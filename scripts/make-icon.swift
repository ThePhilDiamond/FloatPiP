// Draws FloatPiP's logo options as PNGs, and the app icon set.
// Usage: swift scripts/make-icon.swift <output folder> [sheet [name,name,...]|app|menu [name [max width in points]]]
// The chosen icon is "outerboth" (round 15); every option drawn on the way is kept, so any can be redrawn.
//   sheet: every option (or those named) side by side, large and at 32 pixels (sheet.png)
//   app:   the chosen logo (logo.png) and AppIcon.iconset, for iconutil
//   menu:  the menu bar icon (MenuIcon.png and MenuIcon@2x.png), from the chosen drawing or the one named
import AppKit

let args = CommandLine.arguments
let out = URL(fileURLWithPath: args.count > 1 ? args[1] : "build/icon")
let which = args.count > 2 ? args[2] : "sheet"
let chosen = "outerboth"
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}
let white = NSColor.white

/// The macOS icon grid: a rounded square inset from the canvas, filled with water.
func drawTile(_ s: CGFloat) {
    let t = NSRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8)
    let back = NSBezierPath(roundedRect: t, xRadius: s * 0.18, yRadius: s * 0.18)
    NSGradient(colors: [color(0x37B6E9), color(0x1769D1)])!.draw(in: back, angle: -90)
}

/// Rings on the water around a floating object at (cx, cy): drawn whole, so the
/// object drawn after them hides their far side, as with something afloat.
func drawRipples(_ s: CGFloat, cx: CGFloat, cy: CGFloat, widths: [CGFloat], alphas: [CGFloat]) {
    for (i, w) in widths.enumerated() {
        let h = w * 0.2
        let e = NSBezierPath(ovalIn: NSRect(x: cx - w / 2 * s, y: cy - h / 2 * s, width: w * s, height: h * s))
        e.lineWidth = s * 0.016
        white.withAlphaComponent(alphas[i]).setStroke()
        e.stroke()
    }
}

/// The floating effect FloatPiP's panel uses: an ambient and a contact shadow.
func withFloat(_ s: CGFloat, height h: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let ambient = NSShadow()
    ambient.shadowColor = color(0x06264F, 0.45)
    ambient.shadowBlurRadius = max(2, h * 0.10 * 2)
    ambient.shadowOffset = NSSize(width: 0, height: -h * 0.04)
    ambient.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    let contact = NSShadow()
    contact.shadowColor = color(0x06264F, 0.30)
    contact.shadowBlurRadius = max(1, h * 0.02 * 2)
    contact.shadowOffset = NSSize(width: 0, height: -h * 0.01)
    contact.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

/// Option "ripples": a small picture window afloat, rings spreading from it.
func drawRipplesLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.37
    drawRipples(s, cx: s * 0.5, cy: cy, widths: [0.50, 0.64], alphas: [0.75, 0.4])
    let w = s * 0.40, h = s * 0.27
    let r = NSRect(x: s * 0.5 - w / 2, y: cy - h * 0.12, width: w, height: h)
    let p = NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16)
    withFloat(s, height: h) { white.setFill(); p.fill() }
}

/// Option "tube": the picture window's frame is the inner tube, afloat.
func drawTubeLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.37
    drawRipples(s, cx: s * 0.5, cy: cy, widths: [0.54, 0.68], alphas: [0.75, 0.4])
    let w = s * 0.44, h = s * 0.29, t = s * 0.075
    let r = NSRect(x: s * 0.5 - w / 2, y: cy - h * 0.12, width: w, height: h)
    let ring = NSBezierPath(roundedRect: r, xRadius: h * 0.30, yRadius: h * 0.30)
    ring.append(NSBezierPath(roundedRect: r.insetBy(dx: t, dy: t), xRadius: h * 0.30 - t * 0.6, yRadius: h * 0.30 - t * 0.6).reversed)
    withFloat(s, height: h) { white.setFill(); ring.fill() }
}

/// Option "corner": a screen, with a small picture floating in its corner.
func drawCornerLogo(_ s: CGFloat) {
    drawTile(s)
    let screen = NSRect(x: s * 0.2, y: s * 0.27, width: s * 0.6, height: s * 0.44)
    let frame = NSBezierPath(roundedRect: screen, xRadius: s * 0.035, yRadius: s * 0.035)
    frame.lineWidth = s * 0.02
    white.withAlphaComponent(0.6).setStroke()
    frame.stroke()
    let w = s * 0.27, h = s * 0.175
    let r = NSRect(x: screen.maxX - s * 0.045 - w, y: screen.minY + s * 0.045, width: w, height: h)
    let p = NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16)
    withFloat(s, height: h) { white.setFill(); p.fill() }
}

/// Option "lounger": the example's idea, our own drawing: a figure lying back
/// in an inner tube that is a picture window's rounded frame.
func drawLoungerLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.36
    drawRipples(s, cx: s * 0.52, cy: cy, widths: [0.56, 0.70], alphas: [0.75, 0.4])
    let w = s * 0.40, h = s * 0.15, t = s * 0.055
    let r = NSRect(x: s * 0.52 - w / 2, y: cy - h * 0.2, width: w, height: h)
    let ring = NSBezierPath(roundedRect: r, xRadius: h * 0.5, yRadius: h * 0.5)
    ring.append(NSBezierPath(roundedRect: r.insetBy(dx: t, dy: t * 0.8), xRadius: h * 0.5 - t * 0.8, yRadius: h * 0.5 - t * 0.8).reversed)
    // the figure: head on its shoulders, back leaning on the near rim, legs over the far rim
    let body = NSBezierPath()
    body.lineCapStyle = .round
    body.lineJoinStyle = .round
    body.lineWidth = s * 0.055
    body.move(to: NSPoint(x: s * 0.38, y: s * 0.50))           // shoulders
    body.line(to: NSPoint(x: s * 0.47, y: s * 0.405))          // hips, sitting in the tube
    body.line(to: NSPoint(x: s * 0.62, y: s * 0.47))           // knees, raised over the rim
    body.line(to: NSPoint(x: s * 0.73, y: s * 0.415))          // feet, down toward the water
    let head = NSBezierPath(ovalIn: NSRect(x: s * 0.305, y: s * 0.505, width: s * 0.095, height: s * 0.095))
    withFloat(s, height: h * 2) {
        white.setStroke(); white.setFill()
        body.stroke(); head.fill(); ring.fill()
    }
}

/// Option "afloat": a screen, with a small picture floating on ripples in its corner.
func drawAfloatLogo(_ s: CGFloat) {
    drawTile(s)
    let screen = NSRect(x: s * 0.2, y: s * 0.30, width: s * 0.6, height: s * 0.42)
    let frame = NSBezierPath(roundedRect: screen, xRadius: s * 0.035, yRadius: s * 0.035)
    frame.lineWidth = s * 0.02
    white.withAlphaComponent(0.55).setStroke()
    frame.stroke()
    let w = s * 0.28, h = s * 0.18
    let cx = screen.maxX - s * 0.01 - w / 2, cy = screen.minY + s * 0.005
    drawRipples(s, cx: cx, cy: cy, widths: [0.36, 0.48], alphas: [0.8, 0.45])
    let r = NSRect(x: cx - w / 2, y: cy - h * 0.1, width: w, height: h)
    let p = NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16)
    withFloat(s, height: h) { white.setFill(); p.fill() }
}


// MARK: Round 2 (after Phil's note: broken ripples, a float, less clutter)

let coral = color(0xF2646A)

/// Water rings as in a float's ripples: each ring's near side is a crescent, thickest
/// in front and tapering to nothing at its ends; its far side shows only as two short
/// strokes at the ends, with gaps between, so the rings read as broken.
/// Returns the near-side crescents, to draw after the floating object.
func brokenRipples(_ s: CGFloat, cx: CGFloat, cy: CGFloat, rings: [(w: CGFloat, h: CGFloat, t: CGFloat)]) -> (back: NSBezierPath, front: NSBezierPath) {
    let back = NSBezierPath(), front = NSBezierPath()
    back.lineCapStyle = .round
    for r in rings {
        let a = r.w * s / 2, b = r.h * s / 2, t = r.t * s
        func pt(_ th: CGFloat, _ bb: CGFloat) -> NSPoint { NSPoint(x: cx + a * cos(th), y: cy + bb * sin(th)) }
        // near side: from just past the left end, under, to just before the right end
        let gap: CGFloat = 0.16, steps = 48
        let start = CGFloat.pi + gap, end = 2 * CGFloat.pi - gap
        for i in 0...steps {
            let th = start + (end - start) * CGFloat(i) / CGFloat(steps)
            i == 0 ? front.move(to: pt(th, b)) : front.line(to: pt(th, b))
        }
        for i in stride(from: steps, through: 0, by: -1) {
            let th = start + (end - start) * CGFloat(i) / CGFloat(steps)
            front.line(to: pt(th, b - t))
        }
        front.close()
        // far side: two short tapered-looking strokes, one at each end
        for (from, to) in [(CGFloat.pi - 0.62, CGFloat.pi - 0.2), (0.2, 0.62)] {
            let arc = NSBezierPath()
            for i in 0...16 {
                let th = from + (to - from) * CGFloat(i) / 16
                i == 0 ? arc.move(to: pt(th, b - t * 0.3)) : arc.line(to: pt(th, b - t * 0.3))
            }
            back.append(arc)
        }
        back.lineWidth = t * 0.45
    }
    return (back, front)
}

