//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

private func swiftDateToKuzuTimestamp(_ date: Date) -> kuzu_timestamp_t {
    let timeInterval = date.timeIntervalSince1970
    let microseconds = timeInterval * 1_000_000
    return kuzu_timestamp_t(value: Int64(microseconds))
}

private func swiftTimeIntervalToKuzuInterval(_ timeInterval: TimeInterval)
    -> kuzu_interval_t
{
    let microseconds = timeInterval * 1_000_000
    return kuzu_interval_t(months: 0, days: 0, micros: Int64(microseconds))
}

private func swiftArrayOfMapItemsToKuzuMap(_ array: [(String, Any)]) throws
    -> UnsafeMutablePointer<kuzu_value>
{
    let numItems = array.count
    if numItems == 0 {
        throw KuzuError.valueConversionFailed(
            "Cannot convert empty array to Kuzu MAP"
        )
    }
    let keys: UnsafeMutablePointer<UnsafeMutablePointer<kuzu_value>?> =
        .allocate(capacity: numItems)
    let values: UnsafeMutablePointer<UnsafeMutablePointer<kuzu_value>?> =
        .allocate(capacity: numItems)
    for idx in 0..<numItems {
        keys[idx] = nil
        values[idx] = nil
    }
    defer {
        for idx in 0..<numItems {
            kuzu_value_destroy(keys[idx])
            kuzu_value_destroy(values[idx])
        }
        keys.deallocate()
        values.deallocate()
    }
    for (idx, (key, value)) in array.enumerated() {
        let key = try swiftValueToKuzuValue(key)
        let value = try swiftValueToKuzuValue(value)
        keys[idx] = key
        values[idx] = value
    }
    var valuePtr: UnsafeMutablePointer<kuzu_value>?
    let state = kuzu_value_create_map(UInt64(numItems), keys, values, &valuePtr)
    if state != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to create MAP value with status: \(state). Please make sure all the keys are of the same type and all the values are of the same type."
        )
    }
    return valuePtr!
}

private func swiftArrayToKuzuList(_ array: NSArray)
    throws -> UnsafeMutablePointer<kuzu_value>
{
    let numberOfElements = array.count
    if numberOfElements == 0 {
        throw KuzuError.valueConversionFailed(
            "Cannot convert empty array to Kuzu list"
        )
    }
    let cElementArray: UnsafeMutablePointer<UnsafeMutablePointer<kuzu_value>?> =
        .allocate(capacity: numberOfElements)
    for idx in 0..<numberOfElements {
        cElementArray[idx] = nil
    }
    defer {
        for idx in 0..<numberOfElements {
            kuzu_value_destroy(cElementArray[idx])
        }
        cElementArray.deallocate()
    }
    for (idx, element) in array.enumerated() {
        let cElement = try swiftValueToKuzuValue(element)
        cElementArray[idx] = cElement
    }
    var cKuzuListValue: UnsafeMutablePointer<kuzu_value>?
    let state = kuzu_value_create_list(
        UInt64(numberOfElements),
        cElementArray,
        &cKuzuListValue
    )
    if state != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to create LIST value with status: \(state). Please make sure all the values are of the same type."
        )
    }
    return cKuzuListValue!
}

