//
//  TestErrorHandler.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 18.09.2025.
//

import Testing
@testable import MLXStructured

@Test func testEmptyEBNFGrammar() async throws {
    #expect(throws: XGrammarError.self) {
        let grammar = Grammar.ebnf("")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }
}

@Test func testIncorrectEBNFGrammar() async throws {
    #expect(throws: XGrammarError.self) {
        let grammar = Grammar.ebnf("*")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }
}

@Test func testEmptyRegexGrammar() async throws {
    #expect(throws: XGrammarError.self) {
        let grammar = Grammar.regex("")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }
}

@Test func testIncorrectRegexGrammar() async throws {
    #expect(throws: XGrammarError.self) {
        let grammar = Grammar.regex("*")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }
}

@Test func testEmptyJSONSchemaGrammar() async throws {
    #expect(throws: XGrammarError.self) {
        let grammar = Grammar.schema("")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }
}

@Test func testIncorrectJSONSchemaGrammar() async throws {
    #expect(throws: XGrammarError.self) {
        let grammar = Grammar.schema("*")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }
}