/// Draws `object` rotated by `degrees` about `center`, cut flat at the waterline `y`.
func afloat(_ s: CGFloat, waterline y: CGFloat, center: NSPoint, degrees: CGFloat, _ object: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(rect: NSRect(x: 0, y: y, width: s, height: s)).addClip()
    let tr = NSAffineTransform()
    tr.translateX(by: center.x, yBy: center.y)
    tr.rotate(byDegrees: degrees)
    tr.translateX(by: -center.x, yBy: -center.y)
    tr.concat()
    object()
    NSGraphicsContext.restoreGraphicsState()
}

let rings2: [(w: CGFloat, h: CGFloat, t: CGFloat)] = [(0.46, 0.11, 0.030), (0.68, 0.17, 0.026)]

/// Option "bobber": a plain picture window bobbing in the water, tilted, cut at the waterline.
func drawBobberLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.40
    let (back, front) = brokenRipples(s, cx: s * 0.5, cy: cy, rings: rings2)
    white.setStroke(); back.stroke()
    let w = s * 0.34, h = s * 0.26
    afloat(s, waterline: cy, center: NSPoint(x: s * 0.5, y: cy + h * 0.3), degrees: -9) {
        let r = NSRect(x: s * 0.5 - w / 2, y: cy - h * 0.2, width: w, height: h)
        white.setFill(); NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16).fill()
    }
    white.setFill(); front.fill()
}

/// Option "pipbuoy": the picture-in-picture mark itself (a frame with a small
/// picture in its corner) bobbing in the water.
func drawPipBuoyLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.38
    let (back, front) = brokenRipples(s, cx: s * 0.5, cy: cy, rings: rings2)
    white.setStroke(); back.stroke()
    let w = s * 0.42, h = s * 0.32, line = s * 0.035
    afloat(s, waterline: cy, center: NSPoint(x: s * 0.5, y: cy + h * 0.3), degrees: -8) {
        let r = NSRect(x: s * 0.5 - w / 2, y: cy - h * 0.12, width: w, height: h)
        let frame = NSBezierPath(roundedRect: r.insetBy(dx: line / 2, dy: line / 2), xRadius: h * 0.14, yRadius: h * 0.14)
        frame.lineWidth = line
        white.setStroke(); frame.stroke()
        let pw = w * 0.42, ph = h * 0.40
        let p = NSRect(x: r.maxX - line - s * 0.02 - pw, y: r.minY + h * 0.12 + line + s * 0.005, width: pw, height: ph)
        white.setFill(); NSBezierPath(roundedRect: p, xRadius: ph * 0.18, yRadius: ph * 0.18).fill()
    }
    white.setFill(); front.fill()
}

/// A life ring in the shape of a picture window: a rounded-square ring, white with coral bands.
func squareRing(_ r: NSRect, thickness t: CGFloat, radius: CGFloat) {
    let ring = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    ring.append(NSBezierPath(roundedRect: r.insetBy(dx: t, dy: t), xRadius: max(0, radius - t * 0.8), yRadius: max(0, radius - t * 0.8)).reversed)
    white.setFill(); ring.fill()
    NSGraphicsContext.saveGraphicsState()
    ring.addClip()
    coral.setFill()
    // bands across the middle of each side
    let band = r.width * 0.16
    NSRect(x: r.midX - band / 2, y: r.minY, width: band, height: r.height).fill()
    NSRect(x: r.minX, y: r.midY - band / 2, width: r.width, height: band).fill()
    NSGraphicsContext.restoreGraphicsState()
}

/// Option "squarering": a life ring shaped like a picture window, afloat.
func drawSquareRingLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.37
    let (back, front) = brokenRipples(s, cx: s * 0.5, cy: cy, rings: [(0.54, 0.12, 0.030), (0.74, 0.18, 0.026)])
    white.setStroke(); back.stroke()
    let side = s * 0.40
    afloat(s, waterline: cy, center: NSPoint(x: s * 0.5, y: cy + side * 0.3), degrees: -7) {
        squareRing(NSRect(x: s * 0.5 - side / 2, y: cy - side * 0.16, width: side, height: side), thickness: side * 0.25, radius: side * 0.28)
    }
    white.setFill(); front.fill()
}

/// Option "lifering": a round life ring afloat, with a small picture in its middle.
func drawLifeRingLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.37
    let (back, front) = brokenRipples(s, cx: s * 0.5, cy: cy, rings: [(0.56, 0.12, 0.030), (0.76, 0.18, 0.026)])
    white.setStroke(); back.stroke()
    let d = s * 0.42, c = NSPoint(x: s * 0.5, y: cy + d * 0.32)
    afloat(s, waterline: cy, center: c, degrees: 0) {
        let outer = NSRect(x: c.x - d / 2, y: c.y - d / 2, width: d, height: d)
        let t = d * 0.24
        let ring = NSBezierPath(ovalIn: outer)
        ring.append(NSBezierPath(ovalIn: outer.insetBy(dx: t, dy: t)).reversed)
        white.setFill(); ring.fill()
        NSGraphicsContext.saveGraphicsState()
        ring.addClip()
        coral.setFill()
        for k in 0..<4 {
            let p = NSBezierPath()
            let a0 = CGFloat(k) * .pi / 2 + .pi / 4 - 0.30, a1 = a0 + 0.60
            p.move(to: c)
            p.line(to: NSPoint(x: c.x + d * cos(a0), y: c.y + d * sin(a0)))
            p.line(to: NSPoint(x: c.x + d * cos(a1), y: c.y + d * sin(a1)))
            p.close(); p.fill()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
    white.setFill(); front.fill()
}

/// Option "minimal": the picture alone, small and high in the tile, with one broken ring under it.
func drawMinimalLogo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.42
    let (back, front) = brokenRipples(s, cx: s * 0.5, cy: cy, rings: [(0.56, 0.13, 0.034)])
    white.setStroke(); back.stroke()
    let w = s * 0.36, h = s * 0.25
    afloat(s, waterline: cy, center: NSPoint(x: s * 0.5, y: cy + h * 0.3), degrees: 0) {
        let r = NSRect(x: s * 0.5 - w / 2, y: cy - h * 0.15, width: w, height: h)
        white.setFill(); NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16).fill()
    }
    white.setFill(); front.fill()
}


// MARK: Round 3 (Phil: "having the window around the floating bobber"; else pipbuoy)

/// A window frame with water inside it, and a small picture bobbing in that water.
/// `corner`: the picture floats in the frame's lower-right corner, as a picture in
/// picture does; otherwise it floats in the middle.
func framedBobber(_ s: CGFloat, corner: Bool) {
    drawTile(s)
    let frameRect = NSRect(x: s * 0.19, y: s * 0.26, width: s * 0.62, height: s * 0.48)
    let line = s * 0.035
    let radius = s * 0.07
    let inner = frameRect.insetBy(dx: line, dy: line)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: inner, xRadius: radius - line, yRadius: radius - line).addClip()
    let w = s * (corner ? 0.22 : 0.26), h = s * (corner ? 0.165 : 0.19)
    let cx = corner ? inner.maxX - s * 0.15 : s * 0.5
    let cy = inner.minY + s * (corner ? 0.10 : 0.11)
    let rings: [(w: CGFloat, h: CGFloat, t: CGFloat)] = corner
        ? [(0.34, 0.08, 0.026), (0.50, 0.12, 0.022)]
        : [(0.38, 0.09, 0.028), (0.56, 0.13, 0.024)]
    let (back, front) = brokenRipples(s, cx: cx, cy: cy, rings: rings)
    white.setStroke(); back.stroke()
    afloat(s, waterline: cy, center: NSPoint(x: cx, y: cy + h * 0.3), degrees: -9) {
        let r = NSRect(x: cx - w / 2, y: cy - h * 0.2, width: w, height: h)
        white.setFill(); NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16).fill()
    }
    white.setFill(); front.fill()
    NSGraphicsContext.restoreGraphicsState()
    let frame = NSBezierPath(roundedRect: frameRect.insetBy(dx: line / 2, dy: line / 2), xRadius: radius - line / 2, yRadius: radius - line / 2)
    frame.lineWidth = line
    white.setStroke(); frame.stroke()
}
func drawFramedBobberLogo(_ s: CGFloat) { framedBobber(s, corner: false) }
func drawFramedCornerLogo(_ s: CGFloat) { framedBobber(s, corner: true) }

/// Option "pipbuoy2": pipbuoy refined: a gentler tilt, so it reads as bobbing
/// rather than sinking, and a bolder corner picture for small sizes.
func drawPipBuoy2Logo(_ s: CGFloat) {
    drawTile(s)
    let cy = s * 0.37
    let (back, front) = brokenRipples(s, cx: s * 0.5, cy: cy, rings: rings2)
    white.setStroke(); back.stroke()
    let w = s * 0.44, h = s * 0.33, line = s * 0.04
    afloat(s, waterline: cy, center: NSPoint(x: s * 0.5, y: cy + h * 0.3), degrees: -5) {
        let r = NSRect(x: s * 0.5 - w / 2, y: cy - h * 0.10, width: w, height: h)
        let frame = NSBezierPath(roundedRect: r.insetBy(dx: line / 2, dy: line / 2), xRadius: h * 0.15, yRadius: h * 0.15)
        frame.lineWidth = line
        white.setStroke(); frame.stroke()
        let pw = w * 0.46, ph = h * 0.44
        let p = NSRect(x: r.maxX - line - s * 0.022 - pw, y: r.minY + h * 0.10 + line + s * 0.01, width: pw, height: ph)
        white.setFill(); NSBezierPath(roundedRect: p, xRadius: ph * 0.18, yRadius: ph * 0.18).fill()
    }
    white.setFill(); front.fill()
}


