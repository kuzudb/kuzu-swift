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
public protocol KuzuDecodable {
    static var kuzuDataTypes: [KuzuDataType] { get }
    static func kuzuDecode(from container: consuming KuzuValue) throws -> Self
}

@_spi(Typed)
extension KuzuValue {
    fileprivate func nullCheck() throws {
        if kuzu_value_is_null(ptr) {
            throw KuzuError.getValueFailed(
                "Value is null"
            )
        }
    }
    
    fileprivate func typeCheck(_ expecting: [KuzuDataType]) throws {
        let typeId = LogicalType(from: self).id
        guard expecting.contains(typeId) else {
            throw KuzuError.valueConversionFailed(
                "Received \(typeId) type when expecting \(expecting)"
            )
        }
    }
}


@_spi(Typed)
extension Bool: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.bool]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: Bool = Bool()
        let state = kuzu_value_get_bool(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get bool value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension Int64: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.int64, .serial]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: Int64 = Int64()
        let state = kuzu_value_get_int64(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get int64 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension UInt64: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.uint64]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: UInt64 = UInt64()
        let state = kuzu_value_get_uint64(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get uint64 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension Int32: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.int32]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: Int32 = Int32()
        let state = kuzu_value_get_int32(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get int32 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension UInt32: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.uint32]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: UInt32 = UInt32()
        let state = kuzu_value_get_uint32(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get uint32 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension Int16: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.int16]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: Int16 = Int16()
        let state = kuzu_value_get_int16(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get int16 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension UInt16: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.uint16]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: UInt16 = UInt16()
        let state = kuzu_value_get_uint16(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get uint16 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension Int8: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.int8]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: Int8 = Int8()
        let state = kuzu_value_get_int8(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get int8 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension UInt8: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.uint8]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: UInt8 = UInt8()
        let state = kuzu_value_get_uint8(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get uint8 value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension Float: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.float]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: Float = Float()
        let state = kuzu_value_get_float(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get Float value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension Double: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.double]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var value: Double = Double()
        let state = kuzu_value_get_double(container.ptr, &value)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get Double value with status \(state)"
            )
        }
        return value
    }
}

@_spi(Typed)
extension KuzuInterval: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.interval]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var cIntervalValue = kuzu_interval_t()
        let state = kuzu_value_get_interval(container.ptr, &cIntervalValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get interval value with status \(state)"
            )
        }
        return KuzuInterval(
            months: cIntervalValue.months,
            days: cIntervalValue.days,
            micros: cIntervalValue.micros
        )
    }
}

@_spi(Typed)
extension String: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.string]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var strValue: UnsafeMutablePointer<CChar>?
        let state = kuzu_value_get_string(container.ptr, &strValue)
        defer { kuzu_destroy_string(strValue) }
        guard state == KuzuSuccess, let strValue else {
            throw KuzuError.getValueFailed(
                "Failed to get string value with status \(state)"
            )
        }
        return String(cString: strValue)
    }
}

@_spi(Typed)
extension UUID: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.uuid]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var valueString: UnsafeMutablePointer<CChar>?
        let state = kuzu_value_get_uuid(container.ptr, &valueString)
        defer { kuzu_destroy_string(valueString) }
        guard state == KuzuSuccess, let valueString, let uuid = UUID(uuidString: String(cString: valueString)) else {
            throw KuzuError.getValueFailed(
                "Failed to get uuid value with status \(state)"
            )
        }
        return uuid
    }
}

