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

@main
struct GenerateStructuredOutputCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generates structured output using constrained decoding."
    )
    
    func run() async throws {
//        let configuration = ModelConfiguration(id: "mlx-community/Qwen3-4B-Instruct-2507-4bit")
//        let configuration = ModelConfiguration(id: "mlx-community/Llama-3.2-3B-Instruct-4bit")
        let configuration = ModelConfiguration(id: "mlx-community/gemma-3-270m-it-4bit", extraEOSTokens: ["<end_of_turn>"])
        let context = try await LLMModelFactory.shared.load(configuration: configuration) { progress in
            print("Loading model: \(progress.fractionCompleted.formatted(.percent))")
        }
        
        let grammar = try Grammar.schema(.object(
            description: "Movie record",
            properties: [
                "title": .string(),
                "year": .integer(),
                "genres": .array(items: .string(), maxItems: 3),
                "director": .string(),
                "actors": .array(items: .string(), maxItems: 10)
            ], required: [
                "title",
                "year",
                "genres",
                "director",
                "actors"
            ]
        ))
        
        let prompt = """
        Instruction: Extract movie record from the text, output in JSON format according to schema: \(grammar.raw)
        Text: The Dark Knight (2008) is a superhero crime film directed by Christopher Nolan. Starring Christian Bale, Heath Ledger, and Michael Caine. 
        """
        
        // Plain generation
        do {
            let input = try await context.processor.prepare(input: .init(prompt: prompt))
            let sampler = ArgMaxSampler()
            let iterator = try TokenIterator(input: input, model: context.model, processor: nil, sampler: sampler, maxTokens: 256)
            var outputTokens: [Int] = []
            let completionInfo: GenerateCompletionInfo = MLXLMCommon.generate(input: input, context: context, iterator: iterator) { token in
                outputTokens.append(token)
                return .more
            }
            print(completionInfo.summary())
            print("Plain generation:", context.tokenizer.decode(tokens: outputTokens))
        }
        
        // Constrained generation
        do {
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
            print("Constrained generation:", context.tokenizer.decode(tokens: outputTokens))
        }
    }
}

struct ArgMaxSampler: LogitSampler {
    func sample(logits: MLXArray) -> MLXArray {
        argMax(logits, axis: -1)
    }
}
