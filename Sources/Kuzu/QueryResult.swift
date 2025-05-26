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
    internal var columnNames: [String]?

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

    public func getNext() throws -> FlatTuple? {
        if !self.hasNext() {
            return nil
        }
        var cFlatTuple: kuzu_flat_tuple = kuzu_flat_tuple()
        let state = kuzu_query_result_get_next(&cQueryResult, &cFlatTuple)
        if state != KuzuSuccess {
            throw KuzuError.getFlatTupleFailed(
                "Get next failed with error code: \(state)"
            )
        }
        return FlatTuple(self, cFlatTuple)
    }

    public func hasNextQueryResult() -> Bool {
        return kuzu_query_result_has_next_query_result(&cQueryResult)
    }

    public func getNextQueryResult() throws -> QueryResult? {
        if !self.hasNextQueryResult() {
            return nil
        }
        var cNextQueryResult = kuzu_query_result()
        let state = kuzu_query_result_get_next_query_result(
            &cQueryResult,
            &cNextQueryResult
        )
        if state != KuzuSuccess {
            throw KuzuError.getNextQueryResultFailed(
                "Get next query result failed with error code: \(state)"
            )
        }
        return QueryResult(self.connection, cNextQueryResult)
    }

    public func resetIterator() {
        kuzu_query_result_reset_iterator(&cQueryResult)
    }

    public func getColumnNames() -> [String] {
        if let columnNames = self.columnNames {
            return columnNames
        }

        let numColumns = self.getColumnCount()
        columnNames = []
        for i in UInt64(0)..<numColumns {
            var outputString: UnsafeMutablePointer<CChar>?
            kuzu_query_result_get_column_name(&cQueryResult, i, &outputString)
            defer { kuzu_destroy_string(outputString) }
            let columnName = String(cString: outputString!)
            columnNames?.append(columnName)
        }
        return columnNames!
    }

    public func getColumnCount() -> UInt64 {
        return kuzu_query_result_get_num_columns(&cQueryResult)
    }

    public func getRowCount() -> UInt64 {
        return kuzu_query_result_get_num_tuples(&cQueryResult)
    }

    public func getCompilingTime() -> Double {
        var cQuerySummary = kuzu_query_summary()
        defer {
            kuzu_query_summary_destroy(&cQuerySummary)
        }
        kuzu_query_result_get_query_summary(&cQueryResult, &cQuerySummary)
        return kuzu_query_summary_get_compiling_time(&cQuerySummary)
    }

    public func getExecutionTime() -> Double {
        var cQuerySummary = kuzu_query_summary()
        defer {
            kuzu_query_summary_destroy(&cQuerySummary)
        }
        kuzu_query_result_get_query_summary(&cQueryResult, &cQuerySummary)
        return kuzu_query_summary_get_execution_time(&cQuerySummary)
    }
}
