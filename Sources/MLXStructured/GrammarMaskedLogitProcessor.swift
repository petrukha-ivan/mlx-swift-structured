//
//  GrammarMaskedLogitProcessor.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 14.09.2025.
//

import MLXLMCommon
import MLX

public final class GrammarMaskedLogitProcessor: LogitProcessor, @unchecked Sendable {
    
    public let grammarMatcher: GrammarMatcher
    
    public init(grammarMatcher: GrammarMatcher) {
        self.grammarMatcher = grammarMatcher
    }
    
    public func prompt(_ prompt: MLXArray) {
        grammarMatcher.reset()
    }
    
    public func process(logits: MLXArray) -> MLXArray {
        return logits + grammarMatcher.nextTokenMask()
    }
    
    public func didSample(token: MLXArray) {
        grammarMatcher.advance(token: token)
    }
}
