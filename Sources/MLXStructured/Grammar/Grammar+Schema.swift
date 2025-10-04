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
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let string = String(decoding: data, as: UTF8.self)
        return .schema(string, indent: indent)
    }
}
