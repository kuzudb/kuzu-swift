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

@_spi(Typed)
public struct KuzuValue: ~Copyable {
    let ptr: UnsafeMutablePointer<kuzu_value>
    
    init(ptr: UnsafeMutablePointer<kuzu_value>) {
        self.ptr = ptr
    }

    static func null() -> KuzuValue {
        KuzuValue(ptr: kuzu_value_create_null())
    }

    deinit {
        kuzu_value_destroy(ptr)
    }
}

struct LogicalType: ~Copyable {
    let ptr: UnsafeMutablePointer<kuzu_logical_type>
    
    init(from value: borrowing KuzuValue) {
        ptr = .allocate(capacity: 1)
        ptr.initialize(to: kuzu_logical_type())
        kuzu_value_get_data_type(value.ptr, ptr)
    }
    
    var id: KuzuDataType {
        .init(id: kuzu_data_type_get_id(ptr))
    }
    
    deinit {
        kuzu_data_type_destroy(ptr)
        ptr.deinitialize(count: 1)
        ptr.deallocate()
    }
}

@_spi(Typed)
public struct KuzuInterval {
    public let months: Int32
    public let days: Int32
    public let micros: Int64
}

extension KuzuInterval {
    public init(_ timeInterval: TimeInterval) {
        self.init(
            months: 0,
            days: 0,
            micros: Int64(timeInterval * MICROSECONDS_IN_A_SECOND)
        )
    }
}

@_spi(Typed)
public struct KuzuNode_ {
    /// The internal ID of the node.
    public let id: KuzuInternalId
    /// The label of the node.
    public let label: String
    /// The properties of the node, where keys are property names and values are property values.
    public let properties: [String: any KuzuDecodable]
}

@_spi(Typed)
public struct KuzuRelationship_ {
    /// The internal ID of the relationship
    public let id: KuzuInternalId
    /// The internal ID of the source node.
    public let sourceId: KuzuInternalId
    /// The internal ID of the target node.
    public let targetId: KuzuInternalId
    /// The label of the relationship.
    public let label: String
    /// The properties of the relationship, where keys are property names and values are property values.
    public let properties: [String: any KuzuDecodable]
}

/// Represents a recursive relationship retrieved from a path query in Kuzu.
/// A recursive relationship has a list of nodes and a list of relationships.
@_spi(Typed)
public struct KuzuRecursiveRelationship_ {
    /// The list of nodes in the recursive relationship.
    public let nodes: [KuzuNode_]
    /// The list of relationships in the recursive relationship.
    public let relationships: [KuzuRelationship_]
}

// Tuples cannot conform to protocols so we need this wrapper
@_spi(Typed)
public struct KuzuMap<Key, Value> {
    public let tuples: [(Key, Value)]
    
    public init(_ tuples: [(Key, Value)]) {
        self.tuples = tuples
    }
    
    subscript(idx: Int) -> (Key, Value) {
        tuples[idx]
    }
}

@_spi(Typed)
public struct KuzuDataType: Equatable, Sendable {
    let id: kuzu_data_type_id
    
    public static let bool = KuzuDataType(id: KUZU_BOOL)
    public static let serial = KuzuDataType(id: KUZU_SERIAL)
    public static let int128 = KuzuDataType(id: KUZU_INT128)
    public static let int64 = KuzuDataType(id: KUZU_INT64)
    public static let uint64 = KuzuDataType(id: KUZU_UINT64)
    public static let int32 = KuzuDataType(id: KUZU_INT32)
    public static let uint32 = KuzuDataType(id: KUZU_UINT32)
    public static let int16 = KuzuDataType(id: KUZU_INT16)
    public static let uint16 = KuzuDataType(id: KUZU_UINT16)
    public static let int8 = KuzuDataType(id: KUZU_INT8)
    public static let uint8 = KuzuDataType(id: KUZU_UINT8)
    public static let float = KuzuDataType(id: KUZU_FLOAT)
    public static let double = KuzuDataType(id: KUZU_DOUBLE)
    public static let interval = KuzuDataType(id: KUZU_INTERVAL)
    public static let string = KuzuDataType(id: KUZU_STRING)
    public static let uuid = KuzuDataType(id: KUZU_UUID)
    public static let date = KuzuDataType(id: KUZU_DATE)
    public static let timestamp = KuzuDataType(id: KUZU_TIMESTAMP)
    public static let timestampSec = KuzuDataType(id: KUZU_TIMESTAMP_SEC)
    public static let timestampNs = KuzuDataType(id: KUZU_TIMESTAMP_NS)
    public static let timestampMs = KuzuDataType(id: KUZU_TIMESTAMP_MS)
    public static let timestampTz = KuzuDataType(id: KUZU_TIMESTAMP_TZ)
    public static let decimal = KuzuDataType(id: KUZU_DECIMAL)
    public static let internalId = KuzuDataType(id: KUZU_INTERNAL_ID)
    public static let blob = KuzuDataType(id: KUZU_BLOB)
    public static let list = KuzuDataType(id: KUZU_LIST)
    public static let array = KuzuDataType(id: KUZU_ARRAY)
    public static let map = KuzuDataType(id: KUZU_MAP)
    public static let `struct` = KuzuDataType(id: KUZU_STRUCT)
    public static let node = KuzuDataType(id: KUZU_NODE)
    public static let rel = KuzuDataType(id: KUZU_REL)
    public static let recursiveRel = KuzuDataType(id: KUZU_RECURSIVE_REL)
    public static let union = KuzuDataType(id: KUZU_UNION)
    public static let any = KuzuDataType(id: KUZU_ANY)
    
    func decode(from container: consuming KuzuValue) throws -> any KuzuDecodable {
        switch self {
        case .bool: try Bool.kuzuDecode(from: container)
        case .serial, .int64: try Int64.kuzuDecode(from: container)
        case .int64: try Int64.kuzuDecode(from: container)
        case .uint64: try UInt64.kuzuDecode(from: container)
        case .int32: try Int32.kuzuDecode(from: container)
        case .uint32: try UInt32.kuzuDecode(from: container)
        case .int16: try Int16.kuzuDecode(from: container)
        case .uint16: try UInt16.kuzuDecode(from: container)
        case .int8: try Int8.kuzuDecode(from: container)
        case .uint8: try UInt8.kuzuDecode(from: container)
        case .float: try Float.kuzuDecode(from: container)
        case .double: try Double.kuzuDecode(from: container)
        case .interval: try KuzuInterval.kuzuDecode(from: container)
        case .string: try String.kuzuDecode(from: container)
        case .uuid: try UUID.kuzuDecode(from: container)
        case .date, .timestamp, .timestampSec, .timestampNs, .timestampMs, .timestampTz: try Date.kuzuDecode(from: container)
        case .decimal, .int128: try Decimal.kuzuDecode(from: container)
        case .internalId: try KuzuInternalId.kuzuDecode(from: container)
        case .blob: try Data.kuzuDecode(from: container)
        case .list, .array: try Array<KuzuAnyDecodable>.kuzuDecode(from: container)
        case .map: try Dictionary<String, KuzuAnyDecodable>.kuzuDecode(from: container)
        case .struct:try Dictionary<String, KuzuAnyDecodable>.kuzuDecode(from: container)
        case .node: try KuzuNode_.kuzuDecode(from: container)
        case .rel: try KuzuRelationship_.kuzuDecode(from: container)
        case .recursiveRel: try KuzuRecursiveRelationship_.kuzuDecode(from: container)
        case .union: try KuzuAnyDecodable.kuzuUnion(from: container)
        default:
            throw KuzuError.valueConversionFailed("Unsupported type: \(self)")
        }
    }
}
