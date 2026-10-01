// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MeetingFluidAdapter",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "meeting-fluid-asr", targets: ["MeetingFluidASR"])],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.17.4"),
    ],
    targets: [
        .executableTarget(name: "MeetingFluidASR", dependencies: [
            .product(name: "FluidAudio", package: "FluidAudio"),
        ]),
    ]
)
