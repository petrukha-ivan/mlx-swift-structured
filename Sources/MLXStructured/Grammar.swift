//
//  Grammar.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 16.09.2025.
//

import Foundation
import JSONSchema

public enum Grammar {
    case ebnf(String)
    case regex(String)
    case schema(String)
}

public extension Grammar {
    static func schema(_ schema: JSONSchema = .object()) throws -> Grammar {
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let string = String(decoding: data, as: UTF8.self)
        return .schema(string)
    }
}

public extension Grammar {
    
    var raw: String {
        switch self {
        case .ebnf(let ebnf):
            return ebnf
        case .regex(let regex):
            return regex
        case .schema(let schema):
            return schema
        }
    }
    
    var guidance: String? {
        switch self {
        case .ebnf:
            return nil
        case .regex(let regex):
            return "Output is regex constrained: \(regex)"
        case .schema(let schema):
            return "Output is JSON schema constrained: \(schema)"
        }
    }
}
