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

    /// Builds a logit processor that masks tokens to satisfy `grammar`.
    ///
    /// - Parameter maxThreads: Number of threads xgrammar's `GrammarCompiler`
    ///   will use when compiling new grammars. xgrammar gates its internal
    ///   ThreadPool + mutex behind a special-case bypass for `max_threads = 1`
    ///   (see xgrammar PR #75). Some JSON schemas have been observed to
    ///   deadlock the threaded compile path on Apple Silicon; passing `1`
    ///   sidesteps this entirely. Compile is one-shot per grammar per
    ///   configuration, so the perf cost of single-threaded compile is
    ///   negligible. The default keeps xgrammar's published default (`8`)
    ///   for non-affected callers; consumers seeing hangs should pass `1`.
    public static func from(
        hub: HubApi = .shared,
        configuration: ModelConfiguration,
        grammar: Grammar,
        maxThreads: Int32 = 8
    ) async throws -> GrammarMaskedLogitProcessor {
        let compiler: GrammarCompiler
        if let cached = await cache.value(for: configuration) {
            // Note: cache key is `configuration` only — the FIRST call's
            // `maxThreads` value wins for the configuration's lifetime.
            compiler = cached
        } else {
            let tokenizerInfo = try await TokenizerInfo.from(hub: hub, configuration: configuration)
            compiler = try GrammarCompiler(tokenizerInfo: tokenizerInfo, maxThreads: maxThreads)
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
        // mlx-swift-lm 3.x replaced `tokenizerId` and `overrideTokenizer`
        // with the unified `tokenizerSource: TokenizerSource?`. TokenizerSource
        // is `Equatable` but not `Hashable`, so hash its cases manually.
        if let tokenizerSource {
            switch tokenizerSource {
            case .id(let id, let revision):
                hasher.combine(0)
                hasher.combine(id)
                hasher.combine(revision)
            case .directory(let directory):
                hasher.combine(1)
                hasher.combine(directory.path)
            }
        } else {
            hasher.combine(2)
        }
        hasher.combine(defaultPrompt)
        hasher.combine(extraEOSTokens)
        hasher.combine(eosTokenIds)
        hasher.combine(toolCallFormat?.rawValue)
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
