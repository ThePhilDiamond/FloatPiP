import AppKit

/// A one-line hint at the top of the screen while macOS's window picker is open. The picker's
/// button says "Share Window" and macOS offers no way to change it, so the hint says what the
/// click does here: it floats the window, and shares nothing.
final class PickerHint {
    private var panel: NSPanel?
    private var timeout: Timer?

    static let text = "Click the window to float, then Share Window. Nothing is shared."

    func show() {
        hide()
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)
        let label = NSTextField(labelWithString: Self.text)
        label.font = font
        label.textColor = .white
        label.sizeToFit()
        let padX: CGFloat = 16, padY: CGFloat = 9
        let size = NSSize(width: (label.frame.width + padX * 2).rounded(.up), height: (label.frame.height + padY * 2).rounded(.up))
        let area = screen.visibleFrame
        let frame = NSRect(x: (area.midX - size.width / 2).rounded(), y: area.maxY - 14 - size.height, width: size.width, height: size.height)

        let p = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.level = .popUpMenu                       // above ordinary windows while the picker is up
        p.ignoresMouseEvents = true                // never in the way of the picker
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.sharingType = .none                      // like the picture, not in screen captures
        p.isReleasedWhenClosed = false

        let back = NSView(frame: NSRect(origin: .zero, size: size))
        back.wantsLayer = true
        back.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.78).cgColor
        back.layer?.cornerRadius = size.height / 2
        back.layer?.borderColor = NSColor.white.withAlphaComponent(0.25).cgColor
        back.layer?.borderWidth = 1
        label.frame.origin = NSPoint(x: padX, y: padY)
        back.addSubview(label)
        p.contentView = back
        p.orderFrontRegardless()
        panel = p
        // gone after two minutes even if the picker never reports back
        timeout = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in self?.hide() }
    }

    func hide() {
        timeout?.invalidate()
        timeout = nil
        panel?.orderOut(nil)
        panel = nil
    }
}