@_spi(Typed)
extension Date: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.date, .timestamp, .timestampMs, .timestampNs, .timestampTz, .timestampSec]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        
        let typeId = LogicalType(from: container).id
        switch typeId {
        case .date: return try kuzuDate(from: container)
        case .timestamp: return try kuzuTimestamp(from: container)
        case .timestampMs: return try kuzuTimestampMs(from: container)
        case .timestampNs: return try kuzuTimestampNs(from: container)
        case .timestampTz: return try kuzuTimestampTz(from: container)
        case .timestampSec: return try kuzuTimestampSec(from: container)
        default:
            throw KuzuError.valueConversionFailed(
                "Received \(typeId) type when expecting \(Self.kuzuDataTypes)"
            )
        }
    }
    
    static func kuzuTimestamp(from container: consuming KuzuValue) throws -> Self {
        var cTimestampValue = kuzu_timestamp_t()
        let state = kuzu_value_get_timestamp(container.ptr, &cTimestampValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let microseconds = cTimestampValue.value
        let seconds: Double = Double(microseconds) / MICROSECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    }
    
    static func kuzuTimestampNs(from container: consuming KuzuValue) throws -> Self {
        var cTimestampValue = kuzu_timestamp_ns_t()
        let state = kuzu_value_get_timestamp_ns(container.ptr, &cTimestampValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let nanoseconds = cTimestampValue.value
        let seconds: Double = Double(nanoseconds) / NANOSECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    }
    
    static func kuzuTimestampMs(from container: consuming KuzuValue) throws -> Self {
        var cTimestampValue = kuzu_timestamp_ms_t()
        let state = kuzu_value_get_timestamp_ms(container.ptr, &cTimestampValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let milliseconds = cTimestampValue.value
        let seconds: Double = Double(milliseconds) / MILLISECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    }
    
    static func kuzuTimestampSec(from container: consuming KuzuValue) throws -> Self {
        var cTimestampValue = kuzu_timestamp_sec_t()
        let state = kuzu_value_get_timestamp_sec(container.ptr, &cTimestampValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let seconds = cTimestampValue.value
        return Date(timeIntervalSince1970: Double(seconds))
    }
    
    static func kuzuTimestampTz(from container: consuming KuzuValue) throws -> Self {
        var cTimestampValue = kuzu_timestamp_tz_t()
        let state = kuzu_value_get_timestamp_tz(container.ptr, &cTimestampValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let microseconds = cTimestampValue.value
        let seconds: Double = Double(microseconds) / MICROSECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    }
    
    static func kuzuDate(from container: consuming KuzuValue) throws -> Self {
        var cDateValue = kuzu_date_t()
        let state = kuzu_value_get_date(container.ptr, &cDateValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get date value with status \(state)"
            )
        }
        let days = cDateValue.days
        let seconds: Double = Double(days) * SECONDS_IN_A_DAY
        return Date(timeIntervalSince1970: seconds)
    }
}

@_spi(Typed)
extension Decimal: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.decimal, .int128]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        
        let typeId = LogicalType(from: container).id
        switch typeId {
        case .decimal: return try kuzuDecimal(from: container)
        case .int128: return try kuzuInt128(from: container)
        default:
            throw KuzuError.valueConversionFailed(
                "Received \(typeId) type when expecting \(Self.kuzuDataTypes)"
            )
        }
    }
    
    static func kuzuDecimal(from container: consuming KuzuValue) throws -> Self {
        var outString: UnsafeMutablePointer<CChar>?
        let state = kuzu_value_get_decimal_as_string(container.ptr, &outString)
        defer { kuzu_destroy_string(outString) }
        guard state == KuzuSuccess, let outString else {
            throw KuzuError.getValueFailed(
                "Failed to get string value of decimal type with status: \(state)"
            )
        }
        let decimalString = String(cString: outString)
        guard let decimal = Decimal(string: decimalString) else {
            throw KuzuError.valueConversionFailed(
                "Failed to convert decimal value from string: \(decimalString)"
            )
        }
        return decimal
    }
    
    static func kuzuInt128(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        var int128Value = kuzu_int128_t()
        let getValueState = kuzu_value_get_int128(container.ptr, &int128Value)
        guard getValueState == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get int128 value with status \(getValueState)"
            )
        }
        var valueString: UnsafeMutablePointer<CChar>?
        let valueConversionState = kuzu_int128_t_to_string(
            int128Value,
            &valueString
        )
        defer { kuzu_destroy_string(valueString) }
        guard valueConversionState == KuzuSuccess, let valueString else {
            throw KuzuError.getValueFailed(
                "Failed to convert int128 to string with status \(valueConversionState)"
            )
        }
        let decimalString = String(cString: valueString)
        guard let decimal = Decimal(string: decimalString) else {
            throw KuzuError.valueConversionFailed(
                "Failed to convert decimal value from string: \(decimalString)"
            )
        }
        return decimal
    }
}

@_spi(Typed)
extension KuzuInternalId: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.internalId]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var cInternalIdValue = kuzu_internal_id_t()
        let state = kuzu_value_get_internal_id(container.ptr, &cInternalIdValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Failed to get internal id value with status \(state)"
            )
        }
        return KuzuInternalId(
            tableId: cInternalIdValue.table_id,
            offset: cInternalIdValue.offset
        )
    }
}

