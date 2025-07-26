//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

/// Constants for time unit conversions
private let MILLISECONDS_IN_A_SECOND: Double = 1_000
private let MICROSECONDS_IN_A_MILLISECOND: Double = 1_000
private let MICROSECONDS_IN_A_SECOND: Double =
    MILLISECONDS_IN_A_SECOND * MICROSECONDS_IN_A_MILLISECOND
private let NANOSECONDS_IN_A_MICROSECOND: Double = 1_000
private let NANOSECONDS_IN_A_SECOND: Double =
    MICROSECONDS_IN_A_SECOND * NANOSECONDS_IN_A_MICROSECOND
private let SECONDS_IN_A_MINUTE: Double = 60
private let MINUTES_IN_AN_HOUR: Double = 60
private let HOURS_IN_A_DAY: Double = 24
private let DAYS_IN_A_MONTH: Double = 30
private let SECONDS_IN_A_DAY =
    HOURS_IN_A_DAY * MINUTES_IN_AN_HOUR * SECONDS_IN_A_MINUTE
private let SECONDS_IN_A_MONTH = DAYS_IN_A_MONTH * SECONDS_IN_A_DAY

/// Converts a Swift Date to a Kuzu timestamp.
/// - Parameter date: The Swift Date to convert.
/// - Returns: A Kuzu timestamp representing the same time.
private func swiftDateToKuzuTimestamp(_ date: Date) -> kuzu_timestamp_t {
    let timeInterval = date.timeIntervalSince1970
    let microseconds = timeInterval * MICROSECONDS_IN_A_SECOND
    return kuzu_timestamp_t(value: Int64(microseconds))
}

/// Converts a Swift TimeInterval to a Kuzu interval.
/// - Parameter timeInterval: The Swift TimeInterval to convert.
/// - Returns: A Kuzu interval representing the same duration.
private func swiftTimeIntervalToKuzuInterval(_ timeInterval: TimeInterval)
    -> kuzu_interval_t
{
    let microseconds = timeInterval * MICROSECONDS_IN_A_SECOND
    return kuzu_interval_t(months: 0, days: 0, micros: Int64(microseconds))
}

/// Converts a Kuzu interval to a Swift TimeInterval.
/// - Parameter interval: The Kuzu interval to convert.
/// - Returns: A Swift TimeInterval representing the same duration.
private func kuzuIntervalToSwiftTimeInterval(_ interval: kuzu_interval_t)
    -> TimeInterval
{
    var seconds = Double(interval.micros) / MICROSECONDS_IN_A_SECOND
    seconds += Double(interval.days) * SECONDS_IN_A_DAY
    seconds += Double(interval.months) * SECONDS_IN_A_MONTH
    return seconds
}

/// Converts a Swift array of key-value pairs to a Kuzu map value.
/// - Parameter array: An array of tuples containing key-value pairs.
/// - Returns: A Kuzu map value.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func swiftArrayOfMapItemsToKuzuMap(_ array: [(Any?, Any?)]) throws
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

/// Converts a Kuzu map value to a Swift array of key-value pairs.
/// - Parameter cValue: The Kuzu map value to convert.
/// - Returns: An array of tuples containing key-value pairs.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func kuzuMapToSwiftArrayOfMapItems(_ cValue: inout kuzu_value) throws
    -> [(Any?, Any?)]
{
    var mapSize: UInt64 = 0
    let state = kuzu_value_get_map_size(&cValue, &mapSize)
    if state != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get map size with status: \(state)"
        )
    }
    var result: [(Any?, Any?)] = []
    var currentKey = kuzu_value()
    var currentValue = kuzu_value()
    for i in UInt64(0)..<mapSize {
        let keyState = kuzu_value_get_map_key(&cValue, i, &currentKey)
        if keyState != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get map key with status: \(keyState)"
            )
        }
        defer { kuzu_value_destroy(&currentKey) }
        let valueState = kuzu_value_get_map_value(&cValue, i, &currentValue)
        if valueState != KuzuSuccess {
            kuzu_value_destroy(&currentKey)
            throw KuzuError.valueConversionFailed(
                "Failed to get map value with status: \(valueState)"
            )
        }
        defer { kuzu_value_destroy(&currentValue) }
        let key = try kuzuValueToSwift(&currentKey)
        let value = try kuzuValueToSwift(&currentValue)
        result.append((key, value))
    }

    return result
}