// MARK: Round 4 (Phil: the window tilted to match the buoy, framing it and floating too)

func rotated(about c: NSPoint, degrees: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let tr = NSAffineTransform()
    tr.translateX(by: c.x, yBy: c.y); tr.rotate(byDegrees: degrees); tr.translateX(by: -c.x, yBy: -c.y)
    tr.concat()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

/// Option "tiltframe": the frame tilted as the bobber is, around it, with the water
/// and the bobber inside it; the frame floats above the tile on its own shadow.
func drawTiltFrameLogo(_ s: CGFloat) {
    drawTile(s)
    let angle: CGFloat = -8
    let frameRect = NSRect(x: s * 0.20, y: s * 0.28, width: s * 0.60, height: s * 0.46)
    let line = s * 0.035, radius = s * 0.07
    let c = NSPoint(x: frameRect.midX, y: frameRect.midY)
    let inner = frameRect.insetBy(dx: line, dy: line)
    let framePath = NSBezierPath(roundedRect: frameRect.insetBy(dx: line / 2, dy: line / 2), xRadius: radius - line / 2, yRadius: radius - line / 2)
    framePath.lineWidth = line
    rotated(about: c, degrees: angle) {
        withFloat(s, height: frameRect.height * 0.5) { white.setStroke(); framePath.stroke() }
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: inner, xRadius: radius - line, yRadius: radius - line).addClip()
        let w = s * 0.25, h = s * 0.185
        let cx = inner.midX, cy = inner.minY + s * 0.11
        let (back, front) = brokenRipples(s, cx: cx, cy: cy, rings: [(0.36, 0.085, 0.028), (0.54, 0.125, 0.024)])
        white.setStroke(); back.stroke()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: NSRect(x: 0, y: cy, width: s, height: s)).addClip()
        let r = NSRect(x: cx - w / 2, y: cy - h * 0.2, width: w, height: h)
        white.setFill(); NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16).fill()
        NSGraphicsContext.restoreGraphicsState()
        white.setFill(); front.fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

/// Options "anchored" and "anchoredcorner": the frame and the small picture tilted
/// together and anchored in the same water: both cut at one waterline, with the
/// broken ripples spreading outside the frame.
func anchored(_ s: CGFloat, corner: Bool) {
    drawTile(s)
    let angle: CGFloat = -6
    let cy = s * 0.35
    let (back, front) = brokenRipples(s, cx: s * 0.5, cy: cy, rings: [(0.62, 0.13, 0.030), (0.80, 0.19, 0.026)])
    white.setStroke(); back.stroke()
    let w = s * 0.50, h = s * 0.40, line = s * 0.04
    let frameRect = NSRect(x: s * 0.5 - w / 2, y: cy - h * 0.10, width: w, height: h)
    let c = NSPoint(x: s * 0.5, y: cy + h * 0.3)
    afloat(s, waterline: cy, center: c, degrees: angle) {
        let frame = NSBezierPath(roundedRect: frameRect.insetBy(dx: line / 2, dy: line / 2), xRadius: h * 0.14, yRadius: h * 0.14)
        frame.lineWidth = line
        white.setStroke(); frame.stroke()
        let pw = w * (corner ? 0.44 : 0.48), ph = h * (corner ? 0.42 : 0.46)
        let px = corner ? frameRect.maxX - line - s * 0.025 - pw : frameRect.midX - pw / 2
        let p = NSRect(x: px, y: frameRect.minY - h * 0.02, width: pw, height: ph)
        white.setFill(); NSBezierPath(roundedRect: p, xRadius: ph * 0.18, yRadius: ph * 0.18).fill()
    }
    white.setFill(); front.fill()
}
func drawAnchoredLogo(_ s: CGFloat) { anchored(s, corner: false) }
func drawAnchoredCornerLogo(_ s: CGFloat) { anchored(s, corner: true) }


// MARK: Round 5 (Phil: "the ripples level, the pip screen at an angle, and the outer
// screen rectangle matching the angle of the pip screen")

/// The frame and the small picture share one tilt; the water and its ripples stay
/// level, inside the frame. `corner`: the picture floats in the frame's lower-right corner.
func levelFramed(_ s: CGFloat, corner: Bool) {
    drawTile(s)
    let angle: CGFloat = -8
    let rad = angle * .pi / 180
    let frameRect = NSRect(x: s * 0.20, y: s * 0.27, width: s * 0.60, height: s * 0.46)
    let c = NSPoint(x: frameRect.midX, y: frameRect.midY)
    let line = s * 0.035, radius = s * 0.07
    let turn = NSAffineTransform()
    turn.translateX(by: c.x, yBy: c.y); turn.rotate(byDegrees: angle); turn.translateX(by: -c.x, yBy: -c.y)

    // where the picture sits, in the frame's own (tilted) coordinates, then on the tile
    let offset = corner ? NSPoint(x: s * 0.125, y: -s * 0.085) : NSPoint(x: 0, y: -s * 0.065)
    let pc = NSPoint(x: c.x + offset.x * cos(rad) - offset.y * sin(rad), y: c.y + offset.x * sin(rad) + offset.y * cos(rad))
    let w = s * (corner ? 0.22 : 0.25), h = s * (corner ? 0.165 : 0.185)
    let waterline = pc.y - h * 0.18

    // inside the frame: level water, and the tilted picture cut at the waterline
    let inner = turn.transform(NSBezierPath(roundedRect: frameRect.insetBy(dx: line, dy: line), xRadius: radius - line, yRadius: radius - line))
    NSGraphicsContext.saveGraphicsState()
    inner.addClip()
    let rings: [(w: CGFloat, h: CGFloat, t: CGFloat)] = corner
        ? [(0.30, 0.07, 0.024), (0.44, 0.10, 0.020)]
        : [(0.36, 0.08, 0.026), (0.50, 0.115, 0.022)]
    let (back, front) = brokenRipples(s, cx: pc.x, cy: waterline, rings: rings)
    white.setStroke(); back.stroke()
    afloat(s, waterline: waterline, center: pc, degrees: angle) {
        let r = NSRect(x: pc.x - w / 2, y: pc.y - h / 2, width: w, height: h)
        white.setFill(); NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16).fill()
    }
    white.setFill(); front.fill()
    NSGraphicsContext.restoreGraphicsState()

    // the frame, at the picture's angle
    let frame = turn.transform(NSBezierPath(roundedRect: frameRect.insetBy(dx: line / 2, dy: line / 2), xRadius: radius - line / 2, yRadius: radius - line / 2))
    frame.lineWidth = line
    white.setStroke(); frame.stroke()
}
func drawLevelFramedLogo(_ s: CGFloat) { levelFramed(s, corner: false) }
func drawLevelCornerLogo(_ s: CGFloat) { levelFramed(s, corner: true) }


// MARK: Round 6 (Phil: levelcorner is closest; explore it further)

struct CornerStyle {
    var angle: CGFloat = -8
    var frame = (w: CGFloat(0.60), h: CGFloat(0.46))
    var line: CGFloat = 0.035
    var pic = (w: CGFloat(0.22), h: CGFloat(0.165))
    var offset = (x: CGFloat(0.125), y: CGFloat(-0.085))   // picture center from frame center, in the frame's tilt
    var submerged: CGFloat = 0.18                           // share of the picture's height under water
    var rings: [(w: CGFloat, h: CGFloat, t: CGFloat)] = [(0.30, 0.07, 0.024), (0.44, 0.10, 0.020)]
    var farSide = true                                      // the short strokes at the rings' far ends
    var spill = false                                       // ripples spread past the frame, which breaks where they cross
    var submerge = false                                    // with spill: the frame goes under the water inside the outer ring
    var glass = false                                       // the screen is tinted glass, and the water a deeper, level band inside it
    var band: CGFloat = 0.30                                // the water band's strength
    var cutFrame = false                                    // with spill: the frame, like the picture, is cut at the waterline
    var rippleShift: CGFloat = 0                            // the rings' center to the right of the picture's
    var breaks: [[(CGFloat, CGFloat)]] = []                 // per ring: angle ranges cut out of its near side
    var clipToTile = false
    var sinkRight = false                                   // with submerge: hide the frame under the water right of the rings' left end
    var curve = (a: CGFloat(0), b: CGFloat(0))              // the picture meets the water along this ellipse's near side (0: a straight line)
    var ringScale: CGFloat = 1                              // all rings scaled alike, keeping their shape
    var knockRing = -1                                      // which ring's ellipse the frame is cut by under the water (-1: the outer)
    var lift: CGFloat = 0                                   // the waterline and its ripples raised by this much
    var halo: CGFloat = 0                                   // with submerge: a gap of water this wide (in frame lines) around the ripples
    var taperBreaks: [[(CGFloat, CGFloat)]] = []            // per ring: gaps in its near side, each piece tapering to a point at a gap
    var knockMargin: CGFloat = 0.6                          // with submerge: how far past the outer ring the frame is hidden, in frame lines
    var haloFollowsBreaks = true                            // the water gap traces the broken pieces (false: the whole ripples, smooth)
    var noFrame = false                                     // leave out the outer window: the small picture and its ripples alone
}

