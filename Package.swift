// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MeetingSummarizer",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MeetingCore", targets: ["MeetingCore"]),
        .executable(name: "meeting-summarizer", targets: ["MeetingCLI"]),
        .executable(name: "meeting-review", targets: ["MeetingReview"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", exact: "6.3.2"),
    ],
    targets: [
        .target(name: "MeetingCore"),
        .executableTarget(name: "MeetingCLI", dependencies: ["MeetingCore"]),
        .executableTarget(name: "MeetingReview", dependencies: ["MeetingCore"]),
        .testTarget(name: "MeetingCoreTests", dependencies: [
            "MeetingCore", .product(name: "Testing", package: "swift-testing"),
        ], path: "tests/MeetingCoreTests", linkerSettings: [
            .unsafeFlags(["-L", "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
                          "-Xlinker", "-rpath", "-Xlinker",
                          "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"]),
        ]),
        .testTarget(name: "MeetingIntegrationTests", dependencies: [
            "MeetingCore", .product(name: "Testing", package: "swift-testing"),
        ], path: "tests/MeetingIntegrationTests", linkerSettings: [
            .unsafeFlags(["-L", "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
                          "-Xlinker", "-rpath", "-Xlinker",
                          "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"]),
        ]),
    ]
)
