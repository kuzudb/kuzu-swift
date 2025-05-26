//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

public final class FlatTuple: CustomStringConvertible {
    internal var cFlatTuple: kuzu_flat_tuple
    internal var queryResult: QueryResult

    internal init(
        _ queryResult: QueryResult,
        _ cFlatTuple: kuzu_flat_tuple
    ) {
        self.cFlatTuple = cFlatTuple
        self.queryResult = queryResult
    }

    deinit {
        kuzu_flat_tuple_destroy(&cFlatTuple)
    }

    public var description: String {
        let cString: UnsafeMutablePointer<CChar> = kuzu_flat_tuple_to_string(
            &cFlatTuple
        )
        defer { free(UnsafeMutableRawPointer(mutating: cString)) }
        return String(cString: cString)

    }

    public func getValue(_ index: UInt64) throws -> Any? {
        var cValue = kuzu_value()
        let state = kuzu_flat_tuple_get_value(&cFlatTuple, index, &cValue)
        if state != KuzuSuccess {
            throw KuzuError.getValueFailed(
                "Get value failed with error code: \(state)"
            )
        }
        defer { kuzu_value_destroy(&cValue) }
        return try kuzuValueToSwift(&cValue)
    }

    public func getAsDictionary() throws -> [String: Any?] {
        var result: [String: Any] = [:]
        let keys = queryResult.getColumnNames()
        for i in 0..<keys.count {
            let key = keys[i]
            let value = try getValue(UInt64(i))
            result[key] = value
        }
        return result
    }

    public func getAsArray() throws -> [Any?] {
        var result: [Any?] = []
        let count = queryResult.getColumnCount()
        for i in UInt64(0)..<count {
            let value = try getValue(i)
            result.append(value)
        }
        return result
    }
}
