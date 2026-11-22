// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "FloatPiP",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "FloatPiP", targets: ["FloatPiP"]),
    ],
    targets: [
        // ScreenCaptureKit captures the chosen window; AppKit draws the panel and the menu.
        .executableTarget(name: "FloatPiP", linkerSettings: [.linkedFramework("ScreenCaptureKit")]),
    ]
)