/// Converts a Swift array to a Kuzu list value.
/// - Parameter array: The Swift array to convert.
/// - Returns: A Kuzu list value.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
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

/// Converts a Kuzu list value to a Swift array.
/// - Parameter cValue: The Kuzu list value to convert.
/// - Returns: A Swift array containing the list elements.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func kuzuListToSwiftArray(_ cValue: inout kuzu_value) throws -> [Any?] {
    var numElements: UInt64 = 0
    var logicalType = kuzu_logical_type()
    kuzu_value_get_data_type(&cValue, &logicalType)

    defer { kuzu_data_type_destroy(&logicalType) }
    let logicalTypeId = kuzu_data_type_get_id(&logicalType)
    if logicalTypeId == KUZU_ARRAY {
        let state = kuzu_data_type_get_num_elements_in_array(
            &logicalType,
            &numElements
        )
        if state != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in array with status: \(state)"
            )
        }
    } else {
        let state = kuzu_value_get_list_size(&cValue, &numElements)
        if state != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get number of elements in list with status: \(state)"
            )
        }
    }
    var result: [Any?] = []
    var currentValue = kuzu_value()
    for i in UInt64(0)..<numElements {
        let state = kuzu_value_get_list_element(&cValue, i, &currentValue)
        if state != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get list element with status: \(state)"
            )
        }
        defer { kuzu_value_destroy(&currentValue) }
        let swiftValue = try kuzuValueToSwift(&currentValue)
        result.append(swiftValue)
    }
    return result
}

/// Converts a Swift dictionary to a Kuzu struct value.
/// - Parameter dictionary: The Swift dictionary to convert.
/// - Returns: A Kuzu struct value.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
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

/// Converts a Kuzu struct value to a Swift dictionary.
/// - Parameter cValue: The Kuzu struct value to convert.
/// - Returns: A Swift dictionary containing the struct fields.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func kuzuStructValueToSwiftDictionary(_ cValue: inout kuzu_value) throws
    -> [String: Any?]
{
    var dict: [String: Any?] = [:]
    var propertySize: UInt64 = 0
    kuzu_value_get_struct_num_fields(&cValue, &propertySize)
    var currentKey: UnsafeMutablePointer<CChar>?
    var currentValue = kuzu_value()
    for i in UInt64(0)..<propertySize {
        var state = kuzu_value_get_struct_field_name(&cValue, i, &currentKey)
        if state != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get struct field name with status: \(state)"
            )
        }
        defer {
            kuzu_destroy_string(currentKey)
        }
        let key = String(cString: currentKey!)
        state = kuzu_value_get_struct_field_value(&cValue, i, &currentValue)
        if state != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get struct field with status: \(state)"
            )
        }
        defer {
            kuzu_value_destroy(&currentValue)
        }
        let swiftValue = try kuzuValueToSwift(&currentValue)
        dict[key] = swiftValue
    }
    return dict
}

/// Converts a Kuzu union value to a Swift value.
/// - Parameter cValue: The Kuzu union value to convert.
/// - Returns: A Swift value.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func kuzuUnionValueToSwiftValue(_ cValue: inout kuzu_value) throws
    -> Any?
{
    var unionValue = kuzu_value()
    // Only one member in the union can be active at a time and that member is always stored
    // at index 0.
    let state = kuzu_value_get_struct_field_value(&cValue, 0, &unionValue)
    if state != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get union value with status: \(state)"
        )
    }
    defer { kuzu_value_destroy(&unionValue) }
    return try kuzuValueToSwift(&unionValue)
}