/// The near side of one ring as crescent pieces: the outer edge on the ring's ellipse,
/// the inner edge on the smaller one, exactly as a whole crescent, except that each
/// piece narrows smoothly to a point where it meets a gap.
func taperedCrescents(_ s: CGFloat, cx: CGFloat, cy: CGFloat, ring r: (w: CGFloat, h: CGFloat, t: CGFloat), gaps: [(CGFloat, CGFloat)]) -> NSBezierPath {
    let a = r.w * s / 2, b = r.h * s / 2, t = r.t * s
    let start = CGFloat.pi + 0.16, end = 2 * CGFloat.pi - 0.16
    var bounds: [(CGFloat, CGFloat)] = []
    var from = start
    for g in gaps.sorted(by: { $0.0 < $1.0 }) { bounds.append((from, g.0)); from = g.1 }
    bounds.append((from, end))
    let path = NSBezierPath()
    for (p0, p1) in bounds where p1 > p0 {
        let steps = 40
        var outer: [NSPoint] = [], inner: [NSPoint] = []
        for i in 0...steps {
            let th = p0 + (p1 - p0) * CGFloat(i) / CGFloat(steps)
            // narrow toward a gap over 0.22 radians; the ring's own ends narrow by themselves
            var f: CGFloat = 1
            if p0 != start { let d = min(1, (th - p0) / 0.14); f = min(f, sqrt(d)) }
            if p1 != end { let d = min(1, (p1 - th) / 0.14); f = min(f, sqrt(d)) }
            // both edges close in on the band's middle line, so each end comes to an even point
            let mid = b - t / 2
            outer.append(NSPoint(x: cx + a * cos(th), y: cy + (mid + t / 2 * f) * sin(th)))
            inner.append(NSPoint(x: cx + a * cos(th), y: cy + (mid - t / 2 * f) * sin(th)))
        }
        path.move(to: outer[0])
        for q in outer.dropFirst() { path.line(to: q) }
        for q in inner.reversed() { path.line(to: q) }
        path.close()
    }
    return path
}


func levelCornerStyled(_ s: CGFloat, _ st: CornerStyle) {
    drawTile(s)
    let rad = st.angle * .pi / 180
    let frameRect = NSRect(x: s * (0.5 - st.frame.w / 2), y: s * (0.5 - st.frame.h / 2), width: s * st.frame.w, height: s * st.frame.h)
    let c = NSPoint(x: frameRect.midX, y: frameRect.midY)
    let line = s * st.line, radius = s * 0.07
    let turn = NSAffineTransform()
    turn.translateX(by: c.x, yBy: c.y); turn.rotate(byDegrees: st.angle); turn.translateX(by: -c.x, yBy: -c.y)
    let ox = s * st.offset.x, oy = s * st.offset.y
    let pc = NSPoint(x: c.x + ox * cos(rad) - oy * sin(rad), y: c.y + ox * sin(rad) + oy * cos(rad))
    let w = s * st.pic.w, h = s * st.pic.h
    let waterline = pc.y - h * (0.5 - st.submerged) + s * st.lift
    let rcx = pc.x + s * st.rippleShift
    let rings = st.rings.map { (w: $0.w * st.ringScale, h: $0.h * st.ringScale, t: $0.t * st.ringScale) }
    let (back, frontAll) = brokenRipples(s, cx: rcx, cy: waterline, rings: rings)
    if st.clipToTile {
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: NSRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8), xRadius: s * 0.18, yRadius: s * 0.18).addClip()
    }
    defer { if st.clipToTile { NSGraphicsContext.restoreGraphicsState() } }
    // the near side of the rings, each with its own breaks cut out
    func fillFront() {
        if !st.taperBreaks.isEmpty {
            white.setFill()
            for (i, r) in rings.enumerated() {
                taperedCrescents(s, cx: rcx, cy: waterline, ring: r, gaps: i < st.taperBreaks.count ? st.taperBreaks[i] : []).fill()
            }
            return
        }
        if st.breaks.isEmpty { white.setFill(); frontAll.fill(); return }
        for (i, r) in st.rings.enumerated() {
            let (_, f) = brokenRipples(s, cx: rcx, cy: waterline, rings: [r])
            NSGraphicsContext.saveGraphicsState()
            let keep = NSBezierPath(rect: NSRect(x: 0, y: 0, width: s, height: s))
            keep.windingRule = .evenOdd
            for (a0, a1) in (i < st.breaks.count ? st.breaks[i] : []) {
                // an upright cut through the ring, between the two angles' points on it
                let x0 = rcx + s * r.w / 2 * cos(a0), x1 = rcx + s * r.w / 2 * cos(a1)
                let wedge = NSBezierPath(rect: NSRect(x: min(x0, x1), y: 0, width: abs(x1 - x0), height: waterline))
                keep.append(wedge)
            }
            keep.addClip()
            white.setFill(); f.fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    let back2 = st.farSide ? back : NSBezierPath()
    let inner = turn.transform(NSBezierPath(roundedRect: frameRect.insetBy(dx: line, dy: line), xRadius: radius - line, yRadius: radius - line))
    let frame = st.noFrame ? NSBezierPath() : turn.transform(NSBezierPath(roundedRect: frameRect.insetBy(dx: line / 2, dy: line / 2), xRadius: radius - line / 2, yRadius: radius - line / 2))
    frame.lineWidth = line
    func picture() {
        if st.curve.a == 0 {
            afloat(s, waterline: waterline, center: pc, degrees: st.angle) {
                let r = NSRect(x: pc.x - w / 2, y: pc.y - h / 2, width: w, height: h)
                white.setFill(); NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16).fill()
            }
            return
        }
        // the water meets the picture along the near side of an ellipse, as the ripples
        // around it are seen: everything above the waterline, and below it down to that arc
        let ea = s * st.curve.a, eb = s * st.curve.b
        let clip = NSBezierPath()
        clip.move(to: NSPoint(x: 0, y: s))
        clip.line(to: NSPoint(x: 0, y: waterline))
        clip.line(to: NSPoint(x: pc.x - ea, y: waterline))
        for k in 0...48 {
            let th = CGFloat.pi + CGFloat.pi * CGFloat(k) / 48
            clip.line(to: NSPoint(x: pc.x + ea * cos(th), y: waterline + eb * sin(th)))
        }
        clip.line(to: NSPoint(x: s, y: waterline))
        clip.line(to: NSPoint(x: s, y: s))
        clip.close()
        NSGraphicsContext.saveGraphicsState()
        clip.addClip()
        let tr = NSAffineTransform()
        tr.translateX(by: pc.x, yBy: pc.y); tr.rotate(byDegrees: st.angle); tr.translateX(by: -pc.x, yBy: -pc.y)
        tr.concat()
        // the picture runs on below the water, so the arc alone shapes its visible bottom
        let r = NSRect(x: pc.x - w / 2, y: pc.y - h / 2 - s * 0.08, width: w, height: h + s * 0.08)
        white.setFill(); NSBezierPath(roundedRect: r, xRadius: h * 0.16, yRadius: h * 0.16).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
    if st.spill && st.cutFrame {
        back2.lineWidth = back.lineWidth
        white.setStroke(); back2.stroke()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: NSRect(x: 0, y: waterline, width: s, height: s)).addClip()
        white.setStroke(); frame.stroke()
        NSGraphicsContext.restoreGraphicsState()
        picture()
        white.setFill(); frontAll.fill()
        return
    }
    if st.spill {
        back2.lineWidth = back.lineWidth
        white.setStroke(); back2.stroke()
        white.setStroke(); frame.stroke()
        picture()
        // a gap of water around each crescent, so the frame breaks where the ripples pass over it;
        // or, submerged, the whole water surface inside the outer ring, so the frame dips under it
        var gap = NSBezierPath(cgPath: frontAll.cgPath.copy(strokingWithWidth: line * 1.3, lineCap: .round, lineJoin: .round, miterLimit: 4))
        if st.submerge, let outer = (st.knockRing >= 0 && st.knockRing < rings.count) ? rings[st.knockRing] : rings.last {
            let a = outer.w * s / 2 + line * st.knockMargin, b = outer.h * s / 2 + line * st.knockMargin
            gap = NSBezierPath(ovalIn: NSRect(x: rcx - a, y: waterline - b, width: 2 * a, height: 2 * b))
            if st.sinkRight { gap = NSBezierPath(rect: NSRect(x: rcx - a, y: 0, width: s, height: waterline + b)) }
            let below = NSBezierPath(rect: NSRect(x: 0, y: 0, width: s, height: waterline))
            NSGraphicsContext.saveGraphicsState(); below.addClip()
        }
        NSGraphicsContext.saveGraphicsState()
        gap.addClip()
        let t = NSRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8)
        NSGradient(colors: [color(0x37B6E9), color(0x1769D1)])!.draw(in: t, angle: -90)
        NSGraphicsContext.restoreGraphicsState()
        if st.submerge { NSGraphicsContext.restoreGraphicsState() }
        if st.halo > 0 {
            // a thin gap of water around the near ripples, so where one meets the frame they stay apart
            var pieces = frontAll
            if !st.taperBreaks.isEmpty && st.haloFollowsBreaks {
                pieces = NSBezierPath()
                for (i, r) in rings.enumerated() { pieces.append(taperedCrescents(s, cx: rcx, cy: waterline, ring: r, gaps: i < st.taperBreaks.count ? st.taperBreaks[i] : [])) }
            }
            let ring = NSBezierPath(cgPath: pieces.cgPath.copy(strokingWithWidth: line * st.halo, lineCap: .round, lineJoin: .round, miterLimit: 4))
            NSGraphicsContext.saveGraphicsState()
            ring.addClip()
            NSGradient(colors: [color(0x37B6E9), color(0x1769D1)])!.draw(in: NSRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8), angle: -90)
            NSGraphicsContext.restoreGraphicsState()
        }
        fillFront()
        return
    }
    NSGraphicsContext.saveGraphicsState()
    inner.addClip()
    if st.glass {
        white.withAlphaComponent(0.14).setFill(); inner.fill()
        color(0x0A3F8F, st.band).setFill()
        NSRect(x: 0, y: 0, width: s, height: waterline).fill()
    }
    back2.lineWidth = back.lineWidth
    white.setStroke(); back2.stroke()
    picture()
    white.setFill(); frontAll.fill()
    NSGraphicsContext.restoreGraphicsState()
    white.setStroke(); frame.stroke()
}

