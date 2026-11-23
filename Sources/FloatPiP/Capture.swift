import AppKit
import ScreenCaptureKit
import CoreMedia

protocol CaptureDelegate: AnyObject {
    /// The captured window's aspect ratio is known or changed: lay the panel
    /// out for it and return the capture size in pixels. Called on main.
    func captureLayout(forAspect aspect: CGFloat) -> CGSize
    /// A new picture. Called on main.
    func captureDidReceive(_ surface: IOSurfaceRef)
    /// Capture ended; `reason` is nil when FloatPiP stopped it. Called on main.
    func captureDidEnd(reason: String?)
}

/// One window, chosen in macOS's own window picker, captured live.
///
/// The system picker (SCContentSharingPicker) is used, not a list of our own:
/// it shows live window previews, it handles single windows directly, and a
/// window chosen in it may be captured without granting FloatPiP the Screen
/// Recording permission, so nothing in System Settings has to change.
final class Capture: NSObject, SCContentSharingPickerObserver, SCStreamDelegate, SCStreamOutput {
    weak var delegate: CaptureDelegate?

    private let picker = SCContentSharingPicker.shared
    private var stream: SCStream?
    private var windowID: CGWindowID?
    private var aspect: CGFloat = 16.0 / 9.0
    private var pixelSize = CGSize(width: 640, height: 360)
    /// The window's size in points and its points-to-pixels scale, to cap the capture size.
    private var windowPoints = CGSize.zero
    private var windowScale: CGFloat = 2
    private let frameQueue = DispatchQueue(label: "FloatPiP.frames", qos: .userInteractive)
    private var watch: Timer?

    var isRunning: Bool { stream != nil }

    override init() {
        super.init()
        var config = SCContentSharingPickerConfiguration()
        config.allowedPickerModes = [.singleWindow]
        config.allowsChangingSelectedContent = true
        if let me = Bundle.main.bundleIdentifier { config.excludedBundleIDs = [me] }
        picker.defaultConfiguration = config
        picker.maximumStreamCount = 1
        picker.add(self)
        picker.isActive = true
    }

    /// Shows the system window picker; a choice starts capture, or switches
    /// the running capture to the new window.
    func pick() {
        NSApp.activate()
        if let stream {
            picker.present(for: stream, using: .window)
        } else {
            picker.present(using: .window)
        }
    }

    func stop() { end(reason: nil) }

    /// Called whenever the panel's size or shape changes.
    func setPixelSize(_ size: CGSize) {
        let capped = cap(size)
        let new = CGSize(width: Self.even(capped.width), height: Self.even(capped.height))
        guard new != pixelSize else { return }
        pixelSize = new
        stream?.updateConfiguration(makeConfiguration()) { error in
            if let error { NSLog("FloatPiP: could not resize the capture: \(error.localizedDescription)") }
        }
    }

    // MARK: Picker

    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {}

    func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        DispatchQueue.main.async { self.use(filter) }
    }

    func contentSharingPickerStartDidFailWithError(_ error: Error) {
        DispatchQueue.main.async { self.end(reason: "The window picker could not start: \(error.localizedDescription)") }
    }

    private func use(_ filter: SCContentFilter) {
        windowID = filter.includedWindows.first?.windowID
        let size = filter.contentRect.size
        if size.width > 0 && size.height > 0 { aspect = size.width / size.height; windowPoints = size }
        if filter.pointPixelScale > 0 { windowScale = CGFloat(filter.pointPixelScale) }
        pixelSize = Self.evenSize(cap(delegate?.captureLayout(forAspect: aspect) ?? pixelSize))

        if let stream {
            stream.updateContentFilter(filter) { error in
                if let error { DispatchQueue.main.async { self.end(reason: "Could not switch windows: \(error.localizedDescription)") } }
            }
            stream.updateConfiguration(makeConfiguration()) { _ in }
            return
        }

        let s = SCStream(filter: filter, configuration: makeConfiguration(), delegate: self)
        do {
            try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: frameQueue)
        } catch {
            end(reason: "Capture could not start: \(error.localizedDescription)")
            return
        }
        stream = s
        s.startCapture { error in
            if let error { DispatchQueue.main.async { self.end(reason: "Capture could not start: \(error.localizedDescription)") } }
        }
        startWatching()
    }

    private func makeConfiguration() -> SCStreamConfiguration {
        let c = SCStreamConfiguration()
        c.width = Int(pixelSize.width)
        c.height = Int(pixelSize.height)
        c.minimumFrameInterval = CMTime(value: 1, timescale: 30)   // at most 30 fps
        c.queueDepth = 5
        c.pixelFormat = kCVPixelFormatType_32BGRA
        c.showsCursor = false
        c.scalesToFit = true
        c.preservesAspectRatio = true
        c.ignoreShadowsSingleWindow = true
        c.capturesAudio = false
        return c
    }

    // MARK: Stream

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid,
              let info = (CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]])?.first,
              let raw = info[.status] as? Int, let status = SCFrameStatus(rawValue: raw)
        else { return }
        switch status {
        case .complete:
            guard let buffer = sampleBuffer.imageBuffer,
                  let surface = CVPixelBufferGetIOSurface(buffer)?.takeUnretainedValue() else { return }
            DispatchQueue.main.async {
                guard self.stream === stream else { return }
                self.delegate?.captureDidReceive(surface)
            }
        case .stopped:
            DispatchQueue.main.async {
                guard self.stream === stream else { return }
                self.end(reason: "The window's capture stopped.")
            }
        default:
            break
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async {
            guard self.stream === stream else { return }
            self.end(reason: "Capture stopped: \(error.localizedDescription)")
        }
    }

    // MARK: Watching the window

    /// Once a second: stop when the window has closed, and follow its shape
    /// when it is resized. The window list gives a window's existence and
    /// bounds without the Screen Recording permission.
    private func startWatching() {
        watch?.invalidate()
        watch = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.checkWindow() }
    }

    private func checkWindow() {
        guard isRunning, let id = windowID else { return }
        let list = CGWindowListCopyWindowInfo([.optionIncludingWindow], id) as? [[String: Any]] ?? []
        guard let entry = list.first(where: { ($0[kCGWindowNumber as String] as? NSNumber)?.uint32Value == id }) else {
            end(reason: "The window closed.")
            return
        }
        guard let dict = entry[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: dict),
              bounds.width > 0, bounds.height > 0 else { return }
        windowPoints = bounds.size
        let a = bounds.width / bounds.height
        if abs(a - aspect) / aspect > 0.01 {
            aspect = a
            if let size = delegate?.captureLayout(forAspect: a) { setPixelSize(size) }
        }
    }

    private func end(reason: String?) {
        watch?.invalidate()
        watch = nil
        windowID = nil
        let old = stream
        stream = nil
        old?.stopCapture { _ in }
        delegate?.captureDidEnd(reason: reason)
    }

    /// No larger than the window's own pixels: capturing more only adds work, not detail.
    private func cap(_ size: CGSize) -> CGSize {
        guard windowPoints.width > 0, windowPoints.height > 0, size.width > 0, size.height > 0 else { return size }
        let limit = min(windowPoints.width * windowScale / size.width, windowPoints.height * windowScale / size.height, 1)
        return CGSize(width: size.width * limit, height: size.height * limit)
    }

    private static func even(_ x: CGFloat) -> CGFloat { max(2, (x / 2).rounded() * 2) }
    private static func evenSize(_ s: CGSize) -> CGSize { CGSize(width: even(s.width), height: even(s.height)) }
}
