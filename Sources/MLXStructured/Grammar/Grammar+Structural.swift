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
        let encoder = JSONEncoder()
        let data = try encoder.encode(tag)
        let string = String(decoding: data, as: UTF8.self)
        self = Grammar.structural(string)
    }
}
