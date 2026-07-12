//
//  GrammarMaskedTokenIterator.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 12.07.2026.
//

import Foundation
import MLX
import MLXLMCommon

public struct CompositeLogitProcessor: LogitProcessor {

    private var processors: [any LogitProcessor]

    public init(_ processors: [any LogitProcessor]) {
        self.processors = processors
    }

    public mutating func prompt(_ prompt: MLXArray) {
        for index in processors.indices {
            processors[index].prompt(prompt)
        }
    }

    public func process(logits: MLXArray) -> MLXArray {
        processors.reduce(logits) { logits, processor in
            processor.process(logits: logits)
        }
    }

    public mutating func didSample(token: MLXArray) {
        for index in processors.indices {
            processors[index].didSample(token: token)
        }
    }
}

public struct GrammarConstrainedTokenIterator: TokenIteratorProtocol {

    private let model: any LanguageModel
    private var processor: LogitProcessor
    private let sampler: LogitSampler
    private var state: LMOutput.State?
    private var current: LMInput.Text
    private var cache: [KVCache]
    private let parameters: GenerateParameters

    public private(set) var tokenCount = 0
    public private(set) var promptPrefillTime: TimeInterval = 0

    public var maxTokens: Int? {
        parameters.maxTokens
    }

    public init(
        input: LMInput,
        model: any LanguageModel,
        cache: [KVCache]? = nil,
        grammarMatcher: GrammarMatcher,
        parameters: GenerateParameters
    ) throws {
        self.model = model
        self.current = input.text
        self.cache = cache ?? model.newCache(parameters: parameters)
        self.parameters = parameters

        let penaltiesProcessor = parameters.processor()
        let grammarProcessor = GrammarMaskedLogitProcessor(grammarMatcher: grammarMatcher)
        let compositeProcessor = CompositeLogitProcessor([penaltiesProcessor, grammarProcessor].compactMap(\.self))
        processor = compositeProcessor
        sampler = parameters.sampler()

        let start = Date.timeIntervalSinceReferenceDate
        try prepare(input)
        promptPrefillTime = Date.timeIntervalSinceReferenceDate - start
    }

    private mutating func prepare(_ input: LMInput) throws {
        processor.prompt(input.text.tokens)

        switch try model.prepare(input, cache: cache, windowSize: parameters.prefillStepSize) {
        case .tokens(let tokens):
            current = .init(tokens: step(tokens))
        case .logits(let output):
            state = output.state
            current = .init(tokens: sample(output.logits))
        }

        asyncEval(current.tokens)
    }

    private mutating func step(_ input: LMInput.Text) -> MLXArray {
        let output = withPreparedCache(cache, lengths: input.sequenceLengths) {
            model(input[text: .newAxis], cache: cache, state: state)
        }

        state = output.state
        maybeQuantizeKVCache(
            cache: &cache,
            kvBits: parameters.kvBits,
            kvGroupSize: parameters.kvGroupSize,
            quantizedKVStart: parameters.quantizedKVStart,
            kvScheme: parameters.kvScheme
        )

        return sample(output.logits)
    }

    private mutating func sample(_ logits: MLXArray) -> MLXArray {
        let logits = processor.process(logits: logits[0..., -1, 0...])
        let token = sampler.sample(logits: logits)
        processor.didSample(token: token)
        return token
    }

    public mutating func next() -> Int? {
        if let maxTokens, tokenCount >= maxTokens {
            return nil
        }

        let previous = current
        current = .init(tokens: step(previous))
        asyncEval(current.tokens)
        tokenCount += 1

        return previous.tokens.item(Int.self)
    }
}
