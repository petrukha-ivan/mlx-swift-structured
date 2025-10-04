//
//  StructuralTag+Builder.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 25.09.2025.
//

@resultBuilder
public enum FormatBuilder {
    
    public static func buildExpression(_ expression: Encodable) -> Encodable {
        expression
    }
    
    public static func buildBlock(_ component: Encodable) -> Encodable {
        component
    }
    
    public static func buildOptional(_ component: Encodable?) -> Encodable {
        component ?? AnyTextFormat()
    }
    
    public static func buildEither(first component: Encodable) -> Encodable {
        component
    }
    
    public static func buildEither(second component: Encodable) -> Encodable {
        component
    }
    
    public static func buildLimitedAvailability(_ component: Encodable) -> Encodable {
        component
    }
}

@resultBuilder
public enum FormatListBuilder {
    
    public static func buildExpression(_ expression: Encodable) -> [Encodable] {
        [expression]
    }
    
    public static func buildBlock(_ components: [Encodable]...) -> [Encodable] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [Encodable]?) -> [Encodable] {
        component ?? []
    }
    
    public static func buildEither(first component: [Encodable]) -> [Encodable] {
        component
    }
    
    public static func buildEither(second component: [Encodable]) -> [Encodable] {
        component
    }
    
    public static func buildArray(_ components: [[Encodable]]) -> [Encodable] {
        components.flatMap { $0 }
    }
    
    public static func buildLimitedAvailability(_ component: [Encodable]) -> [Encodable] {
        component
    }
}

@resultBuilder
public enum TagListBuilder {
    
    public static func buildExpression(_ expression: TagFormat) -> [TagFormat] {
        [expression]
    }
    
    public static func buildBlock(_ components: [TagFormat]...) -> [TagFormat] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [TagFormat]?) -> [TagFormat] {
        component ?? []
    }
    
    public static func buildEither(first component: [TagFormat]) -> [TagFormat] {
        component
    }
    
    public static func buildEither(second component: [TagFormat]) -> [TagFormat] {
        component
    }
    
    public static func buildArray(_ components: [[TagFormat]]) -> [TagFormat] {
        components.flatMap { $0 }
    }
    
    public static func buildLimitedAvailability(_ component: [TagFormat]) -> [TagFormat] {
        component
    }
}

public extension StructuralTag {
    init(@FormatBuilder _ content: () -> Encodable) {
        self.init(format: content())
    }
}

public extension SequenceFormat {
    init(@FormatListBuilder _ content: () -> [Encodable]) {
        self.init(elements: content())
    }
}

public extension OrFormat {
    init(@FormatListBuilder _ content: () -> [Encodable]) {
        self.init(elements: content())
    }
}

public extension TagFormat {
    init(begin: String, end: String, @FormatBuilder _ content: () -> Encodable) {
        self.init(begin: begin, content: content(), end: end)
    }
}

public extension TriggeredTagsFormat {
    init(triggers: [String], options: Options = [], @TagListBuilder _ content: () -> [TagFormat]) {
        self.init(triggers: triggers, tags: content(), options: options)
    }
}


public extension OrFormat {
    mutating func appending(_ formats: [Encodable]) -> OrFormat {
        OrFormat(elements: self.elements + formats)
    }
}

public extension SequenceFormat {
    mutating func appending(_ formats: [Encodable]) -> SequenceFormat {
        SequenceFormat(elements: self.elements + formats)
    }
}
