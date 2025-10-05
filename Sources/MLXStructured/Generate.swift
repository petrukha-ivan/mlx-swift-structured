//
//  Generate.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 27.09.2025.
//

import Foundation
import JSONSchema
import MLXLMCommon
import MLX

#if canImport(FoundationModels)
import FoundationModels
#endif

public func generate(
    input: LMInput,
    parameters: GenerateParameters = GenerateParameters(),
    context: ModelContext,
    grammar: Grammar,
    didGenerate: ([Int]) -> GenerateDisposition = { _ in .more }
) async throws -> GenerateResult {
    let sampler = parameters.sampler()
    let processor = try await GrammarMaskedLogitProcessor.from(configuration: context.configuration, grammar: grammar)
    let iterator = try TokenIterator(input: input, model: context.model, processor: processor, sampler: sampler)
    let result = generate(input: input, context: context, iterator: iterator, didGenerate: didGenerate)
    return result
}

public func generate<Content: Decodable>(
    input: LMInput,
    parameters: GenerateParameters = GenerateParameters(),
    context: ModelContext,
    schema: JSONSchema,
    generating: Content.Type,
    indent: Int? = nil,
    didGenerate: ([Int]) -> GenerateDisposition = { _ in .more }
) async throws -> (GenerateResult, Content) {
    let grammar = try Grammar.schema(schema, indent: indent)
    let sampler = parameters.sampler()
    let processor = try await GrammarMaskedLogitProcessor.from(configuration: context.configuration, grammar: grammar)
    let iterator = try TokenIterator(input: input, model: context.model, processor: processor, sampler: sampler)
    let result = generate(input: input, context: context, iterator: iterator, didGenerate: didGenerate)
    let content = try JSONDecoder().decode(Content.self, from: Data(result.output.utf8))
    return (result, content)
}

#if compiler(>=6.2)
@available(macOS 26.0, iOS 26.0, *)
public func generate<Content: Generable>(
    input: LMInput,
    parameters: GenerateParameters = GenerateParameters(),
    context: ModelContext,
    generating: Content.Type,
    indent: Int? = nil,
    didGenerate: ([Int]) -> GenerateDisposition = { _ in .more }
) async throws -> (GenerateResult, Content) {
    let sampler = parameters.sampler()
    let grammar = try Grammar.generable(Content.self, indent: indent)
    let processor = try await GrammarMaskedLogitProcessor.from(configuration: context.configuration, grammar: grammar)
    let iterator = try TokenIterator(input: input, model: context.model, processor: processor, sampler: sampler)
    let result = generate(input: input, context: context, iterator: iterator, didGenerate: didGenerate)
    let content = try Content(GeneratedContent(json: result.output))
    return (result, content)
}

@available(macOS 26.0, iOS 26.0, *)
public func generate<Content: Generable>(
    input: LMInput,
    parameters: GenerateParameters = GenerateParameters(),
    context: ModelContext,
    generating: Content.Type,
    indent: Int? = nil
) async throws -> AsyncStream<Content.PartiallyGenerated> {
    let sampler = parameters.sampler()
    let grammar = try Grammar.generable(Content.self, indent: indent)
    let processor = try await GrammarMaskedLogitProcessor.from(configuration: context.configuration, grammar: grammar)
    let iterator = try TokenIterator(input: input, model: context.model, processor: processor, sampler: sampler)
    let stream = generate(input: input, context: context, iterator: iterator)
    return AsyncStream { continuation in
        
        let task = Task {
            var output = ""
            for await generation in stream {
                if let chunk = generation.chunk {
                    output.append(chunk)
                    let generatedContent = try GeneratedContent(json: output)
                    let partiallyGenerated = try Content.PartiallyGenerated(generatedContent)
                    continuation.yield(partiallyGenerated)
                }
            }
            
            continuation.finish()
        }
        
        continuation.onTermination = { _ in
            task.cancel()
        }
    }
}
#endif
