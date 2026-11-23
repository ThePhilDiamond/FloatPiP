import AppKit
import QuartzCore

/// The floating panel: borderless, always on top, on every Space and over
/// full-screen apps, never takes focus, and left out of screen sharing.
final class PiPPanel: NSPanel {
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false                 // the shadows are drawn by PiPView
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isMovable = false                 // PiPView moves it, so it can snap
        sharingType = .none               // not in screen captures (tested on macOS 26.6.2)
        animationBehavior = .none
        contentView = PiPView()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// macOS keeps a window's top edge below the menu bar. This window's top edge is
    /// transparent room for the shadow, about a third of the picture's height, so that rule
    /// kept the picture itself well below the top of the screen, both when dragged and in
    /// the top corners. FloatPiP places the picture itself, clear of the menu bar
    /// (Layout.make), so the window is left where it is put.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    var pipView: PiPView { contentView as! PiPView }
}

/// Draws the live picture with its shape, two shadows and a hairline, and
/// handles dragging and the right-click menu.
final class PiPView: NSView {
    private let ambient = CALayer()
    private let contact = CALayer()
    private let video = CALayer()
    private let outline = CAShapeLayer()
    /// A small note across the top of the picture saying whether screen shares show it.
    private let note = CALayer()
    private let noteText = CATextLayer()
    /// The note's wordings, longest first; the longest that fits is shown.
    private var noteStrings: [String] = []
    private var noteHideTimer: Timer?
    private var hovering = false
    private var noteScale: CGFloat = 2

    /// Called on release after a drag, with the picture's center in screen coordinates.
    var onDragEnded: ((NSPoint) -> Void)?
    var menuProvider: (() -> NSMenu)?
    /// Scrolling over the picture: whole steps, up to zoom in, down to zoom out.
    var onZoomSteps: ((Int) -> Void)?
    /// Pinching on a trackpad: the change in magnification (0.1 is 10% larger).
    var onPinch: ((CGFloat) -> Void)?
    var onPinchBegan: (() -> Void)?
    private var scrollAccumulated: CGFloat = 0

    private var layout: Layout?
    private var dragStartMouse: NSPoint?
    private var dragStartOrigin = NSPoint.zero
    private var moved = false

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        let root = layer!
        root.backgroundColor = NSColor.clear.cgColor
        for s in [ambient, contact] {
            s.shadowColor = NSColor.black.cgColor
            root.addSublayer(s)
        }
        video.backgroundColor = NSColor.black.cgColor
        video.masksToBounds = true
        video.cornerCurve = .circular
        root.addSublayer(video)
        outline.fillColor = nil
        outline.strokeColor = NSColor.white.withAlphaComponent(0.35).cgColor
        root.addSublayer(outline)
        note.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        note.opacity = 0
        noteText.alignmentMode = .center
        noteText.isWrapped = false
        noteText.truncationMode = .end
        note.addSublayer(noteText)
        video.addSublayer(note)      // inside the picture, so its shape clips it
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func apply(_ L: Layout, shape: Shape, scale: CGFloat) {
        layout = L
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let r = CGRect(x: L.pad, y: L.pad, width: L.content.width, height: L.content.height)
        let local = CGRect(origin: .zero, size: r.size)
        let radius = min(L.radius, r.width / 2, r.height / 2)
        let path = CGPath(roundedRect: local, cornerWidth: radius, cornerHeight: radius, transform: nil)

        let shadows: [(CALayer, CGFloat, CGFloat, Float)] = [
            (ambient, L.ambientBlur, L.ambientDrop, L.ambientOpacity),
            (contact, L.contactBlur, L.contactDrop, L.contactOpacity),
        ]
        for (s, blur, drop, opacity) in shadows {
            s.frame = r
            s.shadowPath = path
            s.shadowRadius = blur
            s.shadowOffset = CGSize(width: 0, height: -drop)   // y points up: a drop is downward
            s.shadowOpacity = opacity
        }

        video.frame = r
        video.cornerRadius = radius
        // Rounded and rectangle: the whole window, fitted (the panel has the
        // window's aspect ratio). Circle: filled, so the circle is cut from
        // the center of the picture. Never stretched.
        video.contentsGravity = shape == .circle ? .resizeAspectFill : .resizeAspect

        let px = 1 / scale                                       // a 1-pixel hairline
        let inner = local.insetBy(dx: px / 2, dy: px / 2)
        let innerRadius = max(0, min(radius - px / 2, inner.width / 2, inner.height / 2))
        outline.frame = r
        outline.lineWidth = px
        outline.path = CGPath(roundedRect: inner, cornerWidth: innerRadius, cornerHeight: innerRadius, transform: nil)

        for l in [layer!, ambient, contact, video, outline] { l.contentsScale = scale }
        noteScale = scale
        layoutNote()
        CATransaction.commit()
        updateTrackingAreas()
    }

    // MARK: The screen-share note

