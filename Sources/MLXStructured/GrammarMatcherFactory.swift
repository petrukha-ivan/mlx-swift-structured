//
//  GrammarMatcherFactory.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 20.09.2025.
//

import MLXLMCommon
import Hub

extension GrammarMaskedLogitProcessor {

    private static let cache = Cache<ModelConfiguration, GrammarCompiler>()

    public static func from(
        hub: HubApi = .shared,
        configuration: ModelConfiguration,
        grammar: Grammar
    ) async throws -> GrammarMaskedLogitProcessor {
        let compiler: GrammarCompiler
        if let cached = await cache.value(for: configuration) {
            compiler = cached
        } else {
            let tokenizerInfo = try await TokenizerInfo.from(hub: hub, configuration: configuration)
            compiler = try GrammarCompiler(tokenizerInfo: tokenizerInfo)
            await cache.set(compiler, for: configuration)
        }

        let compiledGrammar = try compiler.compile(grammar: grammar)
        let grammarMatcher = try XGrammar(compiledGrammar: compiledGrammar)
        let processor = GrammarMaskedLogitProcessor(grammarMatcher: grammarMatcher)
        return processor
    }
}

extension ModelConfiguration: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(tokenizerSource)
        hasher.combine(defaultPrompt)
        hasher.combine(extraEOSTokens)
        hasher.combine(eosTokenIds)
        hasher.combine(toolCallFormat)
    }
}

extension ModelConfiguration.Identifier: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .id(let id, let revision):
            hasher.combine(0)
            hasher.combine(id)
            hasher.combine(revision)
        case .directory(let directory):
            hasher.combine(1)
            hasher.combine(directory.path)
        }
    }
}

extension TokenizerSource: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .id(let id, let revision):
            hasher.combine(0)
            hasher.combine(id)
            hasher.combine(revision)
        case .directory(let directory):
            hasher.combine(1)
            hasher.combine(directory.path)
        }
    }
}
