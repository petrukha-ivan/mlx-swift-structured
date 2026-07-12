//
//  TestGrammarMatcher.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 16.09.2025.
//

import Testing
@testable import MLXStructured
import MLX

struct GrammarMatcherTests {

    @Test func `EBNF grammar matcher finds and accepts jump forward string`() async throws {
        let vocab = ["Y", "E", "S", "!", "?"]
        let grammar = Grammar.ebnf(#"root ::= "YES" ("!" | "?")"#)
        let grammarMatcher = try XGrammar(vocab: vocab, stopTokenIds: [], grammar: grammar)

        #expect(grammarMatcher.findJumpForwardString() == "YES")
        grammarMatcher.accept(string: "YES")

        let mask = grammarMatcher.nextTokenMask()
        let allowed = mask.exp().asArray(Int.self)
        #expect(allowed == [0, 0, 0, 1, 1])
    }

    @Test func `EBNF grammar matcher respects accepted jump forward string`() async throws {
        let vocab = ["Y", "E", "S", "!", "?"]
        let grammar = Grammar.ebnf(#"root ::= "YES" ("!" | "?")"#)
        let grammarMatcher = try XGrammar(vocab: vocab, stopTokenIds: [], grammar: grammar)

        #expect(grammarMatcher.findJumpForwardString() == "YES")
        grammarMatcher.accept(string: "YES")

        let mask = grammarMatcher.nextTokenMask()
        let allowed = mask.exp().asArray(Int.self)
        #expect(allowed == [0, 0, 0, 1, 1])

        grammarMatcher.accept(token: MLXArray(3))
        #expect(grammarMatcher.findJumpForwardString() == "")
    }

    @Test func `EBNF grammar matcher accepts YES sequence`() async throws {
        let vocab = ["Y", "E", "S", "N", "O"]
        let grammar = Grammar.ebnf(#"root ::= ("YES" | "NO")"#)
        let grammarMatcher = try XGrammar(vocab: vocab, stopTokenIds: [], grammar: grammar)

        let advances: [Int] = "YES".map(String.init).compactMap({ vocab.firstIndex(of: $0) })
        let expectations: [[Int]] = [
            [1, 0, 0, 1, 0],  // "Y" or "N"
            [0, 1, 0, 0, 0],  // "E"
            [0, 0, 1, 0, 0],  // "S"
        ]

        for (expectation, advance) in zip(expectations, advances) {
            let mask = grammarMatcher.nextTokenMask()
            let allowed = mask.exp().asArray(Int.self)
            #expect(allowed == expectation)
            grammarMatcher.accept(token: MLXArray(advance))
        }
    }

    @Test func `EBNF grammar matcher allows EOS after valid sequence`() async throws {
        let vocab = ["<eos>", "Y", "E", "S", "N", "O"]
        let grammar = Grammar.ebnf(#"root ::= ("YES" | "NO")"#)
        let grammarMatcher = try XGrammar(vocab: vocab, stopTokenIds: [0], grammar: grammar)

        let advances: [Int] = "YES".map(String.init).compactMap({ vocab.firstIndex(of: $0) }) + [0]
        let expectations: [[Int]] = [
            [0, 1, 0, 0, 1, 0],  // "Y" or "N"
            [0, 0, 1, 0, 0, 0],  // "E"
            [0, 0, 0, 1, 0, 0],  // "S"
            [1, 0, 0, 0, 0, 0],  // "<eos>"
        ]

        for (expectation, advance) in zip(expectations, advances) {
            let mask = grammarMatcher.nextTokenMask()
            let allowed = mask.exp().asArray(Int.self)
            #expect(allowed == expectation)
            grammarMatcher.accept(token: MLXArray(advance))
        }
    }

    @Test func `Regex email grammar matcher enforces token constraints`() async throws {
        let vocab = ["<eos>", "a", "b", "c", "@", "."]
        let grammar = Grammar.regex(#"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#)  // Simple email regex
        let grammarMatcher = try XGrammar(vocab: vocab, stopTokenIds: [0], grammar: grammar)

        let advances: [Int] = "abc@ab.cc".map(String.init).compactMap({ vocab.firstIndex(of: $0) }) + [0]
        let expectations: [[Int]] = [
            [0, 1, 1, 1, 0, 1],  // Not "@" nor "<eos>
            [0, 1, 1, 1, 1, 1],  // Not "<eos>"
            [0, 1, 1, 1, 1, 1],  // Not "<eos>"
            [0, 1, 1, 1, 1, 1],  // Not "<eos>"
            [0, 1, 1, 1, 0, 1],  // Not "@" nor "<eos>"
            [0, 1, 1, 1, 0, 1],  // Not "@" nor "<eos>"
            [0, 1, 1, 1, 0, 1],  // Not "@" nor "<eos>"
            [0, 1, 1, 1, 0, 1],  // Not "@" nor "<eos>"
            [0, 1, 1, 1, 0, 1],  // Not "@" nor "<eos>"
            [1, 1, 1, 1, 0, 1],  // Not "@"
        ]

        for (expectation, advance) in zip(expectations, advances) {
            let mask = grammarMatcher.nextTokenMask()
            let allowed = mask.exp().asArray(Int.self)
            #expect(allowed == expectation)
            grammarMatcher.accept(token: MLXArray(advance))
        }
    }

    @Test func `Regex phone grammar matcher enforces token constraints`() async throws {
        let vocab = ["<eos>", "+", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", " "]
        let grammar = Grammar.regex(#"^\+[0-9\s]{7,15}$"#)  // Simple phone regex
        let grammarMatcher = try XGrammar(vocab: vocab, stopTokenIds: [0], grammar: grammar)

        let advances: [Int] = "+1 234 5678".map(String.init).compactMap({ vocab.firstIndex(of: $0) }) + [0]
        let expectations: [[Int]] = [
            [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  // "+"
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+" or "<eos>"
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+" or "<eos>"
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+" or "<eos>"
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+" or "<eos>"
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+" or "<eos>"
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+" or "<eos>"
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+" or "<eos>"
            [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+"
            [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+"
            [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+"
            [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  // Any decimal but not "+"
        ]

        for (expectation, advance) in zip(expectations, advances) {
            let mask = grammarMatcher.nextTokenMask()
            let allowed = mask.exp().asArray(Int.self)
            #expect(allowed == expectation)
            grammarMatcher.accept(token: MLXArray(advance))
        }
    }

    @Test func `JSON schema grammar matcher accepts required object payload`() async throws {
        let vocab = ["<eos>", "{", "}", ":", " ", "\"", "a", "b"]
        let grammar = try Grammar.schema(.object(properties: ["a": .string()], required: ["a"]))
        let grammarMatcher = try XGrammar(vocab: vocab, stopTokenIds: [0], grammar: grammar)

        let advances: [Int] = #"{"a": "b"}"#.map(String.init).compactMap({ vocab.firstIndex(of: $0) }) + [0]
        let expectations: [[Int]] = [
            [0, 1, 0, 0, 0, 0, 0, 0],  // "{"
            [0, 0, 0, 0, 0, 1, 0, 0],  // """
            [0, 0, 0, 0, 0, 0, 1, 0],  // "a"
            [0, 0, 0, 0, 0, 1, 0, 0],  // """
            [0, 0, 0, 1, 0, 0, 0, 0],  // ":"
            [0, 0, 0, 0, 1, 0, 0, 0],  // " "
            [0, 0, 0, 0, 0, 1, 0, 0],  // """
            [0, 1, 1, 1, 1, 1, 1, 1],  // Any char except "<eos>"
            [0, 1, 1, 1, 1, 1, 1, 1],  // Any char except "<eos>"
            [0, 0, 1, 0, 0, 0, 0, 0],  // "}"
            [1, 0, 0, 0, 0, 0, 0, 0],  // "<eos>"
        ]

        for (expectation, advance) in zip(expectations, advances) {
            let mask = grammarMatcher.nextTokenMask()
            let allowed = mask.exp().asArray(Int.self)
            #expect(allowed == expectation)
            grammarMatcher.accept(token: MLXArray(advance))
        }
    }
}
