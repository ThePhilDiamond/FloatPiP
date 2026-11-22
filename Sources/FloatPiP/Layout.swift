import AppKit

/// Where the panel goes and how it is drawn, all in points. The numbers are
/// the ones Mac.apk's screen camera uses for its floating camera image
/// (runtime/src/screen_camera.mm, BuildLayout), so both look the same.
struct Layout {
    /// The picture's rectangle, in screen coordinates.
    let content: NSRect
    /// The panel window: the picture plus room for its shadows.
    let window: NSRect
    /// Space between the window's edge and the picture.
    let pad: CGFloat
    /// Corner radius of the picture (half the side for a circle).
    let radius: CGFloat

    // The floating effect: a wide, soft shadow that lifts the picture off the
    // screen and a tight one that defines its edge. Sized from the picture.
    var ambientBlur: CGFloat { max(4, content.height * 0.10) }
    var ambientDrop: CGFloat { content.height * 0.04 }
    let ambientOpacity: Float = 0.55
    var contactBlur: CGFloat { max(1.5, content.height * 0.02) }
    var contactDrop: CGFloat { content.height * 0.01 }
    let contactOpacity: Float = 0.35

    /// - Parameters:
    ///   - aspect: the captured window's width over its height.
    static func make(screen: NSScreen, aspect: CGFloat, sizePercent: Int, shape: Shape, corner: Corner) -> Layout {
        make(screenFrame: screen.frame, visibleFrame: screen.visibleFrame, aspect: aspect,
             sizePercent: sizePercent, shape: shape, corner: corner)
    }

    /// - Parameters:
    ///   - visibleFrame: the part of the screen clear of the menu bar and Dock.
    static func make(screenFrame: NSRect, visibleFrame area: NSRect, aspect: CGFloat, sizePercent: Int,
                     shape: Shape, corner: Corner) -> Layout {
        let screenHeight = screenFrame.height
        let margin = (screenHeight * 0.03).rounded()

        // The height is the chosen share of the screen height. Rounded and
        // rectangle show the whole window, so the width follows its aspect
        // ratio; the circle is as wide as it is tall.
        var h = (screenHeight * CGFloat(sizePercent) / 100).rounded()
        var w = shape == .circle ? h : (h * aspect).rounded()
        let maxW = area.width - 2 * margin, maxH = area.height - 2 * margin
        if w > maxW { h = (h * maxW / w).rounded(); w = maxW }
        if h > maxH { w = (w * maxH / h).rounded(); h = maxH }
        if shape == .circle { w = min(w, h); h = w }

        let x = corner.isLeft ? area.minX + margin : area.maxX - margin - w
        let y = corner.isTop ? area.maxY - margin - h : area.minY + margin
        let content = NSRect(x: x, y: y, width: w, height: h)

        let radius: CGFloat = shape == .circle ? h / 2 : shape == .rounded ? (h * 0.12).rounded() : 0
        // Room for the ambient shadow: about three blur radii plus its drop.
        let pad = (3 * max(4, h * 0.10) + h * 0.04).rounded(.up)
        return Layout(content: content, window: content.insetBy(dx: -pad, dy: -pad), pad: pad, radius: radius)
    }

    /// The capture size in pixels: the picture's own pixel size. For a circle
    /// the window is captured whole at a size that covers the circle, and the
    /// circle is cut from its center.
    func capturePixels(scale: CGFloat, aspect: CGFloat, shape: Shape) -> CGSize {
        let w = content.width * scale, h = content.height * scale
        guard shape == .circle else { return CGSize(width: w, height: h) }
        return aspect >= 1 ? CGSize(width: h * aspect, height: h) : CGSize(width: w, height: w / aspect)
    }
}
