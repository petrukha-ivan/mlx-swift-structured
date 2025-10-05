//
//  Grammar+Generable.swift
//  MLXStructured
//
//  Created by Rudrank Riyam on 21.09.2025.
//

import Foundation
import JSONSchema

#if canImport(FoundationModels)
import FoundationModels
#endif

#if compiler(>=6.2)
@available(macOS 26.0, iOS 26.0, *)
public extension Grammar {
    
    struct OrderContainer: Codable {
        
        let order: [String]
        
        enum CodingKeys: String, CodingKey {
            case order = "x-order"
        }
    }
    
    static func generable<Content: Generable>(_ type: Content.Type, indent: Int? = nil) throws -> Grammar {
        let generationSchemaData = try JSONEncoder.default.encode(type.generationSchema)
        let orderContainer = try JSONDecoder.default.decode(OrderContainer.self, from: generationSchemaData)
        let schema = try JSONDecoder.withPropertiesOrderInfo(orderContainer.order).decode(JSONSchema.self, from: generationSchemaData)
        let schemaData = try JSONEncoder.sorted.encode(schema)
        let string = String(decoding: schemaData, as: UTF8.self).sanitizedSchema
        return .schema(string, indent: indent)
    }
}
#endif