private func swiftDictionaryToKuzuStruct(_ dictionary: NSDictionary)
    throws -> UnsafeMutablePointer<kuzu_value>
{
    let numFields = UInt64(dictionary.count)
    if numFields == 0 {
        throw KuzuError.valueConversionFailed(
            "Cannot convert empty map to Kuzu struct"
        )
    }
    var stringKeyMap: [String: UnsafeMutablePointer<kuzu_value>?] = [:]
    defer {
        for (_, cValue) in stringKeyMap {
            kuzu_value_destroy(cValue)
        }
    }
    for key in dictionary.allKeys {
        if let stringKey = key as? String {
            stringKeyMap[stringKey] = try swiftValueToKuzuValue(dictionary[key])
        } else {
            throw KuzuError.valueConversionFailed(
                "Cannot convert dictionary to Kuzu struct: keys must be strings"
            )
        }
    }
    // Sort the keys to ensure the order is consistent.
    // This is useful for creating a LIST of STRUCTs because in Kuzu, all the
    // LIST elements must have the same type (i.e., the same order of fields).
    let sortedKeys = Array(stringKeyMap.keys).sorted()

    var mutableSortedCStrings: [UnsafeMutablePointer<CChar>?] = []
    let sortedKeysCStrings: UnsafeMutablePointer<UnsafePointer<CChar>?> =
        .allocate(capacity: sortedKeys.count)
    let sortedValues: UnsafeMutablePointer<UnsafeMutablePointer<kuzu_value>?> =
        .allocate(capacity: sortedKeys.count)

    for idx in 0..<sortedKeys.count {
        let currKey = sortedKeys[idx]
        let currKeyCString = strdup(sortedKeys[idx])
        mutableSortedCStrings.append(currKeyCString)
        sortedKeysCStrings[idx] = UnsafePointer(currKeyCString)
        sortedValues[idx] = stringKeyMap[currKey]!
    }
    defer {
        for idx in 0..<sortedKeys.count {
            free(mutableSortedCStrings[idx])
        }
        sortedKeysCStrings.deallocate()
        sortedValues.deallocate()
    }

    var cStructValue: UnsafeMutablePointer<kuzu_value>?
    kuzu_value_create_struct(
        numFields,
        sortedKeysCStrings,
        sortedValues,
        &cStructValue
    )
    return cStructValue!
}

internal func swiftValueToKuzuValue(_ value: Any?)
    throws -> UnsafeMutablePointer<kuzu_value>
{
    if value == nil {
        return kuzu_value_create_null()
    }
    var valuePtr: UnsafeMutablePointer<kuzu_value>
    let dtype = Mirror(reflecting: value!).subjectType
    if let number = value as? NSNumber {
        // Handle numeric types based on the real type of the number, instead
        // of runtime casting (e.g. let number as Int), because a number can be
        // casted to multiple types, which can cause inconsistencies.
        // See https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        let objCType = String(cString: number.objCType)
        switch objCType {
        case "c":
            // Boolean is encoded as char in Swift / Objective-C.
            valuePtr =
                CFGetTypeID(number) == CFBooleanGetTypeID()
                ? kuzu_value_create_bool(number as! Bool)
                : kuzu_value_create_int8(number as! Int8)
        case "i":
            valuePtr = kuzu_value_create_int32(number as! Int32)
        case "s":
            valuePtr = kuzu_value_create_int16(number as! Int16)
        case "l":
            valuePtr = kuzu_value_create_int32(number as! Int32)
        case "q":
            valuePtr = kuzu_value_create_int64(number as! Int64)
        case "C":
            valuePtr = kuzu_value_create_uint8(number as! UInt8)
        case "I":
            valuePtr = kuzu_value_create_uint32(number as! UInt32)
        case "S":
            valuePtr = kuzu_value_create_uint16(number as! UInt16)
        case "L":
            valuePtr = kuzu_value_create_uint32(number as! UInt32)
        case "Q":
            valuePtr = kuzu_value_create_uint64(number as! UInt64)
        case "f":
            valuePtr = kuzu_value_create_float(number as! Float32)
        case "d":
            valuePtr = kuzu_value_create_double(number as! Double)
        default:
            throw KuzuError.valueConversionFailed(
                "Unsupported numeric type with encoding: \(objCType)"
            )
        }
    } else {
        switch value! {
        case let string as String:
            valuePtr = kuzu_value_create_string(string)
        case let date as Date:
            let timestamp = swiftDateToKuzuTimestamp(date)
            valuePtr = kuzu_value_create_timestamp(timestamp)
        case let timeInterval as TimeInterval:
            let interval = swiftTimeIntervalToKuzuInterval(timeInterval)
            valuePtr = kuzu_value_create_interval(interval)
        case let arrayOfMapItems as [(String, Any)]:
            valuePtr = try swiftArrayOfMapItemsToKuzuMap(arrayOfMapItems)
        case let array as NSArray:
            valuePtr = try swiftArrayToKuzuList(array)
        case let dictionary as NSDictionary:
            valuePtr = try swiftDictionaryToKuzuStruct(dictionary)

        default:
            throw KuzuError.valueConversionFailed(
                "Unsupported Swift type \(dtype)"
            )
        }
    }
    return valuePtr
}
