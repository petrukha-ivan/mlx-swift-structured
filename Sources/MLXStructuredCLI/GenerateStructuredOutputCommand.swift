//
//  GenerateStructuredOutputCommand.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 15.09.2025.
//

import Foundation
import ArgumentParser
import JSONSchema
import MLXStructured
import MLXLMCommon
import MLXLLM
import MLX
import Hub

#if canImport(FoundationModels)
import FoundationModels
#endif

@main
struct GenerateStructuredOutputCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generates structured output using constrained decoding."
    )
    
    @Flag(name: .long, help: "Use @Generable MovieRecord type (requires macOS 26 / iOS 26).")
    var useGenerableSchema = false

    func run() async throws {
//        let configuration = ModelConfiguration(id: "mlx-community/Qwen3-4B-Instruct-2507-4bit")
//        let configuration = ModelConfiguration(id: "mlx-community/Llama-3.2-3B-Instruct-4bit")
//        let configuration = ModelConfiguration(id: "mlx-community/gemma-3-270m-it-4bit", extraEOSTokens: ["<end_of_turn>"])
        let configuration = ModelConfiguration(id: "Qwen/Qwen3-1.7B-MLX-4bit")
        let context = try await LLMModelFactory.shared.load(configuration: configuration) { progress in
            print("Loading model: \(progress.fractionCompleted.formatted(.percent))")
        }
        
        let grammar = try MovieRecordDemo.makeGrammar(useGenerable: useGenerableSchema)
        let prompt = MovieRecordDemo.prompt(schema: grammar)
        
        // Plain generation
        do {
            print("Starting plain generation..")
            let input = try await context.processor.prepare(input: .init(prompt: prompt))
            let sampler = ArgMaxSampler()
            let iterator = try TokenIterator(input: input, model: context.model, processor: nil, sampler: sampler, maxTokens: 256)
            var outputTokens: [Int] = []
            let completionInfo: GenerateCompletionInfo = MLXLMCommon.generate(input: input, context: context, iterator: iterator) { token in
                outputTokens.append(token)
                return .more
            }
            print(completionInfo.summary())
            let outputString = context.tokenizer.decode(tokens: outputTokens)
            print("Plain generation:\n\(String.divider)\n\(outputString)\n\(String.divider)\n")
        }
        
        // Constrained generation
        do {
            print("Starting constrained generation..")
            let input = try await context.processor.prepare(input: .init(prompt: prompt))
            let sampler = ArgMaxSampler()
            let processor = try await GrammarMaskedLogitProcessor.from(configuration: configuration, grammar: grammar)
            let iterator = try TokenIterator(input: input, model: context.model, processor: processor, sampler: sampler, maxTokens: 256)
            var outputTokens: [Int] = []
            let completionInfo: GenerateCompletionInfo = MLXLMCommon.generate(input: input, context: context, iterator: iterator) { token in
                outputTokens.append(token)
                return .more
            }
            print(completionInfo.summary())
            let outputString = context.tokenizer.decode(tokens: outputTokens)
            print("Constrained generation:\n\(String.divider)\n\(outputString)\n\(String.divider)\n")

            if useGenerableSchema {
                #if compiler(>=6.2)
                if #available(macOS 26.0, iOS 26.0, *) {
                    do {
                        let record = try MovieRecord(.init(json: outputString))
                        print("Parsed movie record:", record)
                    } catch {
                        print("Failed to decode MovieRecord:", error)
                    }
                } else {
                    print("Warning: Generable decoding requested on an unsupported platform.")
                }
                #else
                print("Warning: Generable decoding requested on an unsupported platform.")
                #endif
            }
        }
    }
}

struct ArgMaxSampler: LogitSampler {
    func sample(logits: MLXArray) -> MLXArray {
        argMax(logits, axis: -1)
    }
}

private enum MovieRecordDemo {
    private static let context = """
    Text: The Dark Knight (2008) is a superhero crime film directed by Christopher Nolan. Starring Christian Bale, Heath Ledger, and Michael Caine.
    """

    static func makeGrammar(useGenerable: Bool) throws -> Grammar {
        if useGenerable {
            #if compiler(>=6.2)
            guard #available(macOS 26.0, iOS 26.0, *) else {
                throw ValidationError("@Generable schemas require macOS 26 / iOS 26 or later.")
            }
            print("Using @Generable schema for: \(MovieRecord.self)")
            return try Grammar.schema(generable: MovieRecord.self)
            #else
            throw ValidationError("@Generable schemas require Swift 6.2 or later.")
            #endif
        } else {
            return .schema(rawSchema, indent: 2)
        }
    }

    private static let rawSchema: String = {
        let schema = JSONSchema.object(
            description: "Movie record",
            properties: [
                "title": .string(),
                "year": .integer(),
                "genres": .array(items: .string(), maxItems: 3),
                "director": .string(),
                "actors": .array(items: .string(), maxItems: 10)
            ],
            required: ["title", "year", "genres", "director", "actors"]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(schema),
              let string = String(data: data, encoding: .utf8) else {
            fatalError("Failed to build raw JSON schema string for MovieRecord.")
        }
        return string
    }()

    static func prompt(schema: Grammar) -> String {
        """
        Instruction: Extract movie record from the text according to schema: \(schema.raw)
        \(context)
        """
    }
}

#if compiler(>=6.2)
@available(macOS 26.0, iOS 26.0, *)
@Generable
struct MovieRecord: Codable {
    @Guide(description: "Movie title")
    let title: String

    @Guide(description: "Release year")
    let year: Int

    @Guide(description: "List of genres")
    let genres: [String]

    @Guide(description: "Director name")
    let director: String

    @Guide(description: "List of principal actors")
    let actors: [String]
}
#endif

extension String {
    static let divider = String(repeating: "-", count: 64)
}