var roomy = CornerStyle()
roomy.angle = -7; roomy.frame = (0.66, 0.50); roomy.pic = (0.21, 0.155); roomy.offset = (0.15, -0.085)
roomy.submerged = 0.12; roomy.rings = [(0.25, 0.055, 0.022), (0.36, 0.08, 0.018)]
var oneRing = roomy
oneRing.rings = [(0.30, 0.07, 0.026)]; oneRing.farSide = false
var spill = CornerStyle()
spill.angle = -7; spill.frame = (0.60, 0.46); spill.pic = (0.22, 0.165); spill.offset = (0.13, -0.09)
spill.submerged = 0.14; spill.rings = [(0.34, 0.075, 0.026), (0.50, 0.11, 0.022)]; spill.spill = true
var spillBig = spill
spillBig.angle = -6; spillBig.frame = (0.56, 0.43); spillBig.pic = (0.26, 0.19); spillBig.offset = (0.12, -0.075)
spillBig.rings = [(0.38, 0.08, 0.028), (0.56, 0.12, 0.024)]

var tall = CornerStyle()
tall.angle = -7; tall.frame = (0.58, 0.50); tall.pic = (0.22, 0.165); tall.offset = (0.12, -0.05)
tall.submerged = 0.15; tall.rings = [(0.26, 0.06, 0.022), (0.38, 0.085, 0.018)]
var tallGentle = tall
tallGentle.angle = -5; tallGentle.pic = (0.24, 0.175); tallGentle.offset = (0.115, -0.045)
var dip = CornerStyle()
dip.angle = -6; dip.frame = (0.56, 0.43); dip.pic = (0.25, 0.185); dip.offset = (0.12, -0.08)
dip.submerged = 0.14; dip.rings = [(0.36, 0.08, 0.028), (0.54, 0.12, 0.024)]; dip.spill = true; dip.submerge = true
var dipCorner = dip
dipCorner.offset = (0.15, -0.10); dipCorner.pic = (0.23, 0.17); dipCorner.rings = [(0.32, 0.07, 0.026), (0.48, 0.105, 0.022)]

var glass = CornerStyle()
glass.angle = -5; glass.frame = (0.64, 0.50); glass.pic = (0.23, 0.17); glass.offset = (0.14, -0.06)
glass.submerged = 0.16; glass.rings = [(0.28, 0.06, 0.022), (0.42, 0.09, 0.018)]; glass.glass = true
var glassBig = glass
glassBig.angle = -4; glassBig.frame = (0.70, 0.54); glassBig.pic = (0.25, 0.185); glassBig.offset = (0.16, -0.06)
glassBig.rings = [(0.30, 0.065, 0.024), (0.46, 0.10, 0.020)]
var glassTilt = glass
glassTilt.angle = -11; glassTilt.frame = (0.58, 0.46); glassTilt.offset = (0.12, -0.05)
var glassMid = glass
glassMid.angle = -7; glassMid.frame = (0.66, 0.52); glassMid.pic = (0.24, 0.18); glassMid.offset = (0.15, -0.06)
glassMid.rings = [(0.30, 0.065, 0.024), (0.44, 0.095, 0.020)]; glassMid.band = 0.38
var spillClear = spillBig
spillClear.pic = (0.24, 0.18); spillClear.offset = (0.06, -0.075)
var dipClear = dip
dipClear.pic = (0.24, 0.18); dipClear.offset = (0.06, -0.08)
var dipClearWide = dip
dipClearWide.frame = (0.62, 0.47); dipClearWide.pic = (0.24, 0.18); dipClearWide.offset = (0.08, -0.095)
dipClearWide.rings = [(0.36, 0.08, 0.028), (0.56, 0.12, 0.024)]
var dipCentered = dipClearWide
dipCentered.offset = (0, -0.095)
// Round 8 (Phil: a smaller gap between the picture and the frame's side)
var spillNear = spillClear
spillNear.offset = (0.095, -0.075)
var dipNear = dipClear
dipNear.offset = (0.095, -0.08)
var dipNearWide = dipClearWide
dipNearWide.offset = (0.12, -0.095)
// Round 10: dipnearwide unchanged except Phil's three asks, one step at a time
// step 1: the rings move right (their right ends stay put), so they wrap the frame's
// right side and leave its lower-left corner whole
var step1 = dipNearWide
step1.clipToTile = true; step1.rippleShift = 0.04
step1.rings = [(0.28, 0.08, 0.028), (0.48, 0.12, 0.024)]
var step1b = dipNearWide
step1b.clipToTile = true; step1b.rippleShift = 0.06
step1b.rings = [(0.26, 0.08, 0.028), (0.44, 0.12, 0.024)]
// step 2: and the near side of each ring broken, as in Phil's first example
step1.sinkRight = true
step1b.sinkRight = true
var step2 = step1
step2.breaks = [[(CGFloat.pi * 1.62, CGFloat.pi * 1.68)], [(CGFloat.pi * 1.30, CGFloat.pi * 1.36), (CGFloat.pi * 1.78, CGFloat.pi * 1.83)]]
var step2b = step1
step2b.breaks = [[(CGFloat.pi * 1.40, CGFloat.pi * 1.46), (CGFloat.pi * 1.72, CGFloat.pi * 1.77)], [(CGFloat.pi * 1.25, CGFloat.pi * 1.30), (CGFloat.pi * 1.55, CGFloat.pi * 1.60), (CGFloat.pi * 1.82, CGFloat.pi * 1.86)]]
// Round 11: dipnearwide with only a curved bottom on the picture
var curved = dipNearWide
curved.curve = (0.135, 0.030)
var curvedRing = curved
curvedRing.rings = [(0.36, 0.11, 0.028), (0.56, 0.12, 0.024)]
var curvedGentle = dipNearWide
curvedGentle.curve = (0.135, 0.020)
curvedGentle.rings = [(0.36, 0.10, 0.028), (0.56, 0.12, 0.024)]
var curveThin = dipNearWide
curveThin.curve = (0.135, 0.012)
curveThin.rings = [(0.36, 0.08, 0.018), (0.56, 0.12, 0.024)]
var curveDeep = dipNearWide
curveDeep.curve = (0.135, 0.016)
curveDeep.rings = [(0.36, 0.11, 0.028), (0.56, 0.165, 0.024)]
// Round 12, from curvedeep: the inner ripple within, around, or curve-cut at the window's right side
var within = curveDeep
within.rippleShift = -0.035
var around = curveDeep
around.rippleShift = 0.05; around.ringScale = 0.9; around.clipToTile = true
var withinCorner = curveDeep
withinCorner.ringScale = 0.85; withinCorner.rippleShift = -0.05
var withinCorner2 = curveDeep
withinCorner2.ringScale = 0.80; withinCorner2.rippleShift = -0.035
var withinClear = curveDeep
withinClear.ringScale = 0.75; withinClear.rippleShift = -0.06
var withinClear2 = curveDeep
withinClear2.ringScale = 0.72; withinClear2.rippleShift = -0.075
// Round 13: within, with the picture centered in its ripples
// A: the ripples stay where they are in within; the picture moves left to their center
var withinCentered = curveDeep
withinCentered.offset = (0.0848, -0.0987)
// B: the picture stays; the ripples center on it, scaled so the inner one stays inside the window
var withinScaled = curveDeep
withinScaled.ringScale = 0.84
// C: halfway: the picture moves half as far, the ripples scaled a little
var withinHalf = curveDeep
withinHalf.offset = (0.1024, -0.0978); withinHalf.ringScale = 0.92
// Round 14, from withinscaled. Step 1: the waterline and its ripples raised a little
var lift1 = withinScaled
lift1.lift = 0.012
var lift2 = withinScaled
lift2.lift = 0.022
var lift2h = lift2
lift2h.halo = 1.2
// Step 2: the ripples broken, each piece tapering to a point at its gap
var broken1 = lift2h
broken1.taperBreaks = [[(CGFloat.pi * 1.58, CGFloat.pi * 1.66)], [(CGFloat.pi * 1.30, CGFloat.pi * 1.37), (CGFloat.pi * 1.76, CGFloat.pi * 1.82)]]
var broken2 = lift2h
broken2.taperBreaks = [[(CGFloat.pi * 1.40, CGFloat.pi * 1.46), (CGFloat.pi * 1.70, CGFloat.pi * 1.75)], [(CGFloat.pi * 1.52, CGFloat.pi * 1.60)]]
broken1.knockMargin = 1.6
broken2.knockMargin = 1.6
// only the inner ripple broken; the outer stays whole over the frame's edge
var broken3 = lift2h
broken3.taperBreaks = [[(CGFloat.pi * 1.61, CGFloat.pi * 1.66)], []]; broken3.haloFollowsBreaks = false
var broken4 = lift2h
broken4.taperBreaks = [[(CGFloat.pi * 1.38, CGFloat.pi * 1.43), (CGFloat.pi * 1.70, CGFloat.pi * 1.75)], []]; broken4.haloFollowsBreaks = false
// Step 3: the picture runs deeper, so the water gap around the inner ripple alone shapes its
// bottom: an arc parallel to the ripple, as water wraps an object
var wrap3 = broken3
wrap3.curve = (0.16, 0.06)
var wrap4 = broken4
wrap4.curve = (0.16, 0.06)
// Round 15: a break in the outer ripple too, away from the inner one's
var outerLeft = wrap3
outerLeft.taperBreaks = [[(CGFloat.pi * 1.61, CGFloat.pi * 1.66)], [(CGFloat.pi * 1.37, CGFloat.pi * 1.41)]]
var outerRight = wrap3
outerRight.taperBreaks = [[(CGFloat.pi * 1.61, CGFloat.pi * 1.66)], [(CGFloat.pi * 1.80, CGFloat.pi * 1.84)]]
var outerBoth = wrap3
outerBoth.taperBreaks = [[(CGFloat.pi * 1.61, CGFloat.pi * 1.66)], [(CGFloat.pi * 1.37, CGFloat.pi * 1.41), (CGFloat.pi * 1.82, CGFloat.pi * 1.86)]]
// The menu bar version: the same drawing with bolder lines and wider breaks, so it holds at 18 points
var menuBold = outerBoth
menuBold.line = 0.055
menuBold.rings = [(0.36, 0.11, 0.042), (0.56, 0.165, 0.036)]
menuBold.taperBreaks = [[(CGFloat.pi * 1.60, CGFloat.pi * 1.67)], [(CGFloat.pi * 1.36, CGFloat.pi * 1.42), (CGFloat.pi * 1.81, CGFloat.pi * 1.87)]]
// A dedicated menu bar glyph: the same picture with a heavier frame, two bolder ripples set
// further apart, and wider breaks, so each stroke is at least about 2 pixels at 36 pixels high
var menuGlyph = outerBoth
menuGlyph.line = 0.07
menuGlyph.rings = [(0.40, 0.13, 0.055), (0.66, 0.22, 0.050)]
menuGlyph.halo = 1.0
menuGlyph.taperBreaks = [[(CGFloat.pi * 1.58, CGFloat.pi * 1.68)], [(CGFloat.pi * 1.34, CGFloat.pi * 1.42), (CGFloat.pi * 1.80, CGFloat.pi * 1.88)]]
menuGlyph.offset = (0.085, -0.095); menuGlyph.pic = (0.22, 0.17)
var menuGlyph2 = menuGlyph
menuGlyph2.taperBreaks = [[(CGFloat.pi * 1.58, CGFloat.pi * 1.68)], [(CGFloat.pi * 1.80, CGFloat.pi * 1.88)]]
// In between: the design exactly, with its strokes a third heavier and its breaks a little wider
var menuMid = outerBoth
menuMid.line = 0.047
menuMid.rings = [(0.36, 0.11, 0.037), (0.56, 0.165, 0.032)]
menuMid.taperBreaks = [[(CGFloat.pi * 1.60, CGFloat.pi * 1.67)], [(CGFloat.pi * 1.36, CGFloat.pi * 1.415), (CGFloat.pi * 1.815, CGFloat.pi * 1.87)]]
// The menu bar icon as Phil suggested: the bobber and its ripples from the logo, without the window
var menuBob = outerBoth
menuBob.noFrame = true
var menuBobMid = menuMid
menuBobMid.noFrame = true
var curveCut = curveDeep
curveCut.knockRing = 0
var standCorner = dipClearWide
standCorner.cutFrame = true; standCorner.submerge = false
standCorner.offset = (0.08, -0.10); standCorner.submerged = 0.16
standCorner.rings = [(0.40, 0.085, 0.028), (0.62, 0.13, 0.024)]
var standCentered = standCorner
standCentered.offset = (0, -0.10)
var standLow = standCorner
standLow.frame = (0.62, 0.50); standLow.offset = (0.08, -0.125); standLow.submerged = 0.20
var bigOpen = glassBig
bigOpen.glass = false


