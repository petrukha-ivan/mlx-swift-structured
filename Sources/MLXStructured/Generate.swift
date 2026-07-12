//
//  Generate.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 27.09.2025.
//

import Foundation
import JSONSchema
import MLXLMCommon

/// Generates text constrained by an EBNF grammar.
///
/// Use this when you already have an EBNF grammar string and want to stream
/// constrained generation results.
///
/// ```swift
/// let input = try await context.processor.prepare(
///     input: UserInput(prompt: "Answer only YES or NO: Is Swift a programming language?")
/// )
///
/// let stream = try await generate(
///     input: input,
///     context: context,
///     ebnf: #"root ::= ("YES" | "NO")"#
/// )
/// ```
///
/// - Parameters:
///   - input: language model input.
///   - cache: optional KV cache to continue generation from a previous state.
///   - parameters: configuration options for token generation.
///   - context: model context containing the model, tokenizer, and configuration.
///   - ebnf: grammar in Extended Backus-Naur Form.
/// - Returns: an async stream of constrained generation updates.
public func generate(
    input: LMInput,
    cache: [KVCache]? = nil,
    parameters: GenerateParameters = GenerateParameters(),
    context: ModelContext,
    ebnf: String,
) async throws -> AsyncStream<Generation> {
    let grammar = Grammar.ebnf(ebnf)
    return try await generate(
        input: input,
        cache: cache,
        parameters: parameters,
        context: context,
        grammar: grammar
    )
}

/// Generates text constrained by a regular expression.
///
/// ```swift
/// let input = try await context.processor.prepare(
///     input: UserInput(prompt: "Return a support email address.")
/// )
///
/// let stream = try await generate(
///     input: input,
///     context: context,
///     regex: #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
/// )
/// ```
///
/// - Parameters:
///   - input: language model input.
///   - cache: optional KV cache to continue generation from a previous state.
///   - parameters: configuration options for token generation.
///   - context: model context containing the model, tokenizer, and configuration.
///   - regex: regular expression describing valid output.
/// - Returns: an async stream of constrained generation updates.
public func generate(
    input: LMInput,
    cache: [KVCache]? = nil,
    parameters: GenerateParameters = GenerateParameters(),
    context: ModelContext,
    regex: String,
) async throws -> AsyncStream<Generation> {
    let grammar = Grammar.regex(regex)
    return try await generate(
        input: input,
        cache: cache,
        parameters: parameters,
        context: context,
        grammar: grammar
    )
}

/// Generates JSON text constrained by a JSON schema.
///
/// ```swift
/// let schema: JSONSchema = .object(
///     description: "Movie record",
///     properties: [
///         "title": .string(),
///         "year": .integer(minimum: 1900, maximum: 2026),
///         "director": .string()
///     ],
///     required: [
///         "title",
///         "year",
///         "director"
///     ]
/// )
///
/// let input = try await context.processor.prepare(
///     input: UserInput(
///         prompt: "Extract a movie record from: The Dark Knight (2008) was directed by Christopher Nolan."
///     )
/// )
///
/// let stream = try await generate(
///     input: input,
///     context: context,
///     schema: schema
/// )
/// ```
///
/// - Parameters:
///   - input: language model input.
///   - cache: optional KV cache to continue generation from a previous state.
///   - parameters: configuration options for token generation.
///   - context: model context containing the model, tokenizer, and configuration.
///   - schema: JSON schema that defines the allowed output structure.
///   - options: formatting options used when converting the schema to a grammar.
/// - Returns: an async stream of constrained generation updates.
public func generate(
    input: LMInput,
    cache: [KVCache]? = nil,
    parameters: GenerateParameters = .init(),
    context: ModelContext,
    schema: JSONSchema,
    options: JSONSchemaFormatOptions = .init(),
) async throws -> AsyncStream<Generation> {
    let grammar = try Grammar.schema(schema, options: options)
    return try await generate(
        input: input,
        cache: cache,
        parameters: parameters,
        context: context,
        grammar: grammar
    )
}

/// Generates JSON constrained by a schema and decodes it into a value.
///
/// ```swift
/// struct MovieRecord: Decodable {
///     let title: String
///     let year: Int
///     let director: String
/// }
///
/// let schema: JSONSchema = .object(
///     description: "Movie record",
///     properties: [
///         "title": .string(),
///         "year": .integer(minimum: 1900, maximum: 2026),
///         "director": .string()
///     ],
///     required: [
///         "title",
///         "year",
///         "director"
///     ]
/// )
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
///     schema: schema,
///     generating: MovieRecord.self
/// )
/// ```
///
/// - Parameters:
///   - input: language model input.
///   - cache: optional KV cache to continue generation from a previous state.
///   - parameters: configuration options for token generation.
///   - context: model context containing the model, tokenizer, and configuration.
///   - schema: JSON schema that defines the allowed output structure.
///   - options: formatting options used when converting the schema to a grammar.
///   - generating: decoded result type.
///   - decoder: decoder used to convert the generated JSON into `Content`.
/// - Returns: the decoded generated value.
public func generate<Content: Decodable>(
    input: LMInput,
    cache: [KVCache]? = nil,
    parameters: GenerateParameters = .init(),
    context: ModelContext,
    schema: JSONSchema,
    options: JSONSchemaFormatOptions = .init(),
    generating: Content.Type,
    decoder: JSONDecoder = .init()
) async throws -> Content {
    let grammar = try Grammar.schema(schema, options: options)
    let stream = try await generate(
        input: input,
        cache: cache,
        parameters: parameters,
        context: context,
        grammar: grammar
    )

    let output = await stream.compactMap(\.chunk).reduce("", +)
    let content = try decoder.decode(Content.self, from: Data(output.utf8))
    return content
}

/// Generates text constrained by a prebuilt grammar.
///
/// This is the lowest-level generation entry point and is useful when the
/// grammar has already been prepared by the caller.
///
/// - Parameters:
///   - input: language model input.
///   - cache: optional KV cache to continue generation from a previous state.
///   - parameters: configuration options for token generation.
///   - context: model context containing the model, tokenizer, and configuration.
///   - grammar: prepared grammar used to mask invalid tokens during sampling.
/// - Returns: an async stream of constrained generation updates.
public func generate(
    input: LMInput,
    cache: [KVCache]? = nil,
    parameters: GenerateParameters = .init(),
    context: ModelContext,
    grammar: Grammar,
) async throws -> AsyncStream<Generation> {
    let processor = try await GrammarMaskedLogitProcessor.from(
        configuration: context.configuration,
        grammar: grammar
    )

    let iterator = try GrammarConstrainedTokenIterator(
        input: input,
        model: context.model,
        cache: cache,
        grammarMatcher: processor.grammarMatcher,
        parameters: parameters
    )

    let (stream, _) = generateTask(
        promptTokenCount: input.text.tokens.size,
        modelConfiguration: context.configuration,
        tokenizer: context.tokenizer,
        iterator: iterator
    )

    return stream
}
