//
//  GrammarMaskedTokenIterator.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 12.07.2026.
//

import Foundation
import Collections
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

public struct GrammarConstrainedJumpForwardTokenIterator: TokenIteratorProtocol {

    private let model: any LanguageModel
    private var processor: any LogitProcessor
    private let sampler: any LogitSampler
    private var state: LMOutput.State?
    private var current: LMInput.Text
    private var cache: [KVCache]
    private let parameters: GenerateParameters
    private let tokenizer: any Tokenizer
    private let grammarMatcher: GrammarMatcher
    private var pendingTokens: Deque<Int> = []

    public private(set) var tokenCount = 0
    public private(set) var promptPrefillTime: TimeInterval = 0

    public var maxTokens: Int? {
        parameters.maxTokens
    }

    public init(
        input: LMInput,
        model: any LanguageModel,
        cache: [KVCache]? = nil,
        tokenizer: any Tokenizer,
        grammarMatcher: GrammarMatcher,
        parameters: GenerateParameters
    ) throws {
        self.model = model
        self.current = input.text
        self.cache = cache ?? model.newCache(parameters: parameters)
        self.parameters = parameters
        self.tokenizer = tokenizer
        self.grammarMatcher = grammarMatcher

        let penaltiesProcessor = parameters.processor()
        let grammarProcessor = EagerGrammarMaskedLogitProcessor(grammarMatcher: grammarMatcher)
        let compositeProcessor = CompositeLogitProcessor([penaltiesProcessor, grammarProcessor].compactMap(\.self))
        processor = compositeProcessor
        sampler = parameters.sampler()

        let start = Date.timeIntervalSinceReferenceDate
        try prepare(input)
        promptPrefillTime = Date.timeIntervalSinceReferenceDate - start
    }

    private mutating func prepare(_ input: LMInput) throws {
        processor.prompt(input.text.tokens)

        var input = input
        let jumpForwardString = grammarMatcher.findJumpForwardString()
        let jumpForwardTokens = tokenizer.encode(text: jumpForwardString, addSpecialTokens: false)
        if !jumpForwardTokens.isEmpty {
            grammarMatcher.accept(string: jumpForwardString)
            pendingTokens.append(contentsOf: jumpForwardTokens)
            input = LMInput(
                text: .init(
                    tokens: concatenated([
                        input.text.tokens,
                        jumpForwardTokens.asMLXArray(dtype: input.text.tokens.dtype),
                    ])
                ),
                image: input.image,
                video: input.video,
                audio: input.audio
            )
        }

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

        pendingTokens.append(token.item(Int.self))
        if grammarMatcher.isTerminated() {
            return token
        }

        let jumpForwardString = grammarMatcher.findJumpForwardString()
        let jumpForwardTokens = tokenizer.encode(text: jumpForwardString, addSpecialTokens: false)
        if !jumpForwardTokens.isEmpty {
            grammarMatcher.accept(string: jumpForwardString)
            pendingTokens.append(contentsOf: jumpForwardTokens)
            if grammarMatcher.isTerminated() {
                return token
            }

            let tokens = [token.item(Int.self)] + jumpForwardTokens
            return step(.init(tokens: MLXArray(tokens).asType(token.dtype)))
        }

        return token
    }

    public mutating func next() -> Int? {
        if let maxTokens, tokenCount >= maxTokens {
            return nil
        }

        if let token = pendingTokens.popFirst() {
            tokenCount += 1
            return token
        }

        if grammarMatcher.isTerminated() {
            return nil
        }

        current = .init(tokens: step(current))
        asyncEval(current.tokens)

        if let token = pendingTokens.popFirst() {
            tokenCount += 1
            return token
        }

        return nil
    }
}
