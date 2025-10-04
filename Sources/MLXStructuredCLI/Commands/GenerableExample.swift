//
//  GenerableExample.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import Foundation
import FoundationModels
import ArgumentParser
import MLXStructured
import MLXLMCommon

@Generable
@available(macOS 26.0, iOS 26.0, *)
private struct MovieRecord: Codable {
    
    @Guide(description: "Movie title")
    let title: String

    @Guide(description: "Release year", .range(1900...2026))
    let year: Int

    @Guide(description: "List of genres", .count(1...3))
    let genres: [String]

    @Guide(description: "Director name")
    let director: String

    @Guide(description: "List of principal actors", .count(1...5))
    let actors: [String]
}

@available(macOS 26.0, iOS 26.0, *)
private extension MovieRecord {
    
    static let instruction = """
    Instruction: Extract movie record from the text according to schema: \(MovieRecord.generationSchema)
    """
    
    static let sample = """
    Text: The Dark Knight (2008) is a superhero crime film directed by Christopher Nolan. Starring Christian Bale, Heath Ledger, and Michael Caine.
    """
}

struct GenerableExample: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "generable",
        abstract: "Generate @Generable type."
    )
    
    @OptionGroup
    var model: ModelArguments
    
    func run() async throws {
        guard #available(macOS 26.0, iOS 26.0, *) else {
            fatalError("Generable examples available from macOS 26 only")
        }
        
        let context = try await model.modelContext()
        let prompt = MovieRecord.instruction + "\n" + MovieRecord.sample
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
        let (result, model) = try await MLXStructured.generate(input: input, context: context, generating: MovieRecord.self)
        print("Generation result:", result.output)
        print("Generated model:", model)
    }
}

struct GenerableStreamExample: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "generable-stream",
        abstract: "Generate @Generable type using stream and partially generated content."
    )
    
    @OptionGroup
    var model: ModelArguments
    
    func run() async throws {
        guard #available(macOS 26.0, iOS 26.0, *) else {
            fatalError("Generable examples available from macOS 26 only")
        }
        
        let context = try await model.modelContext()
        let prompt = MovieRecord.instruction + "\n" + MovieRecord.sample
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
        let stream = try await MLXStructured.generate(input: input, context: context, generating: MovieRecord.self)
        for await content in stream {
            print("Partially generated:", content)
        }
    }
}
