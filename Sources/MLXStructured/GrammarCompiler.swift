//
//  GrammarCompiler.swift
//  mlx-swift-structured
//
//  Created by Ivan Petrukha on 03.04.2026.
//

import Foundation
import CMLXStructured

final class CompiledGrammar: @unchecked Sendable {

    let pointer: UnsafeMutableRawPointer

    var vocabSize: Int {
        max(0, Int(compiled_grammar_vocab_size(pointer)))
    }

    init(pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    deinit {
        compiled_grammar_free(pointer)
    }
}

final class GrammarCompiler: @unchecked Sendable {

    let pointer: UnsafeMutableRawPointer

    init(
        tokenizerInfo: TokenizerInfo,
        maxThreads: Int32 = 8,
        cacheEnabled: Bool = true,
        maxMemoryBytes: Int64 = -1
    ) throws {
        self.pointer = try withCErrorHandling {
            let vocab = tokenizerInfo.vocab.map { strdup($0) }
            let tokenizerInfo = withCErrorHandling {
                vocab.map({ UnsafePointer($0) }).withUnsafeBufferPointer { vocabBuffer in
                    tokenizerInfo.stopTokenIds.withUnsafeBufferPointer { stopTokenIdsBuffer in
                        tokenizer_info_new(
                            vocabBuffer.baseAddress,
                            vocabBuffer.count,
                            tokenizerInfo.vocabType,
                            stopTokenIdsBuffer.baseAddress,
                            stopTokenIdsBuffer.count
                        )
                    }
                }
            }

            defer {
                tokenizer_info_free(tokenizerInfo)
                vocab.forEach {
                    free($0)
                }
            }

            guard let tokenizerInfo else {
                throw XGrammarError.invalidVocab(CErrorHandler.lastErrorMessage)
            }

            let grammarCompiler = grammar_compiler_new(
                tokenizerInfo,
                maxThreads,
                cacheEnabled ? 1 : 0,
                maxMemoryBytes
            )

            guard let grammarCompiler else {
                throw XGrammarError.invalidVocab(CErrorHandler.lastErrorMessage)
            }

            return grammarCompiler
        }
    }

    deinit {
        grammar_compiler_free(pointer)
    }

    func compile(grammar: Grammar) throws -> CompiledGrammar {
        switch grammar {
        case .ebnf(let ebnf) where ebnf.isEmpty:
            throw XGrammarError.emptyGrammar
        case .regex(let regex) where regex.isEmpty:
            throw XGrammarError.emptyGrammar
        case .schema(let schema, _) where schema.isEmpty:
            throw XGrammarError.emptyGrammar
        case .structural(let tag) where tag.isEmpty:
            throw XGrammarError.emptyGrammar
        default:
            break
        }

        let compiledGrammar = withCErrorHandling {
            switch grammar {
            case .ebnf(let ebnf):
                return ebnf.utf8CString.withUnsafeBufferPointer {
                    grammar_compiler_compile_ebnf(pointer, $0.baseAddress, $0.count - 1)
                }
            case .regex(let regex):
                return regex.utf8CString.withUnsafeBufferPointer {
                    grammar_compiler_compile_regex(pointer, $0.baseAddress, $0.count - 1)
                }
            case .schema(let schema, let format):
                return schema.utf8CString.withUnsafeBufferPointer { schemaBuffer in
                    let (anyWhitespace, indent): (Int32, Int32) =
                        switch format.whitespace {
                        case .any: (1, -1)
                        case .none: (0, -1)
                        case .indent(let count): (0, Int32(count))
                        }
                    var compileOptions = json_schema_compile_options_t(
                        indent: indent,
                        any_whitespace: anyWhitespace,
                        strict_mode: format.strict ? 1 : 0,
                        max_whitespace_cnt: -1,
                        has_separators: 0,
                        separators: .init()
                    )
                    return grammar_compiler_compile_json_schema(
                        pointer,
                        schemaBuffer.baseAddress,
                        schemaBuffer.count - 1,
                        &compileOptions
                    )
                }
            case .structural(let tag):
                return tag.utf8CString.withUnsafeBufferPointer {
                    grammar_compiler_compile_structural_tag(pointer, $0.baseAddress, $0.count - 1)
                }
            }
        }

        guard let compiledGrammar else {
            throw XGrammarError.invalidGrammar(CErrorHandler.lastErrorMessage)
        }

        return CompiledGrammar(pointer: compiledGrammar)
    }
}
