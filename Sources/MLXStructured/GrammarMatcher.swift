//
//  GrammarMatcher.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 16.09.2025.
//

import MLX

public protocol GrammarMatcher {
    func isTerminated() -> Bool
    func nextTokenMask() -> MLXArray  // 0 or -infinity
    func findJumpForwardString() -> String
    func accept(token: MLXArray)
    func accept(string: String)
    func reset()
}