@_spi(Typed)
extension Data: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.blob]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        var cBlobValue: UnsafeMutablePointer<UInt8>?
        let state = kuzu_value_get_blob(container.ptr, &cBlobValue)
        defer { kuzu_destroy_blob(cBlobValue) }
        guard state == KuzuSuccess, let cBlobValue else {
            throw KuzuError.getValueFailed(
                "Failed to get blob value with status \(state)"
            )
        }
        let blobSize = strlen(cBlobValue)
        let blobData = Data(bytes: cBlobValue, count: blobSize)
        return blobData
    }
}

@_spi(Typed)
extension Optional: KuzuDecodable where Wrapped: KuzuDecodable {
    public static var kuzuDataTypes: [KuzuDataType] { Wrapped.kuzuDataTypes }
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        if kuzu_value_is_null(container.ptr) {
            return nil
        }
        
        return try Wrapped.kuzuDecode(from: container)
    }
}

@_spi(Typed)
extension Array: KuzuDecodable where Element: KuzuDecodable {
    public static var kuzuDataTypes: [KuzuDataType] { [.list, .array] }
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        let logicalType = LogicalType(from: container)
        let numElements: UInt64
        
        switch logicalType.id {
        case .array:
            numElements = try logicalType.kuzuArrayElementCount()
        case .list:
            numElements = try container.kuzuListElementCount()
        default:
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements - unknown list/array type \(logicalType.id)"
            )
        }
        
        var result: [Element] = []
        for i in UInt64(0)..<numElements {
            var currentValue = kuzu_value()
            let value = try container.getListValue(index: i, into: &currentValue)
            try result.append(Element.kuzuDecode(from: value))
        }
        return result
    }
}

@_spi(Typed)
extension Dictionary: KuzuDecodable where Key == String, Value: KuzuDecodable {
    public static var kuzuDataTypes: [KuzuDataType] { [.struct] }
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        let propertySize = try container.kuzuStructElementCount()

        var dict: [String: Value] = [:]
        for i in UInt64(0)..<propertySize {
            let key = try container.getStructKey(index: i)
            
            var currentValue = kuzu_value()
            let value = try container.getStructValue(index: i, into: &currentValue)
            dict[key] = try Value.kuzuDecode(from: value)
        }

        return dict
    }
}

@_spi(Typed)
extension KuzuMap: KuzuDecodable where Key: KuzuDecodable, Value: KuzuDecodable {
    public static var kuzuDataTypes: [KuzuDataType] { [.map] }
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)
        
        let mapSize = try container.kuzuMapElementCount()

        var result: [(Key, Value)] = []
        for i in UInt64(0)..<mapSize {
            var currentKey = kuzu_value()
            let key = try container.getMapKey(index: i, into: &currentKey)
            
            var currentValue = kuzu_value()
            let value = try container.getMapValue(index: i, into: &currentValue)

            try result.append((
                Key.kuzuDecode(from: key),
                Value.kuzuDecode(from: value)
            ))
        }

        return .init(result)
    }
}

@_spi(Typed)
extension KuzuNode_: KuzuDecodable {
    public static let kuzuDataTypes: [KuzuDataType] = [.node]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)

        var idValue = kuzu_value()
        let idState = kuzu_node_val_get_id_val(container.ptr, &idValue)
        let kuzuId = KuzuValue(ptr: &idValue)
        guard idState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get node ID with status: \(idState)"
            )
        }
        let id = try KuzuInternalId.kuzuDecode(from: kuzuId)

        var labelValue = kuzu_value()
        let labelState = kuzu_node_val_get_label_val(container.ptr, &labelValue)
        let kuzuLabel = KuzuValue(ptr: &labelValue)
        guard labelState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get node label with status: \(labelState)"
            )
        }
        let label = try String.kuzuDecode(from: kuzuLabel)

        let propertySize = try container.kuzuNodeElementCount()
        var properties: [String: any KuzuDecodable] = [:]

        for i in UInt64(0)..<propertySize {
            let key = try container.getNodeKey(index: i)

            var currentValue = kuzu_value()
            let value = try container.getNodeValue(index: i, into: &currentValue)
            properties[key] = try LogicalType(from: value).id.decode(from: value)
        }

        return KuzuNode_(
            id: id,
            label: label,
            properties: properties
        )
    }
}

