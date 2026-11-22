// Draws FloatPiP's logo options as PNGs, and the app icon set.
// Usage: swift scripts/make-icon.swift <output folder> [sheet|app]
//   sheet: every option side by side, large and at 32 pixels (sheet.png)
//   app:   the chosen logo (logo.png) and AppIcon.iconset, for iconutil
import AppKit

let args = CommandLine.arguments
let out = URL(fileURLWithPath: args.count > 1 ? args[1] : "build/icon")
let which = args.count > 2 ? args[2] : "sheet"
let chosen = "afloat"
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

let options: [(String, (CGFloat) -> Void)] = [
    ("ripples", drawRipplesLogo), ("tube", drawTubeLogo), ("corner", drawCornerLogo), ("afloat", drawAfloatLogo), ("lounger", drawLoungerLogo),
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
