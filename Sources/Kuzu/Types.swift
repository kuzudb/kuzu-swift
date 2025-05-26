//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

enum KuzuError: Error {
    case databaseInitializationFailed(String)
    case connectionInitializationFailed(String)
    case queryExecutionFailed(String)
    case prepareStatmentFailed(String)
    case valueConversionFailed(String)
    case getFlatTupleFailed(String)
    case getNextQueryResultFailed(String)
    case getValueFailed(String)
}

struct KuzuInternalId {
    let tableId: UInt64
    let offset: UInt64
}

struct KuzuNode {
    let id: KuzuInternalId
    let label: String
    let properties: [String: Any?]
}

struct KuzuRelationship {
    let sourceId: KuzuInternalId
    let targetId: KuzuInternalId
    let label: String
    let properties: [String: Any?]
}

struct KuzuRecursiveRelationship {
    let nodes: [KuzuNode]
    let relationships: [KuzuRelationship]
}
