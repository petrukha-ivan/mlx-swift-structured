// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MLXStructured",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        .library(name: "MLXStructured", targets: ["MLXStructured"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.25.6"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", from: "2.25.7"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.24"),
        .package(url: "https://github.com/kevinhermawan/swift-json-schema", from: "2.0.1"),
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
                "xgrammar/cpp/nanobind",
            ],
            cSettings: [
                .headerSearchPath("xgrammar/include"),
                .headerSearchPath("xgrammar/3rdparty/dlpack/include"),
                .headerSearchPath("xgrammar/3rdparty/picojson"),
            ],
            cxxSettings: [
                .headerSearchPath("xgrammar/include"),
                .headerSearchPath("xgrammar/3rdparty/dlpack/include"),
                .headerSearchPath("xgrammar/3rdparty/picojson"),
            ]
        ),
        // Main package
        .target(
            name: "MLXStructured",
            dependencies: [
                .target(name: "CMLXStructured"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
                .product(name: "JSONSchema", package: "swift-json-schema")
            ]
        ),
        // CLI for testing
        .executableTarget(
            name: "MLXStructuredCLI",
            dependencies: [
                .target(name: "MLXStructured"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),
        // Unit tests
        .testTarget(
            name: "MLXStructuredTests",
            dependencies: [
                .target(name: "MLXStructured"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
            ],
        ),
    ],
    cxxLanguageStandard: .gnucxx17
)
