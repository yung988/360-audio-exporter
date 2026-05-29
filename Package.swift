// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Orbit360",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Orbit360", targets: ["Orbit360"])
    ],
    targets: [
        .executableTarget(
            name: "Orbit360",
            path: "Sources/360AudioExporter"
        ),
        .testTarget(
            name: "Orbit360Tests",
            dependencies: ["Orbit360"],
            path: "Tests/360AudioExporterTests"
        )
    ]
)
