//
//  Grammar+Generable.swift
//  MLXStructured
//
//  Created by Codex on 22.02.2026.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

#if compiler(>=6.2)
@available(macOS 26.0, iOS 26.0, *)
public extension Grammar {
    static func schema<Content: Generable>(generable type: Content.Type) throws -> Grammar {
        let encoder = JSONEncoder()
        let data = try encoder.encode(type.generationSchema)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                type,
                EncodingError.Context(codingPath: [], debugDescription: "Failed to encode generation schema using UTF-8.")
            )
        }
        return .schema(string)
    }
}
#endif