// MARK: Round 9, from dipnearwide (Phil: the ripple goes around the right side of the
// outer window, its bottom corner clearly out of the water, and the ripples broken up)

/// One ring of ripples, broken into tapered pieces like rings on real water. `front`
/// pieces are on the near side (below the center line), `back` on the far side. Each
/// piece is a pair of angles in radians, measured as on a clock face's unit circle.
struct BrokenRing {
    var w: CGFloat, h: CGFloat, t: CGFloat
    var front: [(CGFloat, CGFloat)]
    var back: [(CGFloat, CGFloat)]
}

/// A tapered sliver along the ellipse between two angles: thickest in its middle,
/// to nothing at its ends, and thinner toward the ring's sides, as perspective has it.
func ripplePiece(_ s: CGFloat, cx: CGFloat, cy: CGFloat, _ r: BrokenRing, from a0: CGFloat, to a1: CGFloat, scale: CGFloat) -> NSBezierPath {
    // an even band centered on the ring's line, its width measured across the line
    // (along the ellipse's normal), thickest in front, tapering only near its ends
    let a = r.w * s / 2, b = r.h * s / 2, t = r.t * s * scale
    let steps = 48
    var left: [NSPoint] = [], right: [NSPoint] = []
    for i in 0...steps {
        let u = CGFloat(i) / CGFloat(steps)
        let th = a0 + (a1 - a0) * u
        let e = min(u, 1 - u) / 0.2
        let taper = e >= 1 ? 1 : e * e * (3 - 2 * e)
        let depth = 0.45 + 0.55 * abs(sin(th))
        let half = t * taper * depth / 2
        let p = NSPoint(x: cx + a * cos(th), y: cy + b * sin(th))
        var nx = b * cos(th), ny = a * sin(th)
        let len = max(0.0001, (nx * nx + ny * ny).squareRoot())
        nx /= len; ny /= len
        left.append(NSPoint(x: p.x + nx * half, y: p.y + ny * half))
        right.append(NSPoint(x: p.x - nx * half, y: p.y - ny * half))
    }
    let path = NSBezierPath()
    path.move(to: left[0])
    for q in left.dropFirst() { path.line(to: q) }
    for q in right.reversed() { path.line(to: q) }
    path.close()
    return path
}

/// A ripple piece as a round-capped stroke along the ring: thicker in front, thinner
/// toward the ring's sides, as perspective has it.
func rippleArc(_ s: CGFloat, cx: CGFloat, cy: CGFloat, _ r: BrokenRing, from a0: CGFloat, to a1: CGFloat, scale: CGFloat) -> NSBezierPath {
    let a = r.w * s / 2, b = r.h * s / 2
    let path = NSBezierPath()
    for i in 0...40 {
        let th = a0 + (a1 - a0) * CGFloat(i) / 40
        let p = NSPoint(x: cx + a * cos(th), y: cy + b * sin(th))
        i == 0 ? path.move(to: p) : path.line(to: p)
    }
    let mid = (a0 + a1) / 2
    path.lineWidth = r.t * s * scale * (0.5 + 0.5 * abs(sin(mid)))
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    return path
}

struct FinalStyle {
    var strokes = false                                     // ripples as round-capped strokes
    var angle: CGFloat = -10
    var frame = (w: CGFloat(0.62), h: CGFloat(0.47))
    var center = (x: CGFloat(0.47), y: CGFloat(0.53))       // the frame's center on the tile
    var line: CGFloat = 0.04
    var pic = (w: CGFloat(0.24), h: CGFloat(0.18))
    var offset = (x: CGFloat(0.12), y: CGFloat(-0.095))      // picture center from frame center, in the frame's tilt
    var waterline: CGFloat = -0.205                         // from the frame's center, level
    var rippleX: CGFloat = 0.10                              // ripple center from the frame's center, level
    var rings: [BrokenRing] = []
}

func drawFinal(_ s: CGFloat, _ st: FinalStyle) {
    drawTile(s)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: NSRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8), xRadius: s * 0.18, yRadius: s * 0.18).addClip()
    defer { NSGraphicsContext.restoreGraphicsState() }
    let rad = st.angle * .pi / 180
    let c = NSPoint(x: s * st.center.x, y: s * st.center.y)
    let frameRect = NSRect(x: c.x - s * st.frame.w / 2, y: c.y - s * st.frame.h / 2, width: s * st.frame.w, height: s * st.frame.h)
    let line = s * st.line, radius = s * 0.07
    let turn = NSAffineTransform()
    turn.translateX(by: c.x, yBy: c.y); turn.rotate(byDegrees: st.angle); turn.translateX(by: -c.x, yBy: -c.y)
    let ox = s * st.offset.x, oy = s * st.offset.y
    let pc = NSPoint(x: c.x + ox * cos(rad) - oy * sin(rad), y: c.y + ox * sin(rad) + oy * cos(rad))
    let w = s * st.pic.w, h = s * st.pic.h
    let water = c.y + s * st.waterline
    let rx = c.x + s * st.rippleX
    let scale = s < 64 ? 1.35 : 1.0                         // bolder ripples when tiny

    // the far side of the rings, behind everything
    white.setFill()
    for r in st.rings { for (a0, a1) in r.back {
        if st.strokes { white.setStroke(); rippleArc(s, cx: rx, cy: water, r, from: a0, to: a1, scale: scale).stroke() }
        else { ripplePiece(s, cx: rx, cy: water, r, from: a0, to: a1, scale: scale).fill() }
    } }

    // the frame and the picture, tilted together, both cut at the level waterline
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(rect: NSRect(x: 0, y: water, width: s, height: s)).addClip()
    let frame = turn.transform(NSBezierPath(roundedRect: frameRect.insetBy(dx: line / 2, dy: line / 2), xRadius: radius - line / 2, yRadius: radius - line / 2))
    frame.lineWidth = line
    white.setStroke(); frame.stroke()
    let pic = NSRect(x: pc.x - w / 2, y: pc.y - h / 2, width: w, height: h)
    let picPath = NSBezierPath(roundedRect: pic, xRadius: h * 0.16, yRadius: h * 0.16)
    let picTurn = NSAffineTransform()
    picTurn.translateX(by: pc.x, yBy: pc.y); picTurn.rotate(byDegrees: st.angle); picTurn.translateX(by: -pc.x, yBy: -pc.y)
    white.setFill(); picTurn.transform(picPath).fill()
    NSGraphicsContext.restoreGraphicsState()

    // the near side of the rings, in front
    white.setFill()
    for r in st.rings { for (a0, a1) in r.front {
        if st.strokes { white.setStroke(); rippleArc(s, cx: rx, cy: water, r, from: a0, to: a1, scale: scale).stroke() }
        else { ripplePiece(s, cx: rx, cy: water, r, from: a0, to: a1, scale: scale).fill() }
    } }
}

