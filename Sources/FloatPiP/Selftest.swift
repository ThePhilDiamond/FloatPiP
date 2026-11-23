import AppKit

/// `FloatPiP --selftest`: checks the panel's layout and the remembered
/// options without opening a window or capturing anything, so CI can run it.
/// The expected numbers are the styling rules in README.md ("How it looks").
enum Selftest {
    private static var passed = 0
    private static var failures: [String] = []

    private static func check(_ ok: Bool, _ what: String) {
        if ok { passed += 1 } else { failures.append(what) }
    }

    private static func near(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat = 0.5) -> Bool { abs(a - b) <= tolerance }

    static func run() -> Int32 {
        // A 1470 x 956 point screen (a 13-inch MacBook Air) with a 33-point menu bar and a hidden Dock.
        let screen = NSRect(x: 0, y: 0, width: 1470, height: 956)
        let visible = NSRect(x: 0, y: 0, width: 1470, height: 923)
        func layout(_ aspect: CGFloat = 16.0 / 9.0, _ size: Int = 30, _ shape: Shape = .rounded, _ corner: Corner = .bottomRight) -> Layout {
            Layout.make(screenFrame: screen, visibleFrame: visible, aspect: aspect, sizePercent: size, shape: shape, corner: corner)
        }

        // Defaults: 30% of the screen height, bottom right, 3% margin, 12% radius.
        let d = layout()
        check(d.content.height == 287, "default height is 30% of 956 (287), got \(d.content.height)")
        check(d.content.width == 510, "default width follows 16:9 (510), got \(d.content.width)")
        check(d.content.maxX == 1470 - 29 && d.content.minY == 29, "default sits 29 points (3%) from the bottom-right edges, got \(d.content)")
        check(d.radius == 34, "rounded radius is 12% of the height (34), got \(d.radius)")

        // Corners, measured from the area clear of the menu bar.
        let tl = layout(16.0 / 9.0, 30, .rounded, .topLeft)
        check(tl.content.minX == 29 && tl.content.maxY == 923 - 29, "top left sits 29 points from the left and below the menu bar, got \(tl.content)")
        let tr = layout(16.0 / 9.0, 30, .rounded, .topRight)
        check(tr.content.maxX == 1441 && tr.content.maxY == 894, "top right corner, got \(tr.content)")
        let bl = layout(16.0 / 9.0, 30, .rounded, .bottomLeft)
        check(bl.content.minX == 29 && bl.content.minY == 29, "bottom left corner, got \(bl.content)")

        // Shapes.
        let c = layout(16.0 / 9.0, 30, .circle)
        check(c.content.width == c.content.height, "a circle is as wide as it is tall, got \(c.content.size)")
        check(c.radius == c.content.height / 2, "a circle's radius is half its side, got \(c.radius)")
        check(layout(16.0 / 9.0, 30, .rect).radius == 0, "a rectangle has sharp corners")

        // Never stretched: the panel keeps the window's aspect ratio, even when clamped to the screen.
        for (aspect, size) in [(16.0 / 9.0, 90), (4.0, 50), (0.5, 90), (1.0, 10), (21.0 / 9.0, 70)] as [(CGFloat, Int)] {
            let l = layout(aspect, size)
            check(near(l.content.width / l.content.height, aspect, 0.02), "aspect \(aspect) at \(size)% kept, got \(l.content.width / l.content.height)")
            check(l.content.minX >= 29 && l.content.maxX <= 1441 && l.content.minY >= 29 && l.content.maxY <= 894,
                  "aspect \(aspect) at \(size)% stays inside the margins, got \(l.content)")
        }
        let tall = layout(0.5, 90, .circle)
        check(tall.content.width == tall.content.height && tall.content.height <= 923 - 58, "a 90% circle fits on screen, got \(tall.content)")

        // The floating effect, sized from the panel.
        check(near(d.ambientBlur, 28.7) && near(d.ambientDrop, 11.48) && d.ambientOpacity == 0.55, "ambient shadow: blur 10%, drop 4%, 55%")
        check(near(d.contactBlur, 5.74) && near(d.contactDrop, 2.87) && d.contactOpacity == 0.35, "contact shadow: blur 2%, drop 1%, 35%")
        let small = layout(16.0 / 9.0, 10)
        check(small.ambientBlur >= 4 && small.contactBlur >= 1.5, "small panels keep the minimum blurs (4 and 1.5)")
        check(d.pad >= 3 * d.ambientBlur + d.ambientDrop, "the window leaves room for the whole shadow")
        check(d.window == d.content.insetBy(dx: -d.pad, dy: -d.pad), "the window is the picture plus its shadow room")

        // Capture size: the picture's own pixels; for a circle, the whole window covering it.
        let px = d.capturePixels(scale: 2, aspect: 16.0 / 9.0, shape: .rounded)
        check(px == CGSize(width: 1020, height: 574), "capture at the panel's pixel size, got \(px)")
        let cpx = c.capturePixels(scale: 2, aspect: 16.0 / 9.0, shape: .circle)
        check(cpx.height == c.content.height * 2 && near(cpx.width / cpx.height, 16.0 / 9.0, 0.01), "a circle captures the whole window at the circle's height, got \(cpx)")
        let cpxTall = c.capturePixels(scale: 2, aspect: 0.5, shape: .circle)
        check(cpxTall.width == c.content.width * 2 && cpxTall.height == cpxTall.width * 2, "a tall window's circle captures at the circle's width, got \(cpxTall)")

        // Free placement: the picture goes where it was dropped, kept wholly on screen.
        let free = Layout.make(screenFrame: screen, visibleFrame: visible, aspect: 16.0 / 9.0, sizePercent: 30, shape: .rounded,
                               corner: .bottomRight, freeCenter: NSPoint(x: 600, y: 500))
        check(near(free.content.midX, 600, 1) && near(free.content.midY, 500, 1), "free placement centers the picture where dropped, got \(free.content)")
        let pushed = Layout.make(screenFrame: screen, visibleFrame: visible, aspect: 16.0 / 9.0, sizePercent: 30, shape: .rounded,
                                 corner: .bottomRight, freeCenter: NSPoint(x: 1460, y: 950))
        check(pushed.content.maxX == 1470 && pushed.content.maxY == 923, "a drop past the top-right keeps the picture on screen, below the menu bar, got \(pushed.content)")
        let low = Layout.make(screenFrame: screen, visibleFrame: visible, aspect: 16.0 / 9.0, sizePercent: 30, shape: .rounded,
                              corner: .topLeft, freeCenter: NSPoint(x: -50, y: -50))
        check(low.content.minX == 0 && low.content.minY == 0, "a drop past the bottom-left keeps the picture on screen, got \(low.content)")

        // Zoom: the center 1/zoom of the picture, captured that much larger.
        check(Layout.zoomRect(1) == CGRect(x: 0, y: 0, width: 1, height: 1), "100% shows the whole window")
        check(Layout.zoomRect(2) == CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5), "200% shows the center half each way, got \(Layout.zoomRect(2))")
        check(near(Layout.zoomRect(4).width, 0.25, 0.0001) && near(Layout.zoomRect(4).midX, 0.5, 0.0001), "400% shows the center quarter each way")
        let zpx = d.capturePixels(scale: 2, aspect: 16.0 / 9.0, shape: .rounded, zoom: 2)
        check(zpx == CGSize(width: 2040, height: 1148), "at 200% the window is captured twice as large, got \(zpx)")

