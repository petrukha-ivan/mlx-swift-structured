//
//  CodableExample.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import Foundation
import ArgumentParser
import JSONSchema
import MLXStructured
import MLXLMCommon

private struct MovieRecord: Codable {
    let title: String
    let year: Int
    let genres: [String]
    let director: String
    let actors: [String]
}

private extension MovieRecord {
    
    static let instruction = """
    Instruction: Extract movie record from the text according to schema: \(schema)
    """
    
    static let sample = """
    Text: The Dark Knight (2008) is a superhero crime film directed by Christopher Nolan. Starring Christian Bale, Heath Ledger, and Michael Caine.
    """
    
    static let schema = JSONSchema.object(
        description: "Movie record",
        properties: [
            "title": .string(),
            "year": .integer(minimum: 1900, maximum: 2026),
            "genres": .array(items: .string(), maxItems: 3),
            "director": .string(),
            "actors": .array(items: .string(), maxItems: 5)
        ], required: [
            "title",
            "year",
            "genres",
            "director",
            "actors"
        ]
    )
}

struct CodableExample: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "codable",
        abstract: "Generate codable content according to JSON Schema."
    )
    
    @OptionGroup
    var model: ModelArguments
    
    func run() async throws {
        let context = try await model.modelContext()
        let prompt = MovieRecord.instruction + "\n" + MovieRecord.sample
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
        let (result, model) = try await MLXStructured.generate(input: input, context: context, schema: MovieRecord.schema, generating: MovieRecord.self, indent: 2)
        print("Generation result:", result.output)
        print("Generated model:", model)
    }
}
