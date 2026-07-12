//
//  Generate+Generable.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 28.03.2026.
//

#if canImport(FoundationModels)
    import Foundation
    import FoundationModels
    import AsyncAlgorithms
    import MLXLMCommon

    @available(macOS 26.0, iOS 26.0, *)
    /// Generates a Foundation Models `Generable` value.
    ///
    /// Use this overload to produce a fully validated structured value from a
    /// type that conforms to `Generable`.
    ///
    /// ```swift
    /// @Generable
    /// struct MovieRecord {
    ///
    ///     @Guide(description: "Movie title")
    ///     let title: String
    ///
    ///     @Guide(description: "Release year")
    ///     let year: Int
    ///
    ///     @Guide(description: "Director name")
    ///     let director: String
    /// }
    ///
    /// let input = try await context.processor.prepare(
    ///     input: UserInput(
    ///         prompt: "Extract a movie record from: The Dark Knight (2008) was directed by Christopher Nolan."
    ///     )
    /// )
    ///
    /// let movie = try await generate(
    ///     input: input,
    ///     context: context,
    ///     generating: MovieRecord.self
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - input: language model input.
    ///   - cache: optional KV cache to continue generation from a previous state.
    ///   - parameters: configuration options for token generation.
    ///   - options: constrained generation options.
    ///   - context: model context containing the model, tokenizer, and configuration.
    ///   - generating: `Generable` type to produce.
    /// - Returns: the generated structured value.
    public func generate<Content: Generable>(
        input: LMInput,
        cache: [KVCache]? = nil,
        parameters: GenerateParameters = GenerateParameters(),
        options: ConstrainedGenerationOptions = [],
        context: ModelContext,
        generating: Content.Type
    ) async throws -> Content {
        let grammar = try Grammar.generable(Content.self)
        let stream = try await generate(
            input: input,
            cache: cache,
            parameters: parameters,
            options: options,
            context: context,
            grammar: grammar
        )

        let output = await stream.compactMap(\.chunk).reduce("", +)
        let generatedContent = try GeneratedContent(json: output)
        let content = try Content(generatedContent)
        return content
    }

    @available(macOS 26.0, iOS 26.0, *)
    /// Generates partial updates for a Foundation Models `Generable` value.
    ///
    /// This is useful for progressively rendering structured output while the
    /// model is still generating.
    ///
    /// ```swift
    /// @Generable
    /// struct EmailAddress {
    ///     @Guide(description: "A valid email address")
    ///     let email: String
    /// }
    ///
    /// let input = try await context.processor.prepare(
    ///     input: UserInput(prompt: "Return a support email address.")
    /// )
    ///
    /// let stream = try await generate(
    ///     input: input,
    ///     context: context,
    ///     partially: EmailAddress.self
    /// )
    ///
    /// for try await partial in stream {
    ///     print(partial)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - input: language model input.
    ///   - cache: optional KV cache to continue generation from a previous state.
    ///   - parameters: configuration options for token generation.
    ///   - options: constrained generation options.
    ///   - context: model context containing the model, tokenizer, and configuration.
    ///   - partially: `Generable` type whose partial representation should be streamed.
    /// - Returns: an async sequence of partial structured updates.
    public func generate<Content: Generable>(
        input: LMInput,
        cache: [KVCache]? = nil,
        parameters: GenerateParameters = GenerateParameters(),
        options: ConstrainedGenerationOptions = [],
        context: ModelContext,
        partially: Content.Type
    ) async throws -> some AsyncSequence<Content.PartiallyGenerated, any Error> {
        let grammar = try Grammar.generable(Content.self)
        let stream = try await generate(
            input: input,
            cache: cache,
            parameters: parameters,
            options: options,
            context: context,
            grammar: grammar
        )

        return stream.compactMap(\.chunk).reductions("", +).map {
            let generatedContent = try GeneratedContent(json: $0)
            let partiallyGenerated = try Content.PartiallyGenerated(generatedContent)
            return partiallyGenerated
        }
    }
#endif