    /// Sets the note's wordings, longest first (the longest that fits is shown); the note
    /// shows on hover, and for a few seconds after `flashNote`.
    func setNote(_ wordings: [String]) {
        noteStrings = wordings
        layoutNote()
    }

    /// Shows the note for four seconds (longer while the pointer is over the picture).
    func flashNote() {
        showNote(true)
        noteHideTimer?.invalidate()
        noteHideTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            guard let self, !self.hovering else { return }
            self.showNote(false)
        }
    }

    private func showNote(_ visible: Bool) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        note.opacity = visible ? 1 : 0
        CATransaction.commit()
    }

    /// A pill near the top of the picture, its text sized to the picture and kept inside
    /// its shape: lower down in a circle, where the circle is wide enough.
    private func layoutNote() {
        guard let L = layout else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let w = L.content.width, h = L.content.height
        let isCircle = abs(w - h) < 1 && L.radius >= h / 2 - 0.5
        func measure(_ str: String, _ s: CGFloat) -> NSAttributedString {
            NSAttributedString(string: str, attributes: [
                .font: NSFont.systemFont(ofSize: s, weight: .semibold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.95)])
        }
        let room = isCircle ? w * 0.72 : w * 0.9
        // readable first: the longest wording that fits at 11 points, then smaller type, down to 9
        var size: CGFloat = 11
        var text = measure(noteStrings.last ?? "", size)
        search: for s in stride(from: CGFloat(11), through: 9, by: -1) {
            for str in noteStrings {
                let t = measure(str, s)
                if t.size().width + s * 1.6 <= room { size = s; text = t; break search }
            }
            size = s; text = measure(noteStrings.last ?? "", s)
        }
        let pillW = min(room, (text.size().width + size * 1.6).rounded(.up))
        let pillH = (size * 1.8).rounded(.up)
        let top = isCircle ? h * 0.16 : max(6, h * 0.05)
        // the video layer's own coordinates: y up from its bottom
        note.frame = CGRect(x: ((w - pillW) / 2).rounded(), y: (h - top - pillH).rounded(), width: pillW, height: pillH)
        note.cornerRadius = pillH / 2
        noteText.string = text
        noteText.frame = CGRect(x: size * 0.8, y: (pillH - text.size().height) / 2 - 0.5, width: pillW - size * 1.6, height: text.size().height + 1)
        note.contentsScale = noteScale
        noteText.contentsScale = noteScale
        CATransaction.commit()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for t in trackingAreas { removeTrackingArea(t) }
        guard let L = layout else { return }
        let r = CGRect(x: L.pad, y: L.pad, width: L.content.width, height: L.content.height)
        addTrackingArea(NSTrackingArea(rect: r, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        hovering = true
        showNote(true)
    }

    override func mouseExited(with event: NSEvent) {
        hovering = false
        if noteHideTimer?.isValid != true { showNote(false) }
    }

    /// Shows the center of the picture, 1/zoom of it each way (1: the whole window).
    func setZoom(_ zoom: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        video.contentsRect = Layout.zoomRect(zoom)
        CATransaction.commit()
    }

    func show(_ surface: IOSurfaceRef) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        video.contents = surface
        CATransaction.commit()
    }

    func clear() {
        video.contents = nil
    }

    // MARK: Mouse

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { rightMouseDown(with: event); return }
        dragStartMouse = NSEvent.mouseLocation
        dragStartOrigin = window?.frame.origin ?? .zero
        moved = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartMouse, let window else { return }
        let now = NSEvent.mouseLocation
        let dx = now.x - start.x, dy = now.y - start.y
        if !moved && hypot(dx, dy) < 3 { return }
        moved = true
        window.setFrameOrigin(NSPoint(x: dragStartOrigin.x + dx, y: dragStartOrigin.y + dy))
    }

    override func mouseUp(with event: NSEvent) {
        defer { dragStartMouse = nil }
        guard moved, let window, let L = layout else { return }
        let center = NSPoint(x: window.frame.minX + L.pad + L.content.width / 2,
                             y: window.frame.minY + L.pad + L.content.height / 2)
        onDragEnded?(center)
    }

    override func scrollWheel(with event: NSEvent) {
        // a mouse wheel moves in lines, one step each; a trackpad in points, one step per 12
        let d = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY / 12 : event.scrollingDeltaY
        scrollAccumulated += d
        var steps = 0
        while scrollAccumulated >= 1 { steps += 1; scrollAccumulated -= 1 }
        while scrollAccumulated <= -1 { steps -= 1; scrollAccumulated += 1 }
        if steps != 0 { onZoomSteps?(steps) }
        if event.phase == .ended || event.momentumPhase == .ended { scrollAccumulated = 0 }
    }

    override func magnify(with event: NSEvent) {
        if event.phase == .began { onPinchBegan?() }
        onPinch?(event.magnification)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = menuProvider?() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}
