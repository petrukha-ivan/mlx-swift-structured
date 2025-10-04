//
//  RootCommand.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import ArgumentParser
import MLXLMCommon
import MLXLLM
import Hub

@main
struct RootCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "mlx-structured",
        abstract: "Examples of different structured output generation.",
        subcommands: [
            CodableExample.self,
            GenerableExample.self,
            GenerableStreamExample.self,
            StructuralExample.self,
            ToolCallingExample.self
        ]
    )
}

struct ModelArguments: ParsableArguments {
    
    @Option
    var id: String = "Qwen/Qwen3-1.7B-MLX-4bit"
    
    @Option
    var revision: String = "main"
    
    func modelContext() async throws -> ModelContext {
        let hub = HubApi(useOfflineMode: false)
        let configuration = ModelConfiguration(id: id, revision: revision, extraEOSTokens: ["<end_of_turn>", "<|end|>"])
        return try await LLMModelFactory.shared.load(hub: hub, configuration: configuration) { progress in
            print("Loading model: \(progress.fractionCompleted.formatted(.percent))")
        }
    }
}
