// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "360AudioExporter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "360AudioExporter", targets: ["360AudioExporter"])
    ],
    targets: [
        .executableTarget(
            name: "360AudioExporter",
            path: "Sources/360AudioExporter"
        ),
        .testTarget(
            name: "360AudioExporterTests",
            dependencies: ["360AudioExporter"],
            path: "Tests/360AudioExporterTests"
        )
    ]
)
