// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mlx-swift-structured",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "MLXStructured", targets: ["MLXStructured"])],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.31.5"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "3.31.4"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.1.6"),
        .package(url: "https://github.com/petrukha-ivan/swift-json-schema", from: "2.0.2"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.1.3"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
    ],
    targets: [
        // C package
        .target(
            name: "CMLXStructured",
            exclude: [
                "xgrammar/web",
                "xgrammar/tests",
                "xgrammar/3rdparty/cpptrace",
                "xgrammar/3rdparty/googletest",
                "xgrammar/3rdparty/dlpack/contrib",
                "xgrammar/3rdparty/picojson",
                "xgrammar/cpp/tvm_ffi",
                "xgrammar/Package.swift",
            ],
            cxxSettings: [
                .headerSearchPath("xgrammar/include"),
                .headerSearchPath("xgrammar/3rdparty/dlpack/include"),
                .headerSearchPath("xgrammar/3rdparty/picojson"),
                .disableWarning("shorten-64-to-32"),
            ]
        ),
        // Main package
        .target(
            name: "MLXStructured",
            dependencies: [
                .target(name: "CMLXStructured"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "Hub", package: "swift-transformers"),
                .product(name: "JSONSchema", package: "swift-json-schema"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),
        // CLI for testing
        .executableTarget(
            name: "MLXStructuredCLI",
            dependencies: [
                .target(name: "MLXStructured"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXVLM", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "Hub", package: "swift-transformers"),
                .product(name: "Tokenizers", package: "swift-transformers"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),
        // Unit tests
        .testTarget(
            name: "MLXStructuredTests",
            dependencies: [
                .target(name: "MLXStructured"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
            ],
        ),
    ],
    cxxLanguageStandard: .gnucxx17
)
