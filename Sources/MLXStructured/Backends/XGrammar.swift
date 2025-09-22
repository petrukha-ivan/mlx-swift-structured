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

private let errorHandler = {
    let handler = ErrorHandler()
    set_error_handler(errorHandlerClosure)
    return handler
}()

private let errorHandlerClosure: @convention(c) (UnsafePointer<CChar>?) -> Void = {
    errorHandler.lastErrorMessage = $0.map {
        String(cString: $0)
    }
}

private class ErrorHandler: @unchecked Sendable {
    let lock = NSLock()
    var _lastErrorMessage: String? = nil
    var lastErrorMessage: String? {
        get { lock.withLock { _lastErrorMessage } }
        set { lock.withLock { _lastErrorMessage = newValue } }
    }
}

private extension XGrammar {
    static var lastErrorMessage: String {
        errorHandler.lastErrorMessage ?? "Unknown Error"
    }
}

final class XGrammar {
            
    private let vocabSize: Int
    private let bufferSize: Int
    private let bitmap: MLXArray
    private var bitmask: DLTensor
    private let grammarMatcher: UnsafeMutableRawPointer?
    
    init(
        vocab: [String],
        vocabType: Int32 = 0,
        stopTokenIds: [Int32] = [],
        grammar: Grammar
    ) throws {
        let _ = errorHandler // Start capturing errors
        let vocab = vocab.map { strdup($0) }
        let tokenizerInfo = vocab.map({ UnsafePointer($0) }).withUnsafeBufferPointer { vocabBuffer in
            stopTokenIds.withUnsafeBufferPointer { stopTokenIdsBuffer in
                tokenizer_info_new(
                    vocabBuffer.baseAddress,
                    vocabBuffer.count,
                    vocabType,
                    stopTokenIdsBuffer.baseAddress,
                    stopTokenIdsBuffer.count
                )
            }
        }
        
        defer {
            tokenizer_info_free(tokenizerInfo)
            vocab.forEach {
                free($0)
            }
        }
        
        guard let tokenizerInfo else {
            throw XGrammarError.invalidVocab(XGrammar.lastErrorMessage)
        }
        
        let compiledGrammar = switch grammar {
        case _ where grammar.raw.isEmpty:
            throw XGrammarError.emptyGrammar
        case .ebnf(let ebnf):
            ebnf.utf8CString.withUnsafeBufferPointer {
                compile_ebnf_grammar(tokenizerInfo, $0.baseAddress, $0.count)
            }
        case .regex(let regex):
            regex.utf8CString.withUnsafeBufferPointer {
                compile_regex_grammar(tokenizerInfo, $0.baseAddress, $0.count)
            }
        case .schema(let schema, let indent):
            schema.utf8CString.withUnsafeBufferPointer {
                compile_json_schema_grammar(tokenizerInfo, $0.baseAddress, $0.count, Int32(indent ?? -1))
            }
        }
        
        defer {
            compiled_grammar_free(compiledGrammar)
        }
        
        guard let compiledGrammar else {
            throw XGrammarError.invalidGrammar(XGrammar.lastErrorMessage)
        }
        
        var bitmap = [Float](repeating: 0, count: 256 * 8)
        for b in 0..<256 {
            for k in 0..<8 {
                bitmap[b * 8 + k] = ((b >> k) & 1) == 1 ? 0 : -Float.infinity
            }
        }
        
        guard let grammarMatcher = grammar_matcher_new(compiledGrammar) else {
            throw XGrammarError.unknown(XGrammar.lastErrorMessage)
        }
        
        self.vocabSize = vocab.count
        self.bufferSize = (vocab.count + 31) / 32
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
        guard withUnsafeMutablePointer(to: &bitmask, {
            grammar_matcher_fill_next_token_bitmask(grammarMatcher, $0)
        }) else {
            return MLXArray.zeros([vocabSize])
        }
        
        let bytes = bufferSize &<< 2
        let bitmaskData = UnsafeRawBufferPointer(start: bitmask.data, count: bytes)
        let bitmask = MLXArray(bitmaskData, [bytes], type: Int8.self)
        let mask = bitmap[bitmask].reshaped([bytes * 8])[0..<vocabSize]
        return mask
    }
    
    func advance(token: MLXArray) {
        let tokenID = token.item(Int32.self)
        let accepted = grammar_matcher_accept_token(grammarMatcher, tokenID)
        if !accepted {
            reset()
        }
    }
    
    func reset() {
        grammar_matcher_reset(grammarMatcher)
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
