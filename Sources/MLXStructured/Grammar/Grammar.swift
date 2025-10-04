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
    case schema(String, indent: Int? = nil)
    case structural(String)
}

public extension Grammar {
    
    @available(*, deprecated, message: "Prefer constructing prompt manually, this property will be removed in the future versions")
    var raw: String {
        switch self {
        case .ebnf(let ebnf):
            return ebnf
        case .regex(let regex):
            return regex
        case .schema(let schema, _):
            return schema
        case .structural(let tag):
            return tag
        }
    }
    
    @available(*, deprecated, message: "Prefer constructing prompt manually, this property will be removed in the future versions")
    var guidance: String? {
        switch self {
        case .ebnf:
            return nil
        case .regex(let regex):
            return "Output is regex constrained: \(regex)"
        case .schema(let schema, _):
            return "Output is JSON schema constrained: \(schema)"
        case .structural:
            return nil
        }
    }
}
