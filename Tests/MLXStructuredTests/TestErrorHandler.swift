//
//  TestErrorHandler.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 18.09.2025.
//

import Testing
@testable import MLXStructured

@Test func testEmptyEBNFGrammar() async throws {
    #expect(performing: {
        let grammar = Grammar.ebnf("")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }, throws: { error in
        switch error {
        case XGrammarError.emptyGrammar:
            return true
        default:
            return false
        }
    })
}

@Test func testIncorrectEBNFGrammar() async throws {
    #expect(performing: {
        let grammar = Grammar.ebnf("*")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }, throws: { error in
        switch error {
        case XGrammarError.invalidGrammar(let message):
            return message.contains("The root rule with name \"root\" is not found")
        default:
            return false
        }
    })
}

@Test func testEmptyRegexGrammar() async throws {
    #expect(performing: {
        let grammar = Grammar.regex("")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }, throws: { error in
        switch error {
        case XGrammarError.emptyGrammar:
            return true
        default:
            return false
        }
    })
}

@Test func testIncorrectRegexGrammar() async throws {
    #expect(performing: {
        let grammar = Grammar.regex("*")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }, throws: { error in
        switch error {
        case XGrammarError.invalidGrammar(let message):
            return message.contains("Expect element, but got *")
        default:
            return false
        }
    })
}

@Test func testEmptyJSONSchemaGrammar() async throws {
    #expect(performing: {
        let grammar = Grammar.schema("")
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }, throws: { error in
        switch error {
        case XGrammarError.emptyGrammar:
            return true
        default:
            return false
        }
    })
}

@Test func testIncorrectJSONSchemaGrammar() async throws {
    #expect(performing: {
        let grammar = Grammar.schema(#"{"type": "foo"}"#)
        let _ = try XGrammar(vocab: ["a", "b", "c"], grammar: grammar)
    }, throws: { error in
        switch error {
        case XGrammarError.invalidGrammar(let message):
            return message.contains("Unsupported type \"foo\"")
        default:
            return false
        }
    })
}
