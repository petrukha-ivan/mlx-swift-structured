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
    case schema(String, format: JSONSchemaFormatOptions = .init())
    case structural(String)
}
