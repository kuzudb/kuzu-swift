//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

/// Errors that can occur during Kuzu operations.
enum KuzuError: Error {
    /// Database initialization failed with the given error message.
    case databaseInitializationFailed(String)
    /// Connection initialization failed with the given error message.
    case connectionInitializationFailed(String)
    /// Query execution failed with the given error message.
    case queryExecutionFailed(String)
    /// Statement preparation failed with the given error message.
    case prepareStatmentFailed(String)
    /// Value conversion failed with the given error message.
    case valueConversionFailed(String)
    /// Failed to get a flat tuple with the given error message.
    case getFlatTupleFailed(String)
    /// Failed to get the next query result with the given error message.
    case getNextQueryResultFailed(String)
    /// Failed to get a value with the given error message.
    case getValueFailed(String)
    /// The error message.
    /// - Returns: The error message.
    var message: String {
        switch self {
        case .databaseInitializationFailed(let msg),
             .connectionInitializationFailed(let msg),
             .queryExecutionFailed(let msg),
             .prepareStatmentFailed(let msg),
             .valueConversionFailed(let msg),
             .getFlatTupleFailed(let msg),
             .getNextQueryResultFailed(let msg),
             .getValueFailed(let msg):
            return msg
        }
    }
}

/// Represents the internal ID of a node or relationship in Kuzu.
/// It conforms to the Equatable protocol for easy comparison.
struct KuzuInternalId : Equatable{
    /// The table ID of the node or relationship.
    let tableId: UInt64
    /// The offset within the table.
    let offset: UInt64

    /// Compares two KuzuInternalId instances for equality.
    /// - Parameters:
    ///   - lhs: The first KuzuInternalId to compare.
    ///   - rhs: The second KuzuInternalId to compare.
    /// - Returns: True if the two KuzuInternalId instances are equal, false otherwise.
    static func == (lhs: KuzuInternalId, rhs: KuzuInternalId) -> Bool {
        return lhs.tableId == rhs.tableId && lhs.offset == rhs.offset
    }
}

/// Represents a node retrieved from Kuzu.
/// A node has an ID, a label, and properties.
struct KuzuNode {
    /// The internal ID of the node.
    let id: KuzuInternalId
    /// The label of the node.
    let label: String
    /// The properties of the node, where keys are property names and values are property values.
    let properties: [String: Any?]
}

/// Represents a relationship retrieved from Kuzu.
/// A relationship has a source ID, a destination ID, a label, and properties.
struct KuzuRelationship {
    /// The internal ID of the source node.
    let sourceId: KuzuInternalId
    /// The internal ID of the target node.
    let targetId: KuzuInternalId
    /// The label of the relationship.
    let label: String
    /// The properties of the relationship, where keys are property names and values are property values.
    let properties: [String: Any?]
}

/// Represents a recursive relationship retrieved from a path query in Kuzu.
/// A recursive relationship has a list of nodes and a list of relationships.
struct KuzuRecursiveRelationship {
    /// The list of nodes in the recursive relationship.
    let nodes: [KuzuNode]
    /// The list of relationships in the recursive relationship.
    let relationships: [KuzuRelationship]
}

/// A wrapper for UInt32 values to be passed as parameters to Kuzu.
/// The native Swift type UInt32 cannot be distinguished from Int64 because
/// the underlying NSNumber type is the same for both types (type 'q').
struct KuzuUInt32Wrapper: Codable {
    let value: UInt32
}

/// A wrapper for UInt16 values to be passed as parameters to Kuzu.
/// The native Swift type UInt16 cannot be distinguished from Int32 because
/// the underlying NSNumber type is the same for both types (type 'i').
struct KuzuUInt16Wrapper: Codable {
    let value: UInt16
}

/// A wrapper for UInt8 values to be passed as parameters to Kuzu.
/// The native Swift type UInt8 cannot be distinguished from Int16 because
/// the underlying NSNumber type is the same for both types (type 's').
struct KuzuUInt8Wrapper: Codable {
    let value: UInt8
}

/// A wrapper for UInt64 values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuUInt64Wrapper: Codable {
    let value: UInt64
}

/// A wrapper for Int64 values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuInt64Wrapper: Codable {
    let value: Int64
}

/// A wrapper for Int32 values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuInt32Wrapper: Codable {
    let value: Int32
}

/// A wrapper for Int16 values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuInt16Wrapper: Codable {
    let value: Int16
}

/// A wrapper for Int8 values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuInt8Wrapper: Codable {
    let value: Int8
}

/// A wrapper for Float values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuFloatWrapper: Codable {
    let value: Float
}

/// A wrapper for Double values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuDoubleWrapper: Codable {
    let value: Double
}

/// A wrapper for Bool values to be passed as parameters to Kuzu.
/// Using this wrapper is optional on macOS/iOS, because CoreFoundation
/// framework can automatically detect the type of the underlying NSNumber.
/// However, it is required on Linux, because CoreFoundation is not available.
struct KuzuBoolWrapper: Codable {
    let value: Bool
}
