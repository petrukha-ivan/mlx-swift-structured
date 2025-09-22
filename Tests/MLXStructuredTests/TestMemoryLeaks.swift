//
//  TestMemoryLeaks.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 21.09.2025.
//

import Testing
import Foundation
@testable import MLXStructured

// This test never fails, but it is still useful for checking memory in the profiler
// Memory usage is currently stable and never exceeds 30 MB
@Test func testMemoryLeaks() async throws {
    for _ in 0..<100 {
        try autoreleasepool {
            let vocab = ["<eos>"] + (0...0xFFFF).compactMap({ UnicodeScalar($0).map(String.init) })
            let grammar = try Grammar.schema(.object(properties: ["a": .string(), "b": .integer()]))
            let grammarMatcher = try XGrammar(vocab: vocab, vocabType: 0, stopTokenIds: [0], grammar: grammar)
            _ = grammarMatcher.nextTokenMask()
        }
    }
}