@_spi(Typed)
extension KuzuRelationship_: KuzuDecodable {
public static let kuzuDataTypes: [KuzuDataType] = [.rel]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)

        var idValue = kuzu_value()
        let idState = kuzu_rel_val_get_id_val(container.ptr, &idValue)
        let idKuzu = KuzuValue(ptr: &idValue)
        guard idState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get node ID with status: \(idState)"
            )
        }
        let id = try KuzuInternalId.kuzuDecode(from: idKuzu)

        var sourceValue = kuzu_value()
        let sourceState = kuzu_rel_val_get_src_id_val(container.ptr, &sourceValue)
        let sourceKuzu = KuzuValue(ptr: &sourceValue)
        guard sourceState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get relationship source ID with status: \(sourceState)"
            )
        }
        let sourceId = try KuzuInternalId.kuzuDecode(from: sourceKuzu)

        var targetValue = kuzu_value()
        let targetState = kuzu_rel_val_get_dst_id_val(container.ptr, &idValue)
        let targetKuzu = KuzuValue(ptr: &targetValue)
        guard targetState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get relationship target ID with status: \(targetState)"
            )
        }
        let targetId = try KuzuInternalId.kuzuDecode(from: targetKuzu)

        var labelValue = kuzu_value()
        let labelState = kuzu_rel_val_get_label_val(container.ptr, &labelValue)
        let labelKuzu = KuzuValue(ptr: &labelValue)
        guard labelState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get relationship label with status: \(labelState)"
            )
        }
        let label = try String.kuzuDecode(from: labelKuzu)

        let propertySize = try container.kuzuRelElementCount()
        var properties: [String: any KuzuDecodable] = [:]

        for i in UInt64(0)..<propertySize {
            let key = try container.getRelName(index: i)

            var currentValue = kuzu_value()
            let value = try container.getRelValue(index: i, into: &currentValue)
            properties[key] = try LogicalType(from: value).id.decode(from: value)
        }

        return KuzuRelationship_(
            id: id,
            sourceId: sourceId,
            targetId: targetId,
            label: label,
            properties: properties
        )
    }
}

@_spi(Typed)
extension KuzuRecursiveRelationship_: KuzuDecodable {
public static let kuzuDataTypes: [KuzuDataType] = [.recursiveRel]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck(Self.kuzuDataTypes)

        var nodesValue = kuzu_value()
        let nodesState = kuzu_value_get_recursive_rel_node_list(
            container.ptr,
            &nodesValue
        )
        let nodesKuzu = KuzuValue(ptr: &nodesValue)
        guard nodesState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get recursive relationship nodes with status: \(nodesState)"
            )
        }

        var relsValue = kuzu_value()
        let relsState = kuzu_value_get_recursive_rel_rel_list(
            container.ptr, 
            &relsValue
        )
        let relsKuzu = KuzuValue(ptr: &relsValue)
        guard relsState == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get recursive relationship relationships with status: \(relsState)"
            )
        }

        let nodes = try Array<KuzuNode_>.kuzuDecode(from: nodesKuzu)
        let rels = try Array<KuzuRelationship_>.kuzuDecode(from: relsKuzu)

        return KuzuRecursiveRelationship_(
            nodes: nodes, 
            relationships: rels
        )
    }
}

@_spi(Typed)
public struct KuzuAnyDecodable: KuzuDecodable {
    public let value: any KuzuDecodable
    
    public static let kuzuDataTypes: [KuzuDataType] = [.any]
    public static func kuzuDecode(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        let type = LogicalType(from: container)
        let decoded = try type.id.decode(from: container)
        return .init(value: decoded)
    }

    public static func kuzuUnion(from container: consuming KuzuValue) throws -> Self {
        try container.nullCheck()
        try container.typeCheck([.union])

        var unionValue = kuzu_value()
        let state = kuzu_value_get_struct_field_value(container.ptr, 0, &unionValue)
        let kuzu = KuzuValue(ptr: &unionValue)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get union value with status: \(state)"
            )
        }

        return try Self.kuzuDecode(from: kuzu)
    }
}

// MARK: Helpers

