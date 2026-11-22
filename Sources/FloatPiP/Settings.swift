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
