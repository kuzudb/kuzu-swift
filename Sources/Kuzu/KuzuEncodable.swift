//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import cxx_kuzu

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if os(macOS) || os(iOS)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import ucrt
#else
#error("Unknown platform")
#endif

@_spi(Typed)
public protocol KuzuEncodable {
    func kuzuValue() throws -> KuzuValue
}

@_spi(Typed)
extension Optional: KuzuEncodable where Wrapped: KuzuEncodable {
    public func kuzuValue() throws -> KuzuValue {
        if let self {
            try self.kuzuValue()
        } else {
            KuzuValue.null()
        }
    }
}

@_spi(Typed)
extension Array: KuzuEncodable where Element: KuzuEncodable {
    public func kuzuValue() throws -> KuzuValue {
        try ListContainer(items: self).kuzuValue()
    }
}

@_spi(Typed)
extension Dictionary: KuzuEncodable where Key == String, Value: KuzuEncodable {
    public func kuzuValue() throws -> KuzuValue {
        try StructContainer(items: self).kuzuValue()
    }
}

@_spi(Typed)
extension KuzuMap: KuzuEncodable where Key: KuzuEncodable, Value: KuzuEncodable {
    public func kuzuValue() throws -> KuzuValue {
        try MapContainer(items: tuples).kuzuValue()
    }
}

@_spi(Typed)
extension Bool: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_bool(self))
    }
}

@_spi(Typed)
extension Int8: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_int8(self))
    }
}

@_spi(Typed)
extension UInt8: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_uint8(self))
    }
}

@_spi(Typed)
extension Int16: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_int16(self))
    }
}

@_spi(Typed)
extension UInt16: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_uint16(self))
    }
}

@_spi(Typed)
extension Int32: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_int32(self))
    }
}

@_spi(Typed)
extension UInt32: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_uint32(self))
    }
}

@_spi(Typed)
extension Int64: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_int64(self))
    }
}

@_spi(Typed)
extension UInt64: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_uint64(self))
    }
}

@_spi(Typed)
extension Float: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_float(self))
    }
}

@_spi(Typed)
extension Double: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_double(self))
    }
}

@_spi(Typed)
extension String: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_string(self))
    }
}

@_spi(Typed)
extension Date: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        let timeInterval = self.timeIntervalSince1970
        let microseconds = timeInterval * MICROSECONDS_IN_A_SECOND
        let cValue = kuzu_timestamp_t(value: Int64(microseconds))
        return .init(ptr: kuzu_value_create_timestamp(cValue))
    }
}

@_spi(Typed)
extension UUID: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_string(uuidString))
    }
}

@_spi(Typed)
extension KuzuInterval: KuzuEncodable {
    public func kuzuValue() -> KuzuValue {
        .init(ptr: kuzu_value_create_interval(kuzu_interval_t(months: months, days: days, micros: micros)))
    }
}

private final class Box<T: ~Copyable> {
    var value: T
    init(_ value: consuming T) {
        self.value = value
    }
}

private final class ListContainer: KuzuEncodable {
    let count: Int
    let items: [Box<KuzuValue>]
    
    init(items: [some KuzuEncodable]) throws {
        self.count = items.count
        self.items = try items.map { try Box($0.kuzuValue()) }
    }
    
    var pointers: [UnsafeMutablePointer<kuzu_value>?] {
        items.map { $0.value.ptr }
    }
    
    func kuzuValue() throws -> KuzuValue {
        guard count > 0 else {
            throw KuzuError.valueConversionFailed(
                "Cannot convert empty array to Kuzu list"
            )
        }
        
        var outValue: UnsafeMutablePointer<kuzu_value>?
        let state = pointers.withUnsafeBufferPointer { buffer in
            kuzu_value_create_list(
                UInt64(count),
                UnsafeMutablePointer(mutating: buffer.baseAddress),
                &outValue
            )
        }

        guard state == KuzuSuccess, let outValue else {
            throw KuzuError.valueConversionFailed(
                "Failed to create list value with status: \(state)"
            )
        }

        return KuzuValue(ptr: outValue)
    }
}

private final class StructContainer: KuzuEncodable {
    let count: Int
    let keys: [Box<CString>]
    let values: [Box<KuzuValue>]
    
    init(items: [String: some KuzuEncodable]) throws {
        self.count = items.count
        self.keys = items.map { Box(CString($0.key)) }
        self.values = try items.map { try Box($0.value.kuzuValue()) }
    }
    
    var valuePointers: [UnsafeMutablePointer<kuzu_value>?] {
        values.map { $0.value.ptr }
    }
    
    var charPointers: [UnsafePointer<CChar>?] {
        keys.map { UnsafePointer($0.value.ptr) }
    }
    
    struct CString: ~Copyable {
        let ptr: UnsafeMutablePointer<CChar>?
        
        init(_ string: String) {
            self.ptr = strdup(string)
        }
        
        deinit {
            free(ptr)
        }
    }
    
    func kuzuValue() throws -> KuzuValue {
        guard count > 0 else {
            throw KuzuError.valueConversionFailed("Cannot convert empty dictionary to Kuzu struct")
        }

        var outValue: UnsafeMutablePointer<kuzu_value>?
        let state = charPointers.withUnsafeBufferPointer { namesBuffer in
            valuePointers.withUnsafeBufferPointer { valuesBuffer in
                kuzu_value_create_struct(
                    UInt64(count),
                    UnsafeMutablePointer(mutating: namesBuffer.baseAddress),
                    UnsafeMutablePointer(mutating: valuesBuffer.baseAddress),
                    &outValue
                )
            }
        }

        guard state == KuzuSuccess, let outValue else {
            throw KuzuError.valueConversionFailed(
                "Failed to create struct value with status: \(state)"
            )
        }

        return KuzuValue(ptr: outValue)
    }
}

private final class MapContainer: KuzuEncodable {
    let count: Int
    let keys: [Box<KuzuValue>]
    let values: [Box<KuzuValue>]
    
    init(items: [(some KuzuEncodable, some KuzuEncodable)]) throws {
        self.count = items.count
        self.keys = try items.map { try Box($0.0.kuzuValue()) }
        self.values = try items.map { try Box($0.1.kuzuValue()) }
    }
    
    var valuePointers: [UnsafeMutablePointer<kuzu_value>?] {
        values.map { $0.value.ptr }
    }
    
    var keyPointers: [UnsafeMutablePointer<kuzu_value>?] {
        keys.map { $0.value.ptr }
    }
    
    func kuzuValue() throws -> KuzuValue {
        guard count > 0 else {
            throw KuzuError.valueConversionFailed("Cannot convert empty dictionary to Kuzu struct")
        }

        var outValue: UnsafeMutablePointer<kuzu_value>?
        let state = keyPointers.withUnsafeBufferPointer { keysBuffer in
            valuePointers.withUnsafeBufferPointer { valuesBuffer in
                kuzu_value_create_map(
                    UInt64(count),
                    UnsafeMutablePointer(mutating: keysBuffer.baseAddress),
                    UnsafeMutablePointer(mutating: valuesBuffer.baseAddress),
                    &outValue
                )
            }
        }

        guard state == KuzuSuccess, let outValue else {
            throw KuzuError.valueConversionFailed(
                "Failed to create MAP value with status: \(state). Please make sure all the keys are of the same type and all the values are of the same type."
            )
        }

        return KuzuValue(ptr: outValue)
    }
}
