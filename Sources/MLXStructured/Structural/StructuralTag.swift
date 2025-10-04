//
//  StructuralTag.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 24.09.2025.
//

import Foundation
import JSONSchema

public struct AnyEncodable: Encodable {
    
    private let _encode: (Encoder) throws -> Void
    
    public init<E: Encodable>(_ value: E) {
        _encode = value.encode
    }
    
    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

public struct StructuralTag: Encodable {
    
    public let format: AnyEncodable
    
    public init(format: Encodable) {
        self.format = AnyEncodable(format)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("structural_tag", forKey: .type)
        try container.encode(format, forKey: .format)
    }
    
    enum CodingKeys: CodingKey {
        case type
        case format
    }
}

public struct SequenceFormat: Encodable {
    
    public let elements: [AnyEncodable]
    
    public init(elements: [Encodable]) {
        self.elements = elements.map { AnyEncodable($0) }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("sequence", forKey: .type)
        try container.encode(elements, forKey: .elements)
    }
    
    enum CodingKeys: CodingKey {
        case type
        case elements
    }
}

public struct OrFormat: Encodable {
    
    public let elements: [AnyEncodable]
    
    public init(elements: [Encodable]) {
        self.elements = elements.map { AnyEncodable($0) }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("or", forKey: .type)
        try container.encode(elements, forKey: .elements)
    }
    
    enum CodingKeys: CodingKey {
        case type
        case elements
    }
}

public struct AnyTextFormat: Encodable {
    
    public init() {}
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("any_text", forKey: .type)
    }
    
    enum CodingKeys: CodingKey {
        case type
    }
}

public struct ConstTextFormat: Encodable {
    
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("const_string", forKey: .type)
        try container.encode(text, forKey: .text)
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case text = "value"
    }
}

public struct GrammarFormat: Encodable {
    
    public let grammar: String
    
    public init(grammar: String) {
        self.grammar = grammar
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("grammar", forKey: .type)
        try container.encode(grammar, forKey: .grammar)
    }
    
    enum CodingKeys: CodingKey {
        case type
        case grammar
    }
}

public struct RegexFormat: Encodable {
    
    public let pattern: String
    
    public init(pattern: String) {
        self.pattern = pattern
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("regex", forKey: .type)
        try container.encode(pattern, forKey: .pattern)
    }
    
    enum CodingKeys: CodingKey {
        case type
        case pattern
    }
}

public struct JSONSchemaFormat: Encodable {
    
    public let schema: JSONSchema
    
    public init(schema: JSONSchema) {
        self.schema = schema
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("json_schema", forKey: .type)
        try container.encode(schema, forKey: .schema)
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case schema = "json_schema"
    }
}

public struct TriggeredTagsFormat: Encodable {
    
    public struct Options: RawRepresentable, OptionSet, Sendable {
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let atLeastOne = Options(rawValue: 1 << 0)
        public static let stopAfterFirst = Options(rawValue: 1 << 1)
    }
    
    public let triggers: [String]
    public let tags: [TagFormat]
    public let options: Options
    
    public init(triggers: [String], tags: [TagFormat], options: Options = []) {
        self.triggers = triggers
        self.tags = tags
        self.options = options
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("triggered_tags", forKey: .type)
        try container.encode(triggers, forKey: .triggers)
        try container.encode(tags, forKey: .tags)
        try container.encode(options.contains(.atLeastOne), forKey: .atLeastOne)
        try container.encode(options.contains(.stopAfterFirst), forKey: .stopAfterFirst)
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case triggers
        case tags
        case atLeastOne = "at_least_one"
        case stopAfterFirst = "stop_after_first"
    }
}

public struct TagFormat: Encodable {
    
    public let begin: String
    public let content: AnyEncodable
    public let end: String
    
    public init(begin: String, content: Encodable, end: String) {
        self.begin = begin
        self.content = AnyEncodable(content)
        self.end = end
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container  = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("tag", forKey: .type)
        try container.encode(begin, forKey: .begin)
        try container.encode(content, forKey: .content)
        try container.encode(end, forKey: .end)
    }
    
    enum CodingKeys: CodingKey {
        case type
        case begin
        case content
        case end
    }
}
