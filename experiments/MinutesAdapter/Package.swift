// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MeetingMinutesExperiment",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "meeting-mlx-minutes", targets: ["MeetingMLXMinutes"])],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm.git", exact: "3.31.3"),
        .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.9.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(name: "MeetingMLXMinutes", dependencies: [
            .product(name: "MLXLLM", package: "mlx-swift-lm"),
            .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
            .product(name: "HuggingFace", package: "swift-huggingface"),
            .product(name: "Tokenizers", package: "swift-transformers"),
        ]),
        .testTarget(name: "MeetingMLXMinutesTests", dependencies: ["MeetingMLXMinutes"]),
    ]
)
