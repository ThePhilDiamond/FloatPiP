// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "WindowRaft",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "WindowRaft", targets: ["WindowRaft"]),
    ],
    targets: [
        // ScreenCaptureKit captures the chosen window; AppKit draws the panel and the menu.
        .executableTarget(name: "WindowRaft", linkerSettings: [.linkedFramework("ScreenCaptureKit")]),
    ]
)
