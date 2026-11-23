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

    /// Called on release after a drag, with the picture's center in screen coordinates.
    var onDragEnded: ((NSPoint) -> Void)?
    var menuProvider: (() -> NSMenu)?

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

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = menuProvider?() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}