extension KuzuValue {
    fileprivate func getListValue(
        index: UInt64,
        into cValue: inout kuzu_value
    ) throws -> KuzuValue {
        let state = kuzu_value_get_list_element(ptr, index, &cValue)
        let kuzu = KuzuValue(ptr: &cValue)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get list element with status: \(state)"
            )
        }
        return kuzu
    }
    
    fileprivate func getStructValue(
        index: UInt64,
        into cValue: inout kuzu_value
    ) throws -> KuzuValue {
        let state = kuzu_value_get_struct_field_value(ptr, index, &cValue)
        let kuzu = KuzuValue(ptr: &cValue)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get struct field with status: \(state)"
            )
        }
        return kuzu
    }
    
    fileprivate func getStructKey(index: UInt64) throws -> String {
        var currentKey: UnsafeMutablePointer<CChar>?
        let keyState = kuzu_value_get_struct_field_name(ptr, index, &currentKey)
        defer { kuzu_destroy_string(currentKey) }
        guard keyState == KuzuSuccess, let currentKey else {
            throw KuzuError.valueConversionFailed(
                "Failed to get struct field name with status: \(keyState)"
            )
        }
        return String(cString: currentKey)
    }
    
    fileprivate func getMapValue(
        index: UInt64,
        into cValue: inout kuzu_value
    ) throws -> KuzuValue {
        let state = kuzu_value_get_map_value(ptr, index, &cValue)
        let kuzu = KuzuValue(ptr: &cValue)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get map value with status: \(state)"
            )
        }
        return kuzu
    }
    
    fileprivate func getMapKey(
        index: UInt64,
        into cValue: inout kuzu_value
    ) throws -> KuzuValue {
        let state = kuzu_value_get_map_key(ptr, index, &cValue)
        let kuzu = KuzuValue(ptr: &cValue)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get map key with status: \(state)"
            )
        }
        return kuzu
    }
    
    fileprivate func getNodeValue(
        index: UInt64,
        into cValue: inout kuzu_value
    ) throws -> KuzuValue {
        let state = kuzu_node_val_get_property_value_at(ptr, index, &cValue)
        let kuzu = KuzuValue(ptr: &cValue)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get node property value with status: \(state)"
            )
        }
        return kuzu
    }
    
    fileprivate func getNodeKey(index: UInt64) throws -> String {
        var currentKey: UnsafeMutablePointer<CChar>?
        let keyState = kuzu_node_val_get_property_name_at(ptr, index, &currentKey)
        defer { kuzu_destroy_string(currentKey) }
        guard keyState == KuzuSuccess, let currentKey else {
            throw KuzuError.valueConversionFailed(
                "Failed to get node propery name with status: \(keyState)"
            )
        }
        return String(cString: currentKey)
    }

    fileprivate func getRelName(index: UInt64) throws -> String {
        var currentKey: UnsafeMutablePointer<CChar>?
        let keyState = kuzu_rel_val_get_property_name_at(ptr, index, &currentKey)
        defer { kuzu_destroy_string(currentKey) }
        guard keyState == KuzuSuccess, let currentKey else {
            throw KuzuError.valueConversionFailed(
                "Failed to get rel propery name with status: \(keyState)"
            )
        }
        return String(cString: currentKey)
    }

        fileprivate func getRelValue(
        index: UInt64,
        into cValue: inout kuzu_value
    ) throws -> KuzuValue {
        let state = kuzu_rel_val_get_property_value_at(ptr, index, &cValue)
        let kuzu = KuzuValue(ptr: &cValue)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get node property value with status: \(state)"
            )
        }
        return kuzu
    }
    
    fileprivate func kuzuListElementCount() throws -> UInt64 {
        var numElements: UInt64 = 0
        
        let state = kuzu_value_get_list_size(ptr, &numElements)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in list with status: \(state)"
            )
        }
        return numElements
    }
    
    fileprivate func kuzuStructElementCount() throws -> UInt64 {
        var propertySize: UInt64 = 0
        
        let state = kuzu_value_get_struct_num_fields(ptr, &propertySize)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in struct with status: \(state)"
            )
        }
        
        return propertySize
    }
    
    fileprivate func kuzuMapElementCount() throws -> UInt64 {
        var mapSize: UInt64 = 0
        
        let state = kuzu_value_get_map_size(ptr, &mapSize)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in map with status: \(state)"
            )
        }
        
        return mapSize
    }
    
    fileprivate func kuzuNodeElementCount() throws -> UInt64 {
        var propertySize: UInt64 = 0
        
        let state = kuzu_node_val_get_property_size(ptr, &propertySize)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in node with status: \(state)"
            )
        }
        
        return propertySize
    }

    fileprivate func kuzuRelElementCount() throws -> UInt64 {
        var propertySize: UInt64 = 0
        
        let state = kuzu_rel_val_get_property_size(ptr, &propertySize)
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in relationship with status: \(state)"
            )
        }
        
        return propertySize
    }
}

extension LogicalType {
    fileprivate func kuzuArrayElementCount() throws -> UInt64 {
        var numElements: UInt64 = 0
        
        let state = kuzu_data_type_get_num_elements_in_array(
            ptr,
            &numElements
        )
        guard state == KuzuSuccess else {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in array with status: \(state)"
            )
        }
        
        return numElements
    }
}