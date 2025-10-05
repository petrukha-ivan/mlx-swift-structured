//
//  Grammar+Encoding.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 05.10.2025.
//

import Foundation
import JSONSchema

extension JSONEncoder {
    
    static let `default` = JSONEncoder()
    
    static let sorted: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return encoder
    }()
}

extension JSONDecoder {
    
    static let `default` = JSONDecoder()
    
    static func withPropertiesOrderInfo(_ order: [String]) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[JSONSchema.ObjectSchema.Properties.orderInfoKey] = order
        return decoder
    }
}

extension JSONSchema: @retroactive CustomStringConvertible {
    public var description: String {
        do {
            let data = try JSONEncoder.sorted.encode(self)
            let string = String(decoding: data, as: UTF8.self).sanitizedSchema
            return string
        } catch {
            return "Invalid JSON Schema"
        }
    }
}

extension String {
    var sanitizedSchema: String {
        replacingOccurrences(of: "__[0-9]+__", with: "", options: .regularExpression)
    }
}