/// Converts a Kuzu node value to a Swift KuzuNode.
/// - Parameter cValue: The Kuzu node value to convert.
/// - Returns: A Swift KuzuNode.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func kuzuNodeValueToSwiftNode(_ cValue: inout kuzu_value) throws
    -> KuzuNode
{
    var idValue = kuzu_value()
    let idState = kuzu_node_val_get_id_val(&cValue, &idValue)
    if idState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get node ID with status: \(idState)"
        )
    }
    defer { kuzu_value_destroy(&idValue) }
    let id = try kuzuValueToSwift(&idValue) as! KuzuInternalId

    var labelValue = kuzu_value()
    let labelState = kuzu_node_val_get_label_val(&cValue, &labelValue)
    if labelState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get node label with status: \(labelState)"
        )
    }
    defer { kuzu_value_destroy(&labelValue) }
    let label = try kuzuValueToSwift(&labelValue) as! String

    var propertySize: UInt64 = 0
    let propertySizeState = kuzu_node_val_get_property_size(
        &cValue,
        &propertySize
    )
    if propertySizeState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get property size with status: \(propertySizeState)"
        )
    }

    var properties: [String: Any?] = [:]
    var currentKey: UnsafeMutablePointer<CChar>?
    var currentValue = kuzu_value()

    for i in UInt64(0)..<propertySize {
        let keyState = kuzu_node_val_get_property_name_at(
            &cValue,
            i,
            &currentKey
        )
        if keyState != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get property name with status: \(keyState)"
            )
        }
        defer { kuzu_destroy_string(currentKey) }
        let key = String(cString: currentKey!)

        let valueState = kuzu_node_val_get_property_value_at(
            &cValue,
            i,
            &currentValue
        )
        if valueState != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get property value with status: \(valueState)"
            )
        }
        defer { kuzu_value_destroy(&currentValue) }

        let value = try kuzuValueToSwift(&currentValue)
        properties[key] = value
    }

    return KuzuNode(id: id, label: label, properties: properties)
}

/// Converts a Kuzu relationship value to a Swift KuzuRelationship.
/// - Parameter cValue: The Kuzu relationship value to convert.
/// - Returns: A Swift KuzuRelationship.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func kuzuRelValueToSwiftRelationship(_ cValue: inout kuzu_value) throws
    -> KuzuRelationship
{
    var idValue = kuzu_value()
    
    let idState = kuzu_rel_val_get_id_val(&cValue, &idValue)
    if idState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get relationship ID with status: \(idState)"
        )
    }
    let id = try kuzuValueToSwift(&idValue) as! KuzuInternalId
    kuzu_value_destroy(&idValue)

    let srcState = kuzu_rel_val_get_src_id_val(&cValue, &idValue)
    if srcState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get relationship source ID with status: \(srcState)"
        )
    }
    let sourceId = try kuzuValueToSwift(&idValue) as! KuzuInternalId
    kuzu_value_destroy(&idValue)

    let dstState = kuzu_rel_val_get_dst_id_val(&cValue, &idValue)
    if dstState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get relationship target ID with status: \(dstState)"
        )
    }
    let targetId = try kuzuValueToSwift(&idValue) as! KuzuInternalId
    kuzu_value_destroy(&idValue)

    var labelValue = kuzu_value()
    let labelState = kuzu_rel_val_get_label_val(&cValue, &labelValue)
    if labelState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get relationship label with status: \(labelState)"
        )
    }
    let label = try kuzuValueToSwift(&labelValue) as! String

    kuzu_value_destroy(&labelValue)

    // Get Properties
    var propertySize: UInt64 = 0
    let propertySizeState = kuzu_rel_val_get_property_size(
        &cValue,
        &propertySize
    )
    if propertySizeState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get property size with status: \(propertySizeState)"
        )
    }

    var properties: [String: Any?] = [:]
    var currentKey: UnsafeMutablePointer<CChar>?
    var currentValue = kuzu_value()

    for i in UInt64(0)..<propertySize {
        let keyState = kuzu_rel_val_get_property_name_at(
            &cValue,
            i,
            &currentKey
        )
        if keyState != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get property name with status: \(keyState)"
            )
        }
        defer { kuzu_destroy_string(currentKey) }
        let key = String(cString: currentKey!)

        let valueState = kuzu_rel_val_get_property_value_at(
            &cValue,
            i,
            &currentValue
        )
        if valueState != KuzuSuccess {
            throw KuzuError.valueConversionFailed(
                "Failed to get property value with status: \(valueState)"
            )
        }
        defer { kuzu_value_destroy(&currentValue) }

        let value = try kuzuValueToSwift(&currentValue)
        properties[key] = value
    }

    return KuzuRelationship(
        id: id,
        sourceId: sourceId,
        targetId: targetId,
        label: label,
        properties: properties
    )
}

