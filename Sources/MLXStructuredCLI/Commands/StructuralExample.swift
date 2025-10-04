//
//  StructuralExample.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import Foundation
import ArgumentParser
import MLXStructured
import MLXLMCommon

struct StructuralExample: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "structural",
        abstract: "Generate text according to complex structural grammar."
    )
    
    @OptionGroup
    var model: ModelArguments
    
    func run() async throws {
        let context = try await model.modelContext()
        let includePrefix = Bool.random()
        let grammar = try Grammar {
            SequenceFormat {
                if includePrefix {
                    ConstTextFormat(text: "According to my knowledge, my answer is ")
                }
                OrFormat {
                    ConstTextFormat(text: "YES")
                    ConstTextFormat(text: "NO")
                }
            }
        }
        let prompt = "Is it true that London is a capital of a Great Britain?"
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
        let result = try await MLXStructured.generate(input: input, context: context, grammar: grammar)
        print("Generation result:", result.output)
    }
}
