//
//  DLTensor.swift
//  MLXStructured
//
//  Created by Ivan Petrukha on 15.09.2025.
//

import Foundation

struct DLDevice {
    
    var deviceType: Int32
    var deviceId: Int32
    
    public init(deviceType: Int32, deviceId: Int32) {
        self.deviceType = deviceType
        self.deviceId = deviceId
    }
}

struct DLDataType {
    
    var code: UInt8
    var bits: UInt8
    var lanes: UInt16
    
    init(rawCode: UInt8, bits: UInt8, lanes: UInt16) {
        self.code = rawCode
        self.bits = bits
        self.lanes = lanes
    }
}

struct DLTensor {
    
    var data: UnsafeMutableRawPointer?
    var device: DLDevice
    var ndim: Int32
    var dtype: DLDataType
    var shape: UnsafeMutablePointer<Int64>?
    var strides: UnsafeMutablePointer<Int64>?
    var byteOffset: UInt64
    
    init(
        data: UnsafeMutableRawPointer?,
        device: DLDevice,
        ndim: Int32,
        dtype: DLDataType,
        shape: UnsafeMutablePointer<Int64>?,
        strides: UnsafeMutablePointer<Int64>?,
        byteOffset: UInt64
    ) {
        self.data = data
        self.device = device
        self.ndim = ndim
        self.dtype = dtype
        self.shape = shape
        self.strides = strides
        self.byteOffset = byteOffset
    }
}
