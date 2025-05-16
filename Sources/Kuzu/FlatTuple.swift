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
}