        // Remembered options, in a scratch defaults domain.
        let suite = "io.github.thephildiamond.FloatPiP.selftest"
        let scratch = UserDefaults(suiteName: suite)!
        scratch.removePersistentDomain(forName: suite)
        let s = Settings(defaults: scratch)
        check(s.corner == .bottomRight && s.sizePercent == 30 && s.shape == .rounded && s.screenID == nil, "defaults: bottom right, 30%, rounded, main screen")
        s.sizePercent = 5; check(s.sizePercent == 10, "size is at least 10%")
        s.sizePercent = 95; check(s.sizePercent == 90, "size is at most 90%")
        s.corner = .topLeft; s.shape = .circle; s.screenID = 7
        check(s.placement == .corners && s.freeCenter == nil && s.zoomPercent == 100, "defaults: snap to corners, no free position, 100% zoom")
        check(s.hideFromSharing, "by default the picture is hidden from screen sharing")
        check(s.showShareNote, "by default the sharing note shows")
        s.zoomPercent = 50; check(s.zoomPercent == 100, "zoom is at least 100%")
        s.zoomPercent = 900; check(s.zoomPercent == 400, "zoom is at most 400%")
        s.zoomPercent = 170; s.placement = .free; s.freeCenter = NSPoint(x: 321, y: 654)
        let again = Settings(defaults: scratch)
        check(again.corner == .topLeft && again.shape == .circle && again.screenID == 7, "options are remembered")
        check(again.zoomPercent == 170 && again.placement == .free && again.freeCenter == NSPoint(x: 321, y: 654), "zoom and free position are remembered")
        scratch.removePersistentDomain(forName: suite)

        if failures.isEmpty {
            print("FloatPiP selftest: all \(passed) checks passed.")
            return 0
        }
        for f in failures { print("FAILED: \(f)") }
        print("FloatPiP selftest: \(failures.count) of \(passed + failures.count) checks failed.")
        return 1
    }
}
