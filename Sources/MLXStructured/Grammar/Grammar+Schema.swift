//
//  Grammar+Schema.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 04.10.2025.
//

import Foundation
import JSONSchema

public extension Grammar {
    static func schema(_ schema: JSONSchema = .object(), indent: Int? = nil) throws -> Grammar {
        let data = try JSONEncoder.sorted.encode(schema)
        let string = String(decoding: data, as: UTF8.self).sanitizedSchema
        return .schema(string, indent: indent)
    }
}
