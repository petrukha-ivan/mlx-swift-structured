//
//  TestGenerablePerformance.swift
//  MLXStructured
//
//  Created by Rudrank Riyam on 21.09.2025.
//

import Testing
@testable import MLXStructured
import MLXLMCommon
import MLXLLM
import MLX

#if canImport(FoundationModels)
import FoundationModels
#endif

#if compiler(>=6.2)
@available(macOS 26.0, iOS 26.0, *)
@Generable
private struct PerformanceRecord: Codable {
    @Guide(description: "Simple string field")
    let text: String

    @Guide(description: "Simple integer field")
    let value: Int
}

@Test func testGenerableLlamaPerformance() async throws {
    guard #available(macOS 26.0, iOS 26.0, *) else { return }

    let vocab = ["<eos>"] + (0...0xFFFF).compactMap({ UnicodeScalar($0).map(String.init) })
    let model = LlamaModel(.init(
        hiddenSize: 128,
        hiddenLayers: 16,
        intermediateSize: 512,
        attentionHeads: 32,
        rmsNormEps: 1e-5,
        vocabularySize: vocab.count,
        kvHeads: 8
    ))

    let grammar = try Grammar.schema(generable: PerformanceRecord.self)
    let grammarMatcher = try XGrammar(vocab: vocab, vocabType: 0, stopTokenIds: [0], grammar: grammar)
    let processor = GrammarMaskedLogitProcessor(grammarMatcher: grammarMatcher)
    let sampler = ArgMaxSampler()
    let input = LMInput(tokens: MLXArray([1, 2, 3, 4, 5]))
    let maxTokens = 512

    let clock = ContinuousClock()
    for _ in 0..<3 { // Warmup to stabilize results
        let iterator = try TokenIterator(input: input, model: model, processor: nil, sampler: sampler, maxTokens: maxTokens)
        let _ = Array(iterator)
    }
    
    let plainIterator = try TokenIterator(input: input, model: model, processor: nil, sampler: sampler, maxTokens: maxTokens)
    let plainStart = clock.now
    let _ = Array(plainIterator)
    let plainDuration = clock.now - plainStart

    let constrainedIterator = try TokenIterator(input: input, model: model, processor: processor, sampler: sampler, maxTokens: maxTokens)
    let constrainedStart = clock.now
    let _ = Array(constrainedIterator)
    let constrainedDuration = clock.now - constrainedStart

    let slowdown = (constrainedDuration / plainDuration) - 1
    #expect(slowdown < 0.15)  // If it's slower by more than 15%, this indicates something is wrong
    print("Plain duration: \(plainDuration)")
    print("Generable constrained duration: \(constrainedDuration)")
    print("Generable constrained decoding slower by \(slowdown.formatted(.percent))")
}
#endif
