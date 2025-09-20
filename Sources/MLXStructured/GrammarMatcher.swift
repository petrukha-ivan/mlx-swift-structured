//
//  GrammarMatcher.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 16.09.2025.
//

import MLX

public protocol GrammarMatcher {
    func nextTokenMask() -> MLXArray // 0 or -infinity
    func advance(token: MLXArray)
    func reset()
}