/// Converts a Kuzu recursive relationship value to a Swift KuzuRecursiveRelationship.
/// - Parameter cValue: The Kuzu recursive relationship value to convert.
/// - Returns: A Swift KuzuRecursiveRelationship.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
private func kuzuRecursiveRelValueToSwiftRecursiveRelationship(
    _ cValue: inout kuzu_value
) throws
    -> KuzuRecursiveRelationship
{
    var nodesValue = kuzu_value()
    let nodesState = kuzu_value_get_recursive_rel_node_list(
        &cValue,
        &nodesValue
    )
    if nodesState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get recursive relationship nodes with status: \(nodesState)"
        )
    }
    defer { kuzu_value_destroy(&nodesValue) }

    var relsValue = kuzu_value()
    let relsState = kuzu_value_get_recursive_rel_rel_list(&cValue, &relsValue)
    if relsState != KuzuSuccess {
        throw KuzuError.valueConversionFailed(
            "Failed to get recursive relationship relationships with status: \(relsState)"
        )
    }
    defer { kuzu_value_destroy(&relsValue) }

    let nodesArray = try kuzuListToSwiftArray(&nodesValue)
    let relsArray = try kuzuListToSwiftArray(&relsValue)

    var nodes: [KuzuNode] = []
    for node in nodesArray {
        guard let kuzuNode = node as? KuzuNode else {
            throw KuzuError.valueConversionFailed(
                "Failed to convert node to KuzuNode"
            )
        }
        nodes.append(kuzuNode)
    }

    var relationships: [KuzuRelationship] = []
    for rel in relsArray {
        guard let kuzuRel = rel as? KuzuRelationship else {
            throw KuzuError.valueConversionFailed(
                "Failed to convert relationship to KuzuRelationship"
            )
        }
        relationships.append(kuzuRel)
    }

    return KuzuRecursiveRelationship(nodes: nodes, relationships: relationships)
}

