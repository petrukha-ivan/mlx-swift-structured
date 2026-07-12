//
//  XGrammar.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 14.09.2025.
//

import Foundation
import CMLXStructured
import MLX

enum XGrammarError: Error {
    case emptyGrammar
    case invalidGrammar(String)
    case invalidVocab(String)
    case unknown(String)
}

final class XGrammar {

    private let vocabSize: Int
    private let bufferSize: Int
    private let bitmap: MLXArray
    private var bitmask: DLTensor
    private let grammarMatcher: UnsafeMutableRawPointer?

    init(compiledGrammar: CompiledGrammar) throws {
        guard let grammarMatcher = withCErrorHandling({ grammar_matcher_new(compiledGrammar.pointer) }) else {
            throw XGrammarError.unknown(CErrorHandler.lastErrorMessage)
        }

        var bitmap = [Float](repeating: 0, count: 256 * 8)
        for b in 0..<256 {
            for k in 0..<8 {
                bitmap[b * 8 + k] = ((b >> k) & 1) == 1 ? 0 : -Float.infinity
            }
        }

        self.vocabSize = compiledGrammar.vocabSize
        self.bufferSize = (vocabSize + 31) / 32
        self.bitmap = MLXArray(bitmap).reshaped([256, 8])
        self.bitmask = DLTensor.nextTokenBitmask(bufferSize: bufferSize)
        self.grammarMatcher = grammarMatcher
    }

    deinit {
        bitmask.data?.deallocate()
        bitmask.shape?.deallocate()
        bitmask.strides?.deallocate()
        grammar_matcher_free(grammarMatcher)
    }
}

extension XGrammar: GrammarMatcher {

    func nextTokenMask() -> MLXArray {
        guard
            withUnsafeMutablePointer(
                to: &bitmask,
                {
                    grammar_matcher_fill_next_token_bitmask(grammarMatcher, $0)
                }
            )
        else {
            return MLXArray.zeros([vocabSize])
        }

        let bytes = bufferSize &<< 2
        let bitmaskData = UnsafeRawBufferPointer(start: bitmask.data, count: bytes)
        let bitmask = MLXArray(bitmaskData, [bytes], type: Int8.self)
        let mask = bitmap[bitmask].reshaped([bytes * 8])[0..<vocabSize]
        return mask
    }

    func accept(token: MLXArray) {
        let tokenID = token.item(Int32.self)
        let accepted = grammar_matcher_accept_token(grammarMatcher, tokenID)
        if !accepted {
            reset()
        }
    }

    func accept(string: String) {
        _ = string.withCString { string in
            grammar_matcher_accept_string(grammarMatcher, string)
        }
    }

    func findJumpForwardString() -> String {
        guard let string = grammar_matcher_find_jump_forward_string(grammarMatcher) else {
            return ""
        }
        defer {
            grammar_matcher_string_free(string)
        }

        return String(cString: string)
    }

    func reset() {
        grammar_matcher_reset(grammarMatcher)
    }

    func isTerminated() -> Bool {
        return grammar_matcher_is_terminated(grammarMatcher)
    }
}

private extension DLTensor {
    static func nextTokenBitmask(bufferSize: Int) -> DLTensor {
        let dataBytes = bufferSize * MemoryLayout<Int32>.stride
        let data = UnsafeMutableRawPointer.allocate(byteCount: dataBytes, alignment: 64)
        data.bindMemory(to: Int32.self, capacity: bufferSize).initialize(repeating: 0, count: bufferSize)

        let shape = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        shape.initialize(repeating: 0, count: 1)
        shape[0] = Int64(bufferSize)

        let device = DLDevice(deviceType: 1, deviceId: 0)
        let dtype = DLDataType(rawCode: 0, bits: 32, lanes: 1)

        return DLTensor(
            data: data,
            device: device,
            ndim: 1,
            dtype: dtype,
            shape: shape,
            strides: nil,
            byteOffset: 0
        )
    }
}