let pi = CGFloat.pi
var final1 = FinalStyle()
final1.rings = [
    BrokenRing(w: 0.36, h: 0.075, t: 0.022, front: [(pi + 0.20, pi + 1.15), (pi + 1.40, 2 * pi - 0.50), (2 * pi - 0.35, 2 * pi - 0.08)],
               back: [(pi - 0.85, pi - 0.25), (0.25, 0.80)]),
    BrokenRing(w: 0.58, h: 0.12, t: 0.018, front: [(pi + 0.12, pi + 0.75), (pi + 1.00, pi + 2.05), (pi + 2.30, 2 * pi - 0.06)],
               back: [(pi - 0.55, pi - 0.12), (0.18, 0.62)]),
]
var final2 = final1
final2.angle = -8; final2.waterline = -0.195; final2.rippleX = 0.12
var final3 = final1
final3.rings = [
    BrokenRing(w: 0.34, h: 0.07, t: 0.022, front: [(pi + 0.25, pi + 1.30), (pi + 1.55, 2 * pi - 0.15)],
               back: [(pi - 0.80, pi - 0.25), (0.25, 0.75)]),
    BrokenRing(w: 0.52, h: 0.11, t: 0.018, front: [(pi + 0.15, pi + 0.90), (pi + 1.20, pi + 1.85), (pi + 2.10, 2 * pi - 0.10)],
               back: [(0.15, 0.55)]),
    BrokenRing(w: 0.68, h: 0.15, t: 0.015, front: [(pi + 0.45, pi + 1.10), (pi + 1.90, 2 * pi - 0.30)], back: []),
]
var final4 = final1
final4.rings = [
    BrokenRing(w: 0.40, h: 0.09, t: 0.034, front: [(pi + 0.18, pi + 1.30), (pi + 1.50, 2 * pi - 0.12)],
               back: [(pi - 0.70, pi - 0.18), (0.18, 0.75)]),
    BrokenRing(w: 0.64, h: 0.145, t: 0.026, front: [(pi + 0.10, pi + 0.85), (pi + 1.10, pi + 2.15), (pi + 2.35, 2 * pi - 0.06)],
               back: [(pi - 0.45, pi - 0.10), (0.12, 0.50)]),
]
var final5 = final4
final5.rippleX = 0.15
var final6 = final5
final6.angle = -12; final6.waterline = -0.215
var final10 = final1
final10.rippleX = 0.12
final10.rings = [
    BrokenRing(w: 0.40, h: 0.075, t: 0.024, front: [(pi + 0.15, pi + 1.90), (pi + 2.12, 2 * pi - 0.10)],
               back: [(pi - 0.70, pi - 0.15), (0.15, 0.75)]),
    BrokenRing(w: 0.58, h: 0.14, t: 0.020, front: [(pi + 0.10, pi + 1.20), (pi + 1.45, 2 * pi - 0.08)],
               back: [(0.10, 0.50)]),
]
var final11 = final10
final11.rings[0].t = 0.030; final11.rings[1].t = 0.024
var final12 = final11
final12.rings[0].front = [(pi + 0.15, pi + 1.05), (pi + 1.25, pi + 2.10), (pi + 2.30, 2 * pi - 0.10)]
final12.rings[1].front = [(pi + 0.10, pi + 0.80), (pi + 1.00, pi + 1.95), (pi + 2.15, 2 * pi - 0.08)]
// round-capped strokes: the front split into a long middle arc and shorter side arcs
var final13 = final1
final13.strokes = true; final13.rippleX = 0.12
final13.rings = [
    BrokenRing(w: 0.40, h: 0.08, t: 0.026, front: [(pi + 0.30, pi + 0.95), (pi + 1.20, 2 * pi - 0.75), (2 * pi - 0.50, 2 * pi - 0.20)],
               back: [(0.30, 0.85)]),
    BrokenRing(w: 0.58, h: 0.15, t: 0.022, front: [(pi + 0.25, pi + 0.95), (pi + 1.25, 2 * pi - 0.65), (2 * pi - 0.40, 2 * pi - 0.15)],
               back: [(0.22, 0.55)]),
]
var final14 = final13
final14.rings[0].t = 0.032; final14.rings[1].t = 0.027
var final15 = final14
final15.rings[0].front = [(pi + 0.30, pi + 1.30), (pi + 1.55, 2 * pi - 0.20)]
final15.rings[1].front = [(pi + 0.25, pi + 1.15), (pi + 1.40, 2 * pi - 0.15)]
var final7 = final1
final7.rippleX = 0.12
final7.rings = [
    BrokenRing(w: 0.40, h: 0.09, t: 0.028, front: [(pi + 0.15, pi + 1.90), (pi + 2.12, 2 * pi - 0.10)],
               back: [(pi - 0.60, pi - 0.15), (0.15, 0.70)]),
    BrokenRing(w: 0.56, h: 0.13, t: 0.022, front: [(pi + 0.10, pi + 1.20), (pi + 1.45, 2 * pi - 0.08)],
               back: [(0.10, 0.45)]),
]
var final8 = final7
final8.rings[0].t = 0.034; final8.rings[1].t = 0.027
var final9 = final8
final9.angle = -12; final9.waterline = -0.215

let options: [(String, (CGFloat) -> Void)] = [
    ("ripples", drawRipplesLogo), ("tube", drawTubeLogo), ("corner", drawCornerLogo), ("afloat", drawAfloatLogo), ("lounger", drawLoungerLogo),
    ("bobber", drawBobberLogo), ("pipbuoy", drawPipBuoyLogo), ("squarering", drawSquareRingLogo),
    ("lifering", drawLifeRingLogo), ("minimal", drawMinimalLogo),
    ("framedbobber", drawFramedBobberLogo), ("framedcorner", drawFramedCornerLogo), ("pipbuoy2", drawPipBuoy2Logo),
    ("tiltframe", drawTiltFrameLogo), ("anchored", drawAnchoredLogo), ("anchoredcorner", drawAnchoredCornerLogo),
    ("levelframed", drawLevelFramedLogo), ("levelcorner", drawLevelCornerLogo),
    ("roomy", { levelCornerStyled($0, roomy) }), ("onering", { levelCornerStyled($0, oneRing) }),
    ("spill", { levelCornerStyled($0, spill) }), ("spillbig", { levelCornerStyled($0, spillBig) }),
    ("tall", { levelCornerStyled($0, tall) }), ("tallgentle", { levelCornerStyled($0, tallGentle) }),
    ("dip", { levelCornerStyled($0, dip) }), ("dipcorner", { levelCornerStyled($0, dipCorner) }),
    ("glass", { levelCornerStyled($0, glass) }), ("glassbig", { levelCornerStyled($0, glassBig) }),
    ("glasstilt", { levelCornerStyled($0, glassTilt) }), ("glassmid", { levelCornerStyled($0, glassMid) }),
    ("spillclear", { levelCornerStyled($0, spillClear) }), ("dipclear", { levelCornerStyled($0, dipClear) }),
    ("dipclearwide", { levelCornerStyled($0, dipClearWide) }), ("dipcentered", { levelCornerStyled($0, dipCentered) }),
    ("stand", { levelCornerStyled($0, standCorner) }), ("standcentered", { levelCornerStyled($0, standCentered) }),
    ("standlow", { levelCornerStyled($0, standLow) }),
    ("spillnear", { levelCornerStyled($0, spillNear) }), ("dipnear", { levelCornerStyled($0, dipNear) }),
    ("dipnearwide", { levelCornerStyled($0, dipNearWide) }),
    ("curved", { levelCornerStyled($0, curved) }), ("curvedring", { levelCornerStyled($0, curvedRing) }),
    ("curvedgentle", { levelCornerStyled($0, curvedGentle) }),
    ("curvethin", { levelCornerStyled($0, curveThin) }), ("curvedeep", { levelCornerStyled($0, curveDeep) }),
    ("within", { levelCornerStyled($0, within) }), ("around", { levelCornerStyled($0, around) }),
    ("curvecut", { levelCornerStyled($0, curveCut) }),
    ("withincentered", { levelCornerStyled($0, withinCentered) }), ("withinscaled", { levelCornerStyled($0, withinScaled) }),
    ("withinhalf", { levelCornerStyled($0, withinHalf) }),
    ("lift1", { levelCornerStyled($0, lift1) }), ("lift2", { levelCornerStyled($0, lift2) }),
    ("lift2h", { levelCornerStyled($0, lift2h) }),
    ("broken1", { levelCornerStyled($0, broken1) }), ("broken2", { levelCornerStyled($0, broken2) }),
    ("broken3", { levelCornerStyled($0, broken3) }), ("broken4", { levelCornerStyled($0, broken4) }),
    ("wrap3", { levelCornerStyled($0, wrap3) }), ("wrap4", { levelCornerStyled($0, wrap4) }),
    ("outerleft", { levelCornerStyled($0, outerLeft) }), ("outerright", { levelCornerStyled($0, outerRight) }),
    ("outerboth", { levelCornerStyled($0, outerBoth) }), ("menubold", { levelCornerStyled($0, menuBold) }),
    ("menumid", { levelCornerStyled($0, menuMid) }),
    ("menubob", { levelCornerStyled($0, menuBob) }), ("menubobmid", { levelCornerStyled($0, menuBobMid) }),
    ("menuglyph", { levelCornerStyled($0, menuGlyph) }), ("menuglyph2", { levelCornerStyled($0, menuGlyph2) }),
    ("withinclear", { levelCornerStyled($0, withinClear) }), ("withinclear2", { levelCornerStyled($0, withinClear2) }),
    ("withincorner", { levelCornerStyled($0, withinCorner) }), ("withincorner2", { levelCornerStyled($0, withinCorner2) }),
    ("step1", { levelCornerStyled($0, step1) }), ("step1b", { levelCornerStyled($0, step1b) }),
    ("step2", { levelCornerStyled($0, step2) }), ("step2b", { levelCornerStyled($0, step2b) }),
    ("final1", { drawFinal($0, final1) }), ("final2", { drawFinal($0, final2) }), ("final3", { drawFinal($0, final3) }),
    ("final4", { drawFinal($0, final4) }), ("final5", { drawFinal($0, final5) }), ("final6", { drawFinal($0, final6) }),
    ("final7", { drawFinal($0, final7) }), ("final8", { drawFinal($0, final8) }), ("final9", { drawFinal($0, final9) }),
    ("final10", { drawFinal($0, final10) }), ("final11", { drawFinal($0, final11) }), ("final12", { drawFinal($0, final12) }),
    ("final13", { drawFinal($0, final13) }), ("final14", { drawFinal($0, final14) }), ("final15", { drawFinal($0, final15) }), ("bigopen", { levelCornerStyled($0, bigOpen) }),
]

