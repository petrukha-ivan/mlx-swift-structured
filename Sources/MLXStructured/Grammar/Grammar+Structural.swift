//
//  Grammar+Structural.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 27.09.2025.
//

import Foundation

public extension Grammar {
    init(@FormatBuilder _ content: () -> Encodable) throws {
        let tag = StructuralTag(format: content())
        let data = try JSONEncoder.sorted.encode(tag)
        let string = String(decoding: data, as: UTF8.self).sanitizedSchema
        self = Grammar.structural(string)
    }
}
