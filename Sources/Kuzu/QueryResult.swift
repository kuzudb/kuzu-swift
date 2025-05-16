//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

public final class QueryResult: CustomStringConvertible {
    internal var cQueryResult: kuzu_query_result
    internal var connection: Connection

    internal init(
        _ connection: Connection,
        _ cQueryResult: kuzu_query_result
    ) {
        self.cQueryResult = cQueryResult
        self.connection = connection
    }

    deinit {
        kuzu_query_result_destroy(&cQueryResult)
    }

    public var description: String {
        let cString: UnsafeMutablePointer<CChar> = kuzu_query_result_to_string(
            &cQueryResult
        )
        defer { free(UnsafeMutableRawPointer(mutating: cString)) }
        return String(cString: cString)

    }

    public func hasNext() -> Bool {
        return kuzu_query_result_has_next(&cQueryResult)
    }
    
    public func getNext() throws -> FlatTuple  {
        var cFlatTuple: kuzu_flat_tuple = kuzu_flat_tuple()
        let state = kuzu_query_result_get_next(&cQueryResult, &cFlatTuple)
        if state != KuzuSuccess {
            throw KuzuError.getFlatTupleFailed("Get next failed with error code: \(state)")
        }
        return FlatTuple(self, cFlatTuple)
    }

}