/// Converts a Swift value to a Kuzu value.
/// - Parameter value: The Swift value to convert.
/// - Returns: A Kuzu value.
/// - Throws: `KuzuError.valueConversionFailed` if the conversion fails.
internal func swiftValueToKuzuValue(_ value: Any?)
    throws -> UnsafeMutablePointer<kuzu_value>
{
    if value == nil {
        return kuzu_value_create_null()
    }
    var valuePtr: UnsafeMutablePointer<kuzu_value>
    let dtype = Mirror(reflecting: value!).subjectType
    if let number = value as? NSNumber {
        #if os(Linux)
            throw KuzuError.valueConversionFailed(
                "Native Swift numeric types cannot be resolved correctly on Linux. Please use the wrapper structs instead."
            )
        #else
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
            //        Internally Swift does not seem to really use these UInt
            //        type representations, so we use the `KuzuUIntWrapper`
            //        structs as a workaround.
            //        case "C":
            //            valuePtr = kuzu_value_create_uint8(number as! UInt8)
            //        case "I":
            //            valuePtr = kuzu_value_create_uint32(number as! UInt32)
            //        case "S":
            //            valuePtr = kuzu_value_create_uint16(number as! UInt16)
            //        case "L":
            //            valuePtr = kuzu_value_create_uint32(number as! UInt32)
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
        #endif
    } else {
        switch value! {
        case let kuzuUint64 as KuzuUInt64Wrapper:
            valuePtr = kuzu_value_create_uint64(UInt64(kuzuUint64.value))
        case let kuzuUint32 as KuzuUInt32Wrapper:
            valuePtr = kuzu_value_create_uint32(UInt32(kuzuUint32.value))
        case let kuzuUint16 as KuzuUInt16Wrapper:
            valuePtr = kuzu_value_create_uint16(UInt16(kuzuUint16.value))
        case let kuzuUint8 as KuzuUInt8Wrapper:
            valuePtr = kuzu_value_create_uint8(UInt8(kuzuUint8.value))
        case let kuzuInt64 as KuzuInt64Wrapper:
            valuePtr = kuzu_value_create_int64(Int64(kuzuInt64.value))
        case let kuzuInt32 as KuzuInt32Wrapper:
            valuePtr = kuzu_value_create_int32(Int32(kuzuInt32.value))
        case let kuzuInt16 as KuzuInt16Wrapper:
            valuePtr = kuzu_value_create_int16(Int16(kuzuInt16.value))
        case let kuzuInt8 as KuzuInt8Wrapper:
            valuePtr = kuzu_value_create_int8(Int8(kuzuInt8.value))
        case let kuzuFloat as KuzuFloatWrapper:
            valuePtr = kuzu_value_create_float(Float(kuzuFloat.value))
        case let kuzuDouble as KuzuDoubleWrapper:
            valuePtr = kuzu_value_create_double(Double(kuzuDouble.value))
        case let kuzuBool as KuzuBoolWrapper:
            valuePtr = kuzu_value_create_bool(kuzuBool.value)
        case let string as String:
            valuePtr = kuzu_value_create_string(string)
        case let date as Date:
            let timestamp = swiftDateToKuzuTimestamp(date)
            valuePtr = kuzu_value_create_timestamp(timestamp)
        case let timeInterval as TimeInterval:
            let interval = swiftTimeIntervalToKuzuInterval(timeInterval)
            valuePtr = kuzu_value_create_interval(interval)
        case let arrayOfMapItems as [(Any?, Any?)]:
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

/// Converts a Kuzu value to a Swift value.
/// - Parameter cValue: The Kuzu value to convert.
/// - Returns: A Swift value.
/// - Throws: `KuzuError.getValueFailed` if the conversion fails.
internal func kuzuValueToSwift(_ cValue: inout kuzu_value) throws -> Any? {
    if kuzu_value_is_null(&cValue) {
        return nil
    }
    var logicalType = kuzu_logical_type()
    kuzu_value_get_data_type(&cValue, &logicalType)
    defer { kuzu_data_type_destroy(&logicalType) }
    let logicalTypeId = kuzu_data_type_get_id(&logicalType)
    switch logicalTypeId {
    case KUZU_BOOL:
        var value: Bool = Bool()
        let state = kuzu_value_get_bool(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get bool value with status \(state)"
            )
        }
        return value
    case KUZU_INT64, KUZU_SERIAL:
        var value: Int64 = Int64()
        let state = kuzu_value_get_int64(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get int64 value with status \(state)"
            )
        }
        return value
    case KUZU_INT32:
        var value: Int32 = Int32()
        let state = kuzu_value_get_int32(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get int32 value with status \(state)"
            )
        }
        return value
    case KUZU_INT16:
        var value: Int16 = Int16()
        let state = kuzu_value_get_int16(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get int16 value with status \(state)"
            )
        }
        return value
    case KUZU_INT8:
        var value: Int8 = Int8()
        let state = kuzu_value_get_int8(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get int8 value with status \(state)"
            )
        }
        return value
    case KUZU_INT128:
        var int128Value = kuzu_int128_t()
        let getValueState = kuzu_value_get_int128(&cValue, &int128Value)
        if getValueState != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get int128 value with status \(getValueState)"
            )
        }
        var valueString: UnsafeMutablePointer<CChar>?
        let valueConversionState = kuzu_int128_t_to_string(
            int128Value,
            &valueString
        )
        if valueConversionState != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to convert int128 to string with status \(valueConversionState)"
            )
        }
        defer {
            kuzu_destroy_string(valueString)
        }
        let decimalString = String(cString: valueString!)
        let decimal = Decimal(string: decimalString)
        return decimal
    case KUZU_UUID:
        var valueString: UnsafeMutablePointer<CChar>?
        let state = kuzu_value_get_uuid(&cValue, &valueString)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get uuid value with status \(state)"
            )
        }
        defer {
            kuzu_destroy_string(valueString)
        }
        let uuidString = String(cString: valueString!)
        return UUID(uuidString: uuidString)!
    case KUZU_UINT64:
        var value: UInt64 = UInt64()
        let state = kuzu_value_get_uint64(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get uint64 value with status \(state)"
            )
        }
        return value
    case KUZU_UINT32:
        var value: UInt32 = UInt32()
        let state = kuzu_value_get_uint32(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get uint32 value with status \(state)"
            )
        }
        return value
    case KUZU_UINT16:
        var value: UInt16 = UInt16()
        let state = kuzu_value_get_uint16(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get uint16 value with status \(state)"
            )
        }
        return value
    case KUZU_UINT8:
        var value: UInt8 = UInt8()
        let state = kuzu_value_get_uint8(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get uint8 value with status \(state)"
            )
        }
        return value
    case KUZU_FLOAT:
        var value: Float = Float()
        let state = kuzu_value_get_float(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get float value with status \(state)"
            )
        }
        return value
    case KUZU_DOUBLE:
        var value: Double = Double()
        let state = kuzu_value_get_double(&cValue, &value)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get double value with status \(state)"
            )
        }
        return value
    case KUZU_STRING:
        var strValue: UnsafeMutablePointer<CChar>?
        let state = kuzu_value_get_string(&cValue, &strValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get string value with status \(state)"
            )
        }
        defer {
            kuzu_destroy_string(strValue)
        }
        return String(cString: strValue!)
    case KUZU_TIMESTAMP:
        var cTimestampValue = kuzu_timestamp_t()
        let state = kuzu_value_get_timestamp(&cValue, &cTimestampValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let microseconds = cTimestampValue.value
        let seconds: Double = Double(microseconds) / MICROSECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    case KUZU_TIMESTAMP_NS:
        var cTimestampValue = kuzu_timestamp_ns_t()
        let state = kuzu_value_get_timestamp_ns(&cValue, &cTimestampValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let nanoseconds = cTimestampValue.value
        let seconds: Double = Double(nanoseconds) / NANOSECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    case KUZU_TIMESTAMP_MS:
        var cTimestampValue = kuzu_timestamp_ms_t()
        let state = kuzu_value_get_timestamp_ms(&cValue, &cTimestampValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let milliseconds = cTimestampValue.value
        let seconds: Double = Double(milliseconds) / MILLISECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    case KUZU_TIMESTAMP_SEC:
        var cTimestampValue = kuzu_timestamp_sec_t()
        let state = kuzu_value_get_timestamp_sec(&cValue, &cTimestampValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let seconds = cTimestampValue.value
        return Date(timeIntervalSince1970: Double(seconds))
    case KUZU_TIMESTAMP_TZ:
        var cTimestampValue = kuzu_timestamp_tz_t()
        let state = kuzu_value_get_timestamp_tz(&cValue, &cTimestampValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get timestamp value with status \(state)"
            )
        }
        let microseconds = cTimestampValue.value
        let seconds: Double = Double(microseconds) / MICROSECONDS_IN_A_SECOND
        return Date(timeIntervalSince1970: seconds)
    case KUZU_DATE:
        var cDateValue = kuzu_date_t()
        let state = kuzu_value_get_date(&cValue, &cDateValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get date value with status \(state)"
            )
        }
        let days = cDateValue.days
        let seconds: Double = Double(days) * SECONDS_IN_A_DAY
        return Date(timeIntervalSince1970: seconds)
    case KUZU_INTERVAL:
        var cIntervalValue = kuzu_interval_t()
        let state = kuzu_value_get_interval(&cValue, &cIntervalValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get interval value with status \(state)"
            )
        }
        return kuzuIntervalToSwiftTimeInterval(cIntervalValue)
    case KUZU_INTERNAL_ID:
        var cInternalIdValue = kuzu_internal_id_t()
        let state = kuzu_value_get_internal_id(&cValue, &cInternalIdValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get internal id value with status \(state)"
            )
        }
        return KuzuInternalId(
            tableId: cInternalIdValue.table_id,
            offset: cInternalIdValue.offset
        )
    case KUZU_BLOB:
        var cBlobValue: UnsafeMutablePointer<UInt8>?
        let state = kuzu_value_get_blob(&cValue, &cBlobValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get blob value with status \(state)"
            )
        }
        defer {
            kuzu_destroy_blob(cBlobValue)
        }
        let blobSize = strlen(cBlobValue!)
        let blobData = Data(bytes: cBlobValue!, count: blobSize)
        return blobData
    case KUZU_DECIMAL:
        var outString: UnsafeMutablePointer<CChar>?
        let state = kuzu_value_get_decimal_as_string(&cValue, &outString)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Failed to get string value of decimal type with status: \(state)"
            )
        }
        defer {
            kuzu_destroy_string(outString)
        }
        let decimalString = String(cString: outString!)
        guard let decimal = Decimal(string: decimalString) else {
            throw KuzuError.valueConversionFailed(
                "Failed to convert decimal value from string: \(decimalString)"
            )
        }
        return decimal
    case KUZU_LIST, KUZU_ARRAY:
        return try kuzuListToSwiftArray(&cValue)
    case KUZU_STRUCT:
        return try kuzuStructValueToSwiftDictionary(&cValue)
    case KUZU_UNION:
        return try kuzuUnionValueToSwiftValue(&cValue)
    case KUZU_MAP:
        return try kuzuMapToSwiftArrayOfMapItems(&cValue)
    case KUZU_NODE:
        return try kuzuNodeValueToSwiftNode(&cValue)
    case KUZU_REL:
        return try kuzuRelValueToSwiftRelationship(&cValue)
    case KUZU_RECURSIVE_REL:
        return try kuzuRecursiveRelValueToSwiftRecursiveRelationship(&cValue)
    default:
        let valueString = kuzu_value_to_string(&cValue)
        defer { kuzu_destroy_string(valueString) }
        throw KuzuError.valueConversionFailed(
            "Unsupported C value with value \(String(cString: valueString!)) and typeId \(logicalTypeId)"
        )
    }
}
