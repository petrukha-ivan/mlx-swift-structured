//
//  ToolCallingExample.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import Foundation
import ArgumentParser
import JSONSchema
import MLXStructured
import MLXLMCommon

private struct Tool: Encodable {
    let name: String
    let description: String
    let parameters: JSONSchema
}

private extension Tool {
    var schema: [String: Any] {
        return [
            "type": "function",
            "function": [
                "name": name,
                "description": description,
                "parameters": try! JSONSerialization.jsonObject(with: JSONEncoder().encode(parameters))
            ]
        ]
    }
}

private let getCurrentTimeTool = Tool(
    name: "get_current_time",
    description: "Gets current time at specified city.",
    parameters: .object(
        properties: [
            "city": .string(),
        ],
        required: [
            "city",
        ]
    )
)

private let getCurrentWeatherTool = Tool(
    name: "get_current_weather",
    description: "Gets the current weather for the specified city.",
    parameters: .object(
        properties: [
            "city": .string(),
            "unit": .enum(values: [.string("celsius"), .string("fahrenheit")])
        ],
        required: [
            "city",
        ]
    )
)

struct ToolCallingExample: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "tool-calling",
        abstract: "Generate tool calls according to complex structural grammar."
    )
    
    @OptionGroup
    var model: ModelArguments
    
    func run() async throws {
        let context = try await model.modelContext()
        let tools = [getCurrentTimeTool, getCurrentWeatherTool]
        let forceThinking = Bool.random()
        let grammar = try Grammar {
            SequenceFormat {
                if forceThinking {
                    TagFormat(begin: "<think>", end: "</think>") {
                        AnyTextFormat()
                    }
                }
                TriggeredTagsFormat(triggers: ["<tool_call>"], options: [.atLeastOne, .stopAfterFirst]) {
                    for tool in tools {
                        TagFormat(begin: "<tool_call>\n{\"name\": \"\(tool.name)\", \"arguments\": ", end: "}\n</tool_call>") {
                            JSONSchemaFormat(schema: tool.parameters)
                        }
                    }
                }
            }
        }
        let prompt = "Check the weather in Paris."
        let input = try await context.processor.prepare(input: UserInput(prompt: prompt, tools: tools.map(\.schema)))
        let result = try await MLXStructured.generate(input: input, context: context, grammar: grammar)
        print("Generation result:", result.output)
    }
}
