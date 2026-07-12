//
//  UnsafeBox.swift
//  mlx-swift-structured
//
//  Created by Ivan Petrukha on 16.05.2026.
//

import Foundation

class UnsafeBox<Value>: @unchecked Sendable {

    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}
