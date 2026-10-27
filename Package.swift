// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Fluent",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "FluentCore"),
        .executableTarget(name: "Fluent", dependencies: ["FluentCore"]),
        .testTarget(name: "FluentCoreTests", dependencies: ["FluentCore"]),
    ],
    swiftLanguageModes: [.v5]
)