func render(_ size: Int, _ draw: (CGFloat) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: size, height: size).fill(using: .copy)
    draw(CGFloat(size))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
}

/// The white marks of a drawing as a template image (black, with the marks' coverage as
/// alpha), cropped to the marks and scaled to `height` pixels.
func menuTemplate(_ draw: (CGFloat) -> Void, height: Int, maxWidth: Int = Int.max) -> NSBitmapImageRep {
    let big = render(1024, draw)
    let w = big.pixelsWide, h = big.pixelsHigh
    var alpha = [UInt8](repeating: 0, count: w * h)
    var minX = w, minY = h, maxX = 0, maxY = 0
    for y in 0..<h { for x in 0..<w {
        let c = big.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
        // the tile's blues have little red; white has all of it
        let a = max(0, min(1, (c.redComponent * 255 - 60) / 195)) * c.alphaComponent
        let v = UInt8(a * 255)
        alpha[y * w + x] = v
        if v > 6 { minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) }
    } }
    let cw = maxX - minX + 1, ch = maxY - minY + 1
    let mask = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: cw, pixelsHigh: ch, bitsPerSample: 8, samplesPerPixel: 4,
                                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    for y in 0..<ch { for x in 0..<cw {
        let a = CGFloat(alpha[(y + minY) * w + (x + minX)]) / 255
        mask.setColor(NSColor(deviceRed: 0, green: 0, blue: 0, alpha: a), atX: x, y: y)
    } }
    // fit the marks within `height` and `maxWidth`, centered in an image `height` tall
    let scale = min(CGFloat(height) / CGFloat(ch), CGFloat(maxWidth) / CGFloat(cw))
    let outW = Int((CGFloat(cw) * scale).rounded()), drawnH = CGFloat(ch) * scale
    let out = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: outW, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: out)!
    ctx.imageInterpolation = .high
    NSGraphicsContext.current = ctx
    NSColor.clear.set(); NSRect(x: 0, y: 0, width: outW, height: height).fill(using: .copy)
    mask.draw(in: NSRect(x: 0, y: (CGFloat(height) - drawnH) / 2, width: CGFloat(outW), height: drawnH), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high.rawValue])
    NSGraphicsContext.restoreGraphicsState()
    return out
}

switch which {
case "menu":
    // menu bar template images: `menu <name>` writes MenuIcon.png (18 px) and MenuIcon@2x.png (36 px),
    // and menu-preview.png showing them at actual size on light and dark menu bars, and enlarged
    let name = args.count > 3 ? args[3] : chosen
    let draw = options.first { $0.0 == name }!.1
    // an optional fourth argument caps the width, in points
    let maxW = args.count > 4 ? Int(args[4])! : 1000
    let one = menuTemplate(draw, height: 18, maxWidth: maxW), two = menuTemplate(draw, height: 36, maxWidth: maxW * 2)
    save(one, "MenuIcon.png"); save(two, "MenuIcon@2x.png")
    let pw = 420, ph = 150
    let prev = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pw, pixelsHigh: ph, bitsPerSample: 8, samplesPerPixel: 4,
                                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: prev)
    NSColor(white: 0.93, alpha: 1).setFill(); NSRect(x: 0, y: ph / 2, width: pw, height: ph / 2).fill()
    NSColor(white: 0.16, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: pw, height: ph / 2).fill()
    func tinted(_ rep: NSBitmapImageRep, _ c: NSColor) -> NSBitmapImageRep {
        let t = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: rep.pixelsWide, pixelsHigh: rep.pixelsHigh, bitsPerSample: 8, samplesPerPixel: 4,
                                 hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        for y in 0..<rep.pixelsHigh { for x in 0..<rep.pixelsWide {
            let rgb = c.usingColorSpace(.deviceRGB)!
            // the bitmap is premultiplied: each color component carries the pixel's coverage
            let a = rgb.alphaComponent * rep.colorAt(x: x, y: y)!.alphaComponent
            t.setColor(NSColor(deviceRed: rgb.redComponent * a, green: rgb.greenComponent * a, blue: rgb.blueComponent * a, alpha: a), atX: x, y: y)
        } }
        return t
    }
    for (row, col) in [(ph / 2, NSColor(white: 0.1, alpha: 0.85)), (0, NSColor(white: 1, alpha: 0.9))] {
        // actual size (the 2x drawn at 1 point per 2 pixels is shown here at 2x, as on a Retina screen)
        tinted(two, col).draw(in: NSRect(x: 20, y: row + 19, width: two.pixelsWide, height: 36))
        tinted(one, col).draw(in: NSRect(x: 90, y: row + 28, width: one.pixelsWide, height: 18))
        tinted(two, col).draw(in: NSRect(x: 150, y: row + 2, width: two.pixelsWide * 2, height: 72))
    }
    NSGraphicsContext.restoreGraphicsState()
    save(prev, "menu-preview.png")
    print("Wrote MenuIcon.png, MenuIcon@2x.png and menu-preview.png for \(name) in \(out.path)")
case "app":
    let draw = options.first { $0.0 == chosen }!.1
    save(render(1024, draw), "logo.png")
    let set = out.appendingPathComponent("AppIcon.iconset")
    try? FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
    for base in [16, 32, 128, 256, 512] {
        try! render(base, draw).representation(using: .png, properties: [:])!.write(to: set.appendingPathComponent("icon_\(base)x\(base).png"))
        try! render(base * 2, draw).representation(using: .png, properties: [:])!.write(to: set.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
    }
    print("Wrote logo.png and AppIcon.iconset in \(out.path)")
default:
    let names = args.count > 3 ? Set(args[3].split(separator: ",").map(String.init)) : nil
    let options = options.filter { names == nil || names!.contains($0.0) }
    // every option at 320 pixels, with the same drawing at 32 pixels under it, on light and dark
    let cell = 320, small = 32, pad = 24
    let width = options.count * (cell + pad) + pad, height = cell + small * 2 + pad * 4
    let sheet = render(max(width, height)) { _ in }
    let canvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
                                  samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                  bytesPerRow: 0, bitsPerPixel: 0)!
    _ = sheet
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)
    NSColor(white: 0.93, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    NSColor(white: 0.12, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: small + pad * 2).fill()
    for (i, (name, draw)) in options.enumerated() {
        let x = pad + i * (cell + pad)
        render(cell, draw).draw(in: NSRect(x: x, y: small * 2 + pad * 3, width: cell, height: cell))
        let tiny = render(small, draw)
        tiny.draw(in: NSRect(x: x + cell / 2 - small - 8, y: small + pad * 2 + 4, width: small, height: small))
        tiny.draw(in: NSRect(x: x + cell / 2 - small - 8, y: pad, width: small, height: small))
        let label = NSAttributedString(string: name, attributes: [.font: NSFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: NSColor.black])
        label.draw(at: NSPoint(x: x + cell / 2 + 4, y: small + pad * 2 + 10))
    }
    NSGraphicsContext.restoreGraphicsState()
    save(canvas, "sheet.png")
    print("Wrote sheet.png in \(out.path)")
}
