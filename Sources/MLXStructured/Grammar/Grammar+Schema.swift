//
//  Grammar+Schema.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import Foundation
import JSONSchema

public extension Grammar {

    static func schema(_ schema: JSONSchema = .object(), indent: Int) throws -> Grammar {
        try Grammar.schema(schema, options: JSONSchemaFormatOptions(whitespace: .indent(indent)))
    }

    static func schema(_ schema: JSONSchema = .object(), options: JSONSchemaFormatOptions = .init()) throws -> Grammar {
        let data = try JSONEncoder.sorted.encode(schema)
        let string = String(decoding: data, as: UTF8.self).sanitizedSchema
        return .schema(string, options: options)
    }
}

public struct JSONSchemaFormatOptions: Sendable, Equatable {

    public enum Whitespace: Sendable, Equatable {
        case none
        case any
        case indent(Int)
    }

    public let strict: Bool
    public let whitespace: Whitespace

    public init(
        strict: Bool = true,
        whitespace: Whitespace = .any
    ) {
        self.strict = strict
        self.whitespace = whitespace
    }
}
