import AppKit

/// The menu-bar item, the panel, and the glue between them and the capture.
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate, CaptureDelegate {
    private let settings = Settings()
    private let capture = Capture()
    private let panel = PiPPanel()
    private var statusItem: NSStatusItem!
    private var aspect: CGFloat = 16.0 / 9.0
    private var lastStop: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // FloatPiP's own mark, drawn by scripts/make-icon.swift as a template so macOS colors it for
        // light and dark menu bars; the system's picture-in-picture symbol if it is missing
        if let mark = Bundle.main.image(forResource: "MenuIcon") {
            mark.isTemplate = true
            mark.accessibilityDescription = "FloatPiP"
            statusItem.button?.image = mark
        } else {
            statusItem.button?.image = NSImage(systemSymbolName: "pip", accessibilityDescription: "FloatPiP")
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        capture.delegate = self
        panel.pipView.onDragEnded = { [weak self] center in self?.dropped(at: center) }
        panel.pipView.menuProvider = { [weak self] in self?.makeMenu() ?? NSMenu() }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.relayout() }
        capture.pick()
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        fill(menu)
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        fill(menu)
        return menu
    }

    private func fill(_ menu: NSMenu) {
        menu.addItem(item(capture.isRunning ? "Pick Another Window…" : "Pick a Window…", #selector(pickWindow)))
        let stop = item("Stop", #selector(stopPiP))
        stop.isEnabled = capture.isRunning
        menu.addItem(stop)
        if !capture.isRunning, let lastStop {
            let note = NSMenuItem(title: lastStop, action: nil, keyEquivalent: "")
            note.isEnabled = false
            menu.addItem(note)
        }
        menu.addItem(.separator())

        let corners = NSMenu()
        for c in Corner.allCases {
            let i = item(c.title, #selector(setCorner(_:)))
            i.representedObject = c.rawValue
            i.state = settings.corner == c ? .on : .off
            corners.addItem(i)
        }
        menu.addItem(submenu("Corner", corners))

        let sizes = NSMenu()
        for p in Settings.sizeChoices {
            let i = item("\(p)%\(p == 30 ? " (default)" : "")", #selector(setSize(_:)))
            i.tag = p
            i.state = settings.sizePercent == p ? .on : .off
            sizes.addItem(i)
        }
        menu.addItem(submenu("Size (Height of Screen)", sizes))

        let shapes = NSMenu()
        for s in Shape.allCases {
            let i = item(s.title, #selector(setShape(_:)))
            i.representedObject = s.rawValue
            i.state = settings.shape == s ? .on : .off
            shapes.addItem(i)
        }
        menu.addItem(submenu("Shape", shapes))

        menu.addItem(.separator())
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let about = NSMenuItem(title: "FloatPiP v\(version)", action: nil, keyEquivalent: "")
        about.isEnabled = false
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit FloatPiP", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: "")
        i.target = self
        return i
    }

    private func submenu(_ title: String, _ menu: NSMenu) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        i.submenu = menu
        return i
    }

    @objc private func pickWindow() { capture.pick() }
    @objc private func stopPiP() { capture.stop() }

    @objc private func setCorner(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let c = Corner(rawValue: raw) else { return }
        settings.corner = c
        relayout(animated: true)
    }

    @objc private func setSize(_ sender: NSMenuItem) {
        settings.sizePercent = sender.tag
        relayout()
    }

    @objc private func setShape(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let s = Shape(rawValue: raw) else { return }
        settings.shape = s
        relayout()
    }

    // MARK: Layout

    private var screen: NSScreen {
        if let id = settings.screenID, let s = NSScreen.screens.first(where: { $0.displayID == id }) { return s }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    @discardableResult
    private func relayout(animated: Bool = false) -> CGSize {
        let screen = self.screen
        let L = Layout.make(screen: screen, aspect: aspect, sizePercent: settings.sizePercent,
                            shape: settings.shape, corner: settings.corner)
        let sameSize = panel.frame.size == L.window.size
        panel.pipView.apply(L, shape: settings.shape, scale: screen.backingScaleFactor)
        panel.setFrame(L.window, display: true, animate: animated && sameSize && panel.isVisible)
        let pixels = L.capturePixels(scale: screen.backingScaleFactor, aspect: aspect, shape: settings.shape)
        capture.setPixelSize(pixels)
        return pixels
    }

    /// After a drag: snap to the nearest corner of the display it was dropped on.
    private func dropped(at center: NSPoint) {
        let target = NSScreen.screens.first { $0.frame.contains(center) } ?? screen
        let area = target.visibleFrame
        let left = center.x < area.midX, top = center.y > area.midY
        settings.corner = top ? (left ? .topLeft : .topRight) : (left ? .bottomLeft : .bottomRight)
        settings.screenID = target.displayID
        relayout(animated: true)
    }

    // MARK: CaptureDelegate

    func captureLayout(forAspect aspect: CGFloat) -> CGSize {
        self.aspect = aspect
        return relayout()
    }

    func captureDidReceive(_ surface: IOSurfaceRef) {
        panel.pipView.show(surface)
        if !panel.isVisible {
            lastStop = nil
            panel.orderFrontRegardless()
        }
    }

    func captureDidEnd(reason: String?) {
        panel.orderOut(nil)
        panel.pipView.clear()
        lastStop = reason
        if let reason { NSLog("FloatPiP: \(reason)") }
    }
}

if CommandLine.arguments.contains("--selftest") {
    exit(Selftest.run())
}

let app = NSApplication.shared
let controller = AppController()
app.delegate = controller
app.setActivationPolicy(.accessory)
app.run()
