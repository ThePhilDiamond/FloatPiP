import AppKit

/// The menu-bar item, the panel, and the glue between them and the capture.
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate, CaptureDelegate {
    private let settings = Settings()
    private let capture = Capture()
    private let panel = PiPPanel()
    private let hint = PickerHint()
    private var statusItem: NSStatusItem!
    private var aspect: CGFloat = 16.0 / 9.0
    private var lastStop: String?
    /// The zoom while pinching, unrounded, so small pinches add up.
    private var pinchZoom: CGFloat?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Window Raft's own mark, drawn by scripts/make-icon.swift as a template so macOS colors it for
        // light and dark menu bars; the system's picture-in-picture symbol if it is missing
        if let mark = Bundle.main.image(forResource: "MenuIcon") {
            mark.isTemplate = true
            mark.accessibilityDescription = "Window Raft"
            statusItem.button?.image = mark
        } else {
            statusItem.button?.image = NSImage(systemSymbolName: "pip", accessibilityDescription: "Window Raft")
        }
        let menu = AppController.newMenu()
        menu.delegate = self
        statusItem.menu = menu

        capture.delegate = self
        capture.onPickerClosed = { [weak self] in self?.hint.hide() }
        panel.pipView.onDragEnded = { [weak self] center in self?.dropped(at: center) }
        panel.pipView.menuProvider = { [weak self] in self?.makeMenu() ?? NSMenu() }
        panel.pipView.onZoomSteps = { [weak self] steps in self?.zoom(by: steps) }
        panel.pipView.onPinch = { [weak self] m in self?.pinch(m) }
        panel.pipView.onPinchBegan = { [weak self] in self?.pinchZoom = nil }
        applySharing()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.relayout() }
        Updater.shared.schedule()
        // WINDOWRAFT_UPDATE_TEST=1: check now and install if there is an update, reporting each step (docs/UPDATES.md)
        if ProcessInfo.processInfo.environment["WINDOWRAFT_UPDATE_TEST"] != nil {
            Task { @MainActor in
                await Updater.shared.check(quiet: false)
                FileHandle.standardError.write(Data("update test: after check: \(Updater.shared.phase)\n".utf8))
                if case .available = Updater.shared.phase {
                    await Updater.shared.install()
                    FileHandle.standardError.write(Data("update test: after install: \(Updater.shared.phase)\n".utf8))
                }
            }
        }
        // Nothing opens at launch: the picker would cover the menu bar icon, the way to control
        // Window Raft. A window is picked from the menu (Pick a Window…).
    }

    /// Opening Window Raft again while it runs (from Finder, Launchpad, or Spotlight) shows its menu
    /// under the pointer: a way in when macOS hides the menu bar icon, as it does behind the camera
    /// notch when the menu bar is full.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate()
        makeMenu().popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        return false
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        fill(menu)
    }

    private func makeMenu() -> NSMenu {
        let menu = AppController.newMenu()
        fill(menu)
        return menu
    }

    /// The menu bar menu and the picture's right-click menu. Their items are enabled or greyed out
    /// as `fill` sets them: left to macOS, any item whose target answers its action is enabled, so
    /// Stop Floating and Checking for Updates… could be chosen while greyed out.
    static func newMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        return menu
    }

    private func fill(_ menu: NSMenu) {
        if case .available(let v) = Updater.shared.phase {
            menu.addItem(item("Install Window Raft \(v)…", #selector(installUpdate)))
            menu.addItem(item("What's New in \(v)", #selector(openReleasePage)))
            menu.addItem(.separator())
        }
        menu.addItem(item(capture.isRunning ? "Pick Another Window…" : "Pick a Window…", #selector(pickWindow)))
        menu.addItem(AppController.stopItem(floating: capture.isRunning, target: self))
        if !capture.isRunning, let lastStop {
            let note = NSMenuItem(title: lastStop, action: nil, keyEquivalent: "")
            note.isEnabled = false
            menu.addItem(note)
        }
        menu.addItem(.separator())

        let snap = item("Snap to Corners", #selector(toggleSnapToCorners))
        snap.state = settings.placement == .corners ? .on : .off
        menu.addItem(snap)

        let sizes = NSMenu()
        for p in Settings.sizeChoices {
            let i = item("\(p)%\(p == 30 ? " (default)" : "")", #selector(setSize(_:)))
            i.tag = p
            i.state = settings.sizePercent == p ? .on : .off
            sizes.addItem(i)
        }
        menu.addItem(submenu("Size (Height of Screen)", sizes))

        let zooms = NSMenu()
        let zoom = settings.zoomPercent
        for z in Settings.zoomChoices {
            let i = item(z == 100 ? "100% (Whole Window)" : "\(z)%", #selector(setZoom(_:)))
            i.tag = z
            i.state = zoom == z ? .on : .off
            zooms.addItem(i)
        }
        if !Settings.zoomChoices.contains(zoom) {
            // set by scrolling or pinching: shown, ticked, so the menu says where it is
            let i = item("\(zoom)%", #selector(setZoom(_:)))
            i.tag = zoom
            i.state = .on
            zooms.addItem(.separator())
            zooms.addItem(i)
        }
        let zoomTip = NSMenuItem(title: "Scroll or pinch on the picture to zoom", action: nil, keyEquivalent: "")
        zoomTip.isEnabled = false
        zooms.addItem(.separator())
        zooms.addItem(zoomTip)
        menu.addItem(submenu("Zoom (Center of Window)", zooms))

        let shapes = NSMenu()
        for s in Shape.allCases {
            let i = item(s.title, #selector(setShape(_:)))
            i.representedObject = s.rawValue
            i.state = settings.shape == s ? .on : .off
            shapes.addItem(i)
        }
        menu.addItem(submenu("Shape", shapes))

        menu.addItem(.separator())
        let hide = item("Hide from Screen Sharing", #selector(toggleHideFromSharing))
        hide.state = settings.hideFromSharing ? .on : .off
        menu.addItem(hide)
        let note = item("Show Sharing Note on Picture", #selector(toggleShareNote))
        note.state = settings.showShareNote ? .on : .off
        menu.addItem(note)

        menu.addItem(.separator())
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let about = NSMenuItem(title: "Window Raft v\(version)", action: nil, keyEquivalent: "")
        about.isEnabled = false
        menu.addItem(about)
        let checking = Updater.shared.phase == .checking || Updater.shared.phase == .installing
        var checkTitle = checking ? "Checking for Updates…" : "Check for Updates…"
        // an update found but not installed (Later) stays on this item, which opens its offer again
        if case .available(let v) = Updater.shared.phase { checkTitle = "Update Available: Window Raft \(v)…" }
        let check = item(checkTitle, #selector(checkForUpdates))
        check.isEnabled = !checking
        menu.addItem(check)
        let auto = item("Check for Updates Automatically", #selector(toggleAutomaticUpdates))
        auto.state = Updater.shared.automatic ? .on : .off
        menu.addItem(auto)
        menu.addItem(NSMenuItem(title: "Quit Window Raft", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    /// Stop Floating closes the picture; it is greyed out unless a picture is floating.
    static func stopItem(floating: Bool, target: AnyObject?) -> NSMenuItem {
        let i = NSMenuItem(title: "Stop Floating", action: #selector(stopPiP), keyEquivalent: "")
        i.target = target
        i.isEnabled = floating
        return i
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

    @objc private func pickWindow() {
        hint.show()
        capture.pick()
    }
    @objc func stopPiP() { capture.stop() }

    @objc private func toggleHideFromSharing() {
        settings.hideFromSharing.toggle()
        applySharing()
        if panel.isVisible { panel.pipView.flashNote() }
    }

    @objc private func toggleShareNote() {
        settings.showShareNote.toggle()
        applySharing()
        if panel.isVisible { panel.pipView.flashNote() }
    }

    /// The picture is left out of screen sharing unless that is turned off; its note says which,
    /// unless the note is turned off too.
    private func applySharing() {
        panel.sharingType = settings.hideFromSharing ? .none : .readOnly
        panel.pipView.noteEnabled = settings.showShareNote
        panel.pipView.setNote(settings.hideFromSharing
            ? ["Not visible in screen shares (change or hide this in the menu)", "Not visible in screen shares", "Not shared"]
            : ["Visible in screen shares (change or hide this in the menu)", "Visible in screen shares", "Shared"])
    }

    // MARK: Updates

    @objc private func checkForUpdates() {
        if case .available(let v) = Updater.shared.phase { offerUpdate(v); return }
        Task { @MainActor in
            await Updater.shared.check(quiet: false)
            switch Updater.shared.phase {
            case .available(let v): offerUpdate(v)
            case .upToDate: say("Window Raft is up to date", "You have the latest version, \(Updater.currentVersion).")
            case .failed(let why): say("Couldn't check for updates", why)
            default: break
            }
            Updater.shared.acknowledge()
        }
    }

    @objc private func toggleAutomaticUpdates() {
        Updater.shared.automatic.toggle()
    }

    @objc private func installUpdate() {
        Task { @MainActor in
            await Updater.shared.install()
            // reached only if it didn't install (on success Window Raft reopens as the new version)
            if case .failed(let why) = Updater.shared.phase {
                say("The update wasn't installed", why)
                Updater.shared.acknowledge()
            }
        }
    }

    @objc private func openReleasePage() {
        if let page = Updater.shared.releasePage { NSWorkspace.shared.open(page) }
    }

    private func offerUpdate(_ version: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "Window Raft \(version) is available"
        alert.informativeText = "You have \(Updater.currentVersion). Installing replaces this copy (the old one goes to the Trash) and reopens Window Raft; a floating picture stops until you pick the window again."
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Later")
        // What's new is shown here, not in a button: an alert's buttons all close it, which lost the offer
        alert.accessoryView = whatsNewView(version)
        if alert.runModal() == .alertFirstButtonReturn { installUpdate() }
    }

    /// The release's notes, scrolling if long, and a link to its page on GitHub, which opens in the
    /// browser and leaves the offer open.
    private func whatsNewView(_ version: String) -> NSView {
        let small = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let text = NSMutableAttributedString()
        let bullet = NSMutableParagraphStyle()
        bullet.headIndent = 12
        bullet.paragraphSpacing = 3
        bullet.tabStops = [NSTextTab(textAlignment: .left, location: 12)]
        bullet.defaultTabInterval = 12
        let heading = NSMutableParagraphStyle()
        heading.paragraphSpacingBefore = 6
        heading.paragraphSpacing = 2
        let sections = Updater.shared.releaseNotes.map(Updater.whatsNew) ?? []
        // label colors follow light and dark mode (without one, text is drawn black)
        let ink = NSColor.labelColor
        text.append(NSAttributedString(string: "What's new in \(version)\n", attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize), .foregroundColor: ink]))
        for section in sections {
            text.append(NSAttributedString(string: section.heading + "\n", attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize), .foregroundColor: ink, .paragraphStyle: heading]))
            for item in section.items {
                text.append(NSAttributedString(string: "•\t" + item + "\n", attributes: [.font: small, .foregroundColor: ink, .paragraphStyle: bullet]))
            }
        }
        if sections.isEmpty {
            text.append(NSAttributedString(string: "The release's notes couldn't be read here.\n", attributes: [.font: small, .foregroundColor: ink]))
        }
        if let page = Updater.shared.releasePage {
            let linkStyle = NSMutableParagraphStyle()
            linkStyle.paragraphSpacingBefore = 6
            text.append(NSAttributedString(string: "Release page on GitHub", attributes: [.font: small, .link: page, .paragraphStyle: linkStyle]))
        }
        let width: CGFloat = 340
        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: width, height: 10))
        view.isEditable = false
        view.isSelectable = true            // links need it
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textStorage?.setAttributedString(text)
        view.layoutManager?.ensureLayout(for: view.textContainer!)
        let used = view.layoutManager?.usedRect(for: view.textContainer!).height ?? 100
        let height = min(ceil(used) + 2, 220)
        view.frame.size.height = max(ceil(used) + 2, height)
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        scroll.hasVerticalScroller = used + 2 > 220
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.documentView = view
        return scroll
    }

    private func say(_ title: String, _ text: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.runModal()
    }

    /// Snap to Corners on: the picture settles into the nearest corner; off: it stays where dropped.
    @objc private func toggleSnapToCorners() {
        let p: Placement = settings.placement == .corners ? .free : .corners
        // keep the picture where it is when freeing it; snap it to the nearest corner when anchoring it
        let center = pictureCenter
        settings.placement = p
        if p == .free {
            settings.freeCenter = center
            relayout()
        } else {
            dropped(at: center)
        }
    }

    @objc private func setZoom(_ sender: NSMenuItem) {
        settings.zoomPercent = sender.tag
        relayout()
    }

    /// Scrolling: 10% a step.
    private func zoom(by steps: Int) {
        let z = settings.zoomPercent
        let next = Settings.clampZoom((z / 10 + steps) * 10)   // onto whole tens, then step
        guard next != z else { return }
        settings.zoomPercent = next
        relayout()
    }

    /// Pinching: in proportion, 1% at a time.
    private func pinch(_ magnification: CGFloat) {
        let current = pinchZoom ?? CGFloat(settings.zoomPercent)
        let next = min(CGFloat(Settings.zoomRange.upperBound), max(CGFloat(Settings.zoomRange.lowerBound), current * (1 + magnification)))
        pinchZoom = next
        let rounded = Int(next.rounded())
        guard rounded != settings.zoomPercent else { return }
        settings.zoomPercent = rounded
        relayout()
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

    /// The picture's center on screen now, or where it would go.
    private var pictureCenter: NSPoint {
        if panel.isVisible { return NSPoint(x: panel.frame.midX, y: panel.frame.midY) }   // the window centers the picture
        let L = currentLayout(on: screen)
        return NSPoint(x: L.content.midX, y: L.content.midY)
    }

    private func currentLayout(on screen: NSScreen) -> Layout {
        Layout.make(screen: screen, aspect: aspect, sizePercent: settings.sizePercent, shape: settings.shape,
                    corner: settings.corner, freeCenter: settings.placement == .free ? settings.freeCenter : nil)
    }

    @discardableResult
    private func relayout(animated: Bool = false) -> CGSize {
        let screen = self.screen
        let L = currentLayout(on: screen)
        let sameSize = panel.frame.size == L.window.size
        let zoom = CGFloat(settings.zoomPercent) / 100
        panel.pipView.apply(L, shape: settings.shape, scale: screen.backingScaleFactor)
        panel.pipView.setZoom(zoom)
        panel.setFrame(L.window, display: true, animate: animated && sameSize && panel.isVisible)
        let pixels = L.capturePixels(scale: screen.backingScaleFactor, aspect: aspect, shape: settings.shape, zoom: zoom)
        capture.setPixelSize(pixels)
        return pixels
    }

    /// After a drag: snapped to the nearest corner of the display it was dropped on, or,
    /// with free placement, left there (kept wholly on screen).
    private func dropped(at center: NSPoint) {
        pinchZoom = nil
        let target = NSScreen.screens.first { $0.frame.contains(center) } ?? screen
        settings.screenID = target.displayID
        if settings.placement == .free {
            settings.freeCenter = center
            relayout()
            return
        }
        let area = target.visibleFrame
        let left = center.x < area.midX, top = center.y > area.midY
        settings.corner = top ? (left ? .topLeft : .topRight) : (left ? .bottomLeft : .bottomRight)
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
            panel.pipView.flashNote()
        }
    }

    func captureDidEnd(reason: String?) {
        panel.orderOut(nil)
        panel.pipView.clear()
        lastStop = reason
        if let reason { NSLog("Window Raft: \(reason)") }
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
