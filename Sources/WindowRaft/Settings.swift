import AppKit

enum Corner: String, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight

    var title: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
    var isLeft: Bool { self == .topLeft || self == .bottomLeft }
    var isTop: Bool { self == .topLeft || self == .topRight }
}

/// Where the picture sits: snapped to the nearest corner, or wherever it was dropped.
/// The menu's Snap to Corners: on is `corners`, off is `free` (the picture stays where dropped).
enum Placement: String, CaseIterable {
    case corners, free
}

enum Shape: String, CaseIterable {
    case rounded, circle, rect

    var title: String {
        switch self {
        case .rounded: return "Rounded"
        case .circle: return "Circle"
        case .rect: return "Rectangle (Sharp Corners)"
        }
    }
}

/// The options, kept in the app's user defaults so they survive a relaunch.
final class Settings {
    static let sizeChoices = [10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90]
    static let zoomChoices = [100, 125, 150, 200, 300, 400]
    static let zoomRange = 100...400
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var corner: Corner {
        get { Corner(rawValue: defaults.string(forKey: "corner") ?? "") ?? .bottomRight }
        set { defaults.set(newValue.rawValue, forKey: "corner") }
    }

    /// The panel's height as a percent of the screen height, 10 to 90.
    var sizePercent: Int {
        get { min(90, max(10, defaults.object(forKey: "sizePercent") as? Int ?? 30)) }
        set { defaults.set(min(90, max(10, newValue)), forKey: "sizePercent") }
    }

    var placement: Placement {
        get { Placement(rawValue: defaults.string(forKey: "placement") ?? "") ?? .corners }
        set { defaults.set(newValue.rawValue, forKey: "placement") }
    }

    /// With free placement: the picture's center, in screen coordinates, where it was last dropped.
    var freeCenter: NSPoint? {
        get {
            guard let x = defaults.object(forKey: "freeX") as? Double, let y = defaults.object(forKey: "freeY") as? Double else { return nil }
            return NSPoint(x: x, y: y)
        }
        set {
            if let p = newValue { defaults.set(Double(p.x), forKey: "freeX"); defaults.set(Double(p.y), forKey: "freeY") }
            else { defaults.removeObject(forKey: "freeX"); defaults.removeObject(forKey: "freeY") }
        }
    }

    /// How far the picture is zoomed into the window's center, as a percent, 100 (the whole window) to 400.
    var zoomPercent: Int {
        get { Self.clampZoom(defaults.object(forKey: "zoomPercent") as? Int ?? 100) }
        set { defaults.set(Self.clampZoom(newValue), forKey: "zoomPercent") }
    }

    static func clampZoom(_ z: Int) -> Int { min(zoomRange.upperBound, max(zoomRange.lowerBound, z)) }

    /// Whether the picture is left out of screen sharing (true unless turned off in the menu).
    var hideFromSharing: Bool {
        get { defaults.object(forKey: "hideFromSharing") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "hideFromSharing") }
    }

    /// Whether the picture's note about screen sharing appears at all (it can be turned off in the menu).
    var showShareNote: Bool {
        get { defaults.object(forKey: "showShareNote") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showShareNote") }
    }

    var shape: Shape {
        get { Shape(rawValue: defaults.string(forKey: "shape") ?? "") ?? .rounded }
        set { defaults.set(newValue.rawValue, forKey: "shape") }
    }

    /// The display the panel was last dropped on (nil: the main display).
    var screenID: CGDirectDisplayID? {
        get { (defaults.object(forKey: "screenID") as? NSNumber)?.uint32Value }
        set { defaults.set(newValue.map { NSNumber(value: $0) }, forKey: "screenID") }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
