//
//  TestPerformance.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 19.09.2025.
//

import Testing
@testable import MLXStructured
import MLXLMCommon
import MLXLLM
import MLX

@Test func testLlamaPerformance() async throws {
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
        
    let grammar = try Grammar.schema(.object(
        properties: [
            "a": .string(),
            "b": .integer()
        ], required: [
            "a",
            "b"
        ]
    ))
    
    let grammarMatcher = try XGrammar(vocab: vocab, vocabType: 0, stopTokenIds: [0], grammar: grammar)
    let processor = GrammarMaskedLogitProcessor(grammarMatcher: grammarMatcher)
    let sampler = ArgMaxSampler()
    let input = LMInput(tokens: MLXArray([1, 2, 3, 4, 5]))
    let maxTokens = 512 // Without a stopping criterion, both tests generate up to the maximum number of tokens
    
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
    #expect(slowdown < 0.15) // If it's slower by more than 15%, this indicates something is wrong
    print("Plain duration: \(plainDuration)")
    print("Constrained duration: \(constrainedDuration)")
    print("Constrained decoding slower by \(slowdown.formatted(.percent))")
}

struct ArgMaxSampler: LogitSampler {
    func sample(logits: MLXArray) -> MLXArray {
        argMax(logits, axis: -1)
    }
}
