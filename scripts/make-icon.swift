// Draws FloatPiP's logo options as PNGs, and the app icon set.
// Usage: swift scripts/make-icon.swift <output folder> [sheet [name,name,...]|app]
//   sheet: every option (or those named) side by side, large and at 32 pixels (sheet.png)
//   app:   the chosen logo (logo.png) and AppIcon.iconset, for iconutil
import AppKit

let args = CommandLine.arguments
let out = URL(fileURLWithPath: args.count > 1 ? args[1] : "build/icon")
let which = args.count > 2 ? args[2] : "sheet"
let chosen = "pipbuoy2"
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

let options: [(String, (CGFloat) -> Void)] = [
    ("ripples", drawRipplesLogo), ("tube", drawTubeLogo), ("corner", drawCornerLogo), ("afloat", drawAfloatLogo), ("lounger", drawLoungerLogo),
    ("bobber", drawBobberLogo), ("pipbuoy", drawPipBuoyLogo), ("squarering", drawSquareRingLogo),
    ("lifering", drawLifeRingLogo), ("minimal", drawMinimalLogo),
    ("framedbobber", drawFramedBobberLogo), ("framedcorner", drawFramedCornerLogo), ("pipbuoy2", drawPipBuoy2Logo),
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

switch which {
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
