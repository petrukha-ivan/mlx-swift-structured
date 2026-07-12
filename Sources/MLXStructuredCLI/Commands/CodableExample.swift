//
//  CodableExample.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import Foundation
import ArgumentParser
import JSONSchema
import MLXStructured
import MLXLMCommon

private struct MovieRecord: Codable {
    let title: String
    let year: Int
    let genres: [String]
    let director: String
    let actors: [String]
}

private extension MovieRecord {

    static let instruction = """
        Instruction: Extract movie record from the text according to schema: \(schema)
        """

    static let sample = """
        Text: The Dark Knight (2008) is a superhero crime film directed by Christopher Nolan. Starring Christian Bale, Heath Ledger, and Michael Caine.
        """

    static let schema = JSONSchema.object(
        description: "Movie record",
        properties: [
            "title": .string(),
            "year": .integer(minimum: 1900, maximum: 2026),
            "genres": .array(items: .string(), minItems: 1, maxItems: 3),
            "director": .string(),
            "actors": .array(items: .string(), minItems: 1, maxItems: 5),
        ],
        required: [
            "title",
            "year",
            "genres",
            "director",
            "actors",
        ]
    )
}

struct CodableExample: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "codable",
        abstract: "Generate codable content according to JSON Schema."
    )

    @OptionGroup
    var model: ModelArguments

    func run() async throws {
        let context = try await model.modelContext()
        let prompt = MovieRecord.instruction + "\n" + MovieRecord.sample
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
        let model = try await generate(input: input, context: context, schema: MovieRecord.schema, generating: MovieRecord.self)
        print("Generated model:", model)
    }
}

struct CodableStreamExample: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "codable-stream",
        abstract: "Generate codable content according to JSON Schema."
    )

    @OptionGroup
    var model: ModelArguments

    func run() async throws {
        let context = try await model.modelContext()
        let prompt = MovieRecord.instruction + "\n" + MovieRecord.sample
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
        let stream = try await generate(input: input, context: context, schema: MovieRecord.schema)
        print("Output:", terminator: " ")
        fflush(stdout)
        for await generation in stream {
            switch generation {
            case .chunk(let chunk):
                print(chunk, terminator: "")
                fflush(stdout)
            case .toolCall(let toolCall):
                print("\nTool call:", toolCall)
            case .info(let info):
                print("\n\n\(info.summary())")
            }
        }
    }
}

struct BenchmarkCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "benchmark",
        abstract: "Benchmark generation with and without constrained decoding."
    )

    @Option(help: "Number of warmup iterations to discard.")
    var warmupSteps: Int = 3

    @Option(help: "Number of benchmark iterations to measure.")
    var benchmarkSteps: Int = 10

    @OptionGroup
    var model: ModelArguments

    func run() async throws {
        let context = try await model.modelContext()
        let prompt = MovieRecord.instruction + "\n" + MovieRecord.sample
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt, additionalContext: ["enable_thinking": false]))
        let parameters = GenerateParameters(
            maxTokens: 128,
            temperature: 0.0
        )

        print("\nStarting benchmark with default generation...")
        try await benchmark(label: "Default") {
            let stream = try generate(input: input, parameters: parameters, context: context)
            return
                await stream
                .compactMap(\.info)
                .first { _ in true }
                .unsafelyUnwrapped
        }

        do {
            let stream = try generate(input: input, parameters: parameters, context: context)
            let output = await stream.reduce("", { $0 + ($1.chunk ?? "") })
            print("Default output:", output)
        }

        print("\nStarting benchmark with constrained generation...")
        try await benchmark(label: "Constrained") {
            let grammar = try Grammar.schema(MovieRecord.schema, indent: 2)
            let stream = try await generate(input: input, parameters: parameters, context: context, grammar: grammar)
            return
                await stream
                .compactMap(\.info)
                .first { _ in true }
                .unsafelyUnwrapped
        }

        do {
            let grammar = try Grammar.schema(MovieRecord.schema, indent: 2)
            let stream = try await generate(input: input, parameters: parameters, context: context, grammar: grammar)
            let output = await stream.reduce("", { $0 + ($1.chunk ?? "") })
            print("Constrained output:", output)
        }

        print("\nStarting benchmark with constrained generation and jump forwarding...")
        try await benchmark(label: "Constrained with jump forwarding") {
            let grammar = try Grammar.schema(MovieRecord.schema, indent: 2)
            let stream = try await generate(input: input, parameters: parameters, options: .jumpForwarding, context: context, grammar: grammar)
            return
                await stream
                .compactMap(\.info)
                .first { _ in true }
                .unsafelyUnwrapped
        }

        do {
            let grammar = try Grammar.schema(MovieRecord.schema, indent: 2)
            let stream = try await generate(input: input, parameters: parameters, options: .jumpForwarding, context: context, grammar: grammar)
            let output = await stream.reduce("", { $0 + ($1.chunk ?? "") })
            print("Constrained with jump forwarding output:", output)
        }
    }

    func benchmark(
        label: String,
        processing: () async throws -> GenerateCompletionInfo
    ) async throws {
        for i in 0..<warmupSteps {
            print("Warmup \(i + 1)/\(warmupSteps)...")
            _ = try await processing()
        }

        let clock = ContinuousClock()
        let start = clock.now
        var results = [GenerateCompletionInfo]()
        for i in 0..<benchmarkSteps {
            print("Benchmark \(i + 1)/\(benchmarkSteps)...")
            let result = try await processing()
            results.append(result)
        }

        let totalDuration = clock.now - start
        let promptTokensPerSecond = results.map(\.promptTokensPerSecond)
        let generationTokensPerSecond = results.map(\.tokensPerSecond)
        print("\n\(label) total duration: \(totalDuration.readable)")
        print("\(label) prompt tokens: \(results[0].promptTokenCount)")
        print("\(label) generated tokens: \(results[0].generationTokenCount)")
        print("\(label) prompt: \(promptTokensPerSecond.median.short) ± \(promptTokensPerSecond.std.short) t/s")
        print("\(label) generation: \(generationTokensPerSecond.median.short) ± \(generationTokensPerSecond.std.short) t/s")
    }
}

extension Array where Element: BinaryFloatingPoint {
    var std: Element {
        let mean = reduce(0, +) / Element(count)
        let variance = map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Element(count)
        return Element(sqrt(Double(variance)))
    }
}

extension Array where Element: Comparable {
    var median: Element {
        sorted()[count / 2]
    }
}

extension Duration {
    var readable: String {
        formatted(.units(allowed: [.seconds, .milliseconds]))
    }
}

extension Double {
    var short: String {
        formatted(.number.precision(.fractionLength(1)))
    }
}
