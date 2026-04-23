//
//  TestRepetitionCompile.swift
//  MLXStructured
//
//  Timing test for JSON schema with repetition structures.
//

import Testing
@testable import MLXStructured

struct RepetitionCompileTests {

    @Test func `Schema with maxItems and maxLength compiles quickly`() throws {
        let vocab = ["<eos>"] + (0...0xFFFF).compactMap({ UnicodeScalar($0).map(String.init) })
        let tokenizerInfo = TokenizerInfo(vocab: vocab, vocabType: 0, stopTokenIds: [0])
        let compiler = try GrammarCompiler(tokenizerInfo: tokenizerInfo)

        let grammar = try Grammar.schema(
            .object(
                properties: [
                    "items": .array(
                        items: .string(maxLength: 512),
                        maxItems: 48
                    ),
                ],
                required: ["items"]
            )
        )

        let clock = ContinuousClock()
        let start = clock.now
        let _ = try compiler.compile(grammar: grammar)
        let duration = clock.now - start

        print("Repetition schema compilation duration: \(duration)")
        #expect(duration < .seconds(30), "Schema with maxItems:48 and maxLength:512 should compile in under 30s, took \(duration)")
    }
}
