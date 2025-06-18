//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

/// A class representing the result of a query, which can be used to iterate over the result set.
/// QueryResult is returned by the `query` and `execute` methods of Connection.
/// It conforms to `CustomStringConvertible` and `Sequence` protocols for easy string representation and iteration.
public final class QueryResult: CustomStringConvertible, Sequence, @unchecked
    Sendable
{
    internal var cQueryResult: kuzu_query_result
    internal var connection: Connection
    internal var columnNames: [String]?

    /// An iterator type for QueryResult that conforms to IteratorProtocol.
    public struct Iterator: IteratorProtocol {
        private let queryResult: QueryResult

        init(_ queryResult: QueryResult) {
            self.queryResult = queryResult
        }

        /// Returns the next tuple in the result set, or nil if there are no more tuples.
        public mutating func next() -> FlatTuple? {
            do {
                return try queryResult.getNext()
            } catch {
                return nil
            }
        }
    }

    /// Creates an iterator for iterating over the result set.
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }

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

    /// Returns the string representation of the QueryResult.
    /// The string representation contains the column names and the tuples in the result set.
    public var description: String {
        let cString: UnsafeMutablePointer<CChar> = kuzu_query_result_to_string(
            &cQueryResult
        )
        defer { free(UnsafeMutableRawPointer(mutating: cString)) }
        return String(cString: cString)
    }

    /// Returns true if there is at least one more tuple in the result set.
    public func hasNext() -> Bool {
        return kuzu_query_result_has_next(&cQueryResult)
    }

    /// Returns the next tuple in the result set.
    /// - Returns: The next tuple, or nil if there are no more tuples.
    /// - Throws: `KuzuError.getFlatTupleFailed` if retrieving the next tuple fails.
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

    /// Returns true if not all query results are consumed when multiple query statements are executed.
    public func hasNextQueryResult() -> Bool {
        return kuzu_query_result_has_next_query_result(&cQueryResult)
    }

    /// Returns the next query result when multiple query statements are executed.
    /// - Returns: The next query result, or nil if there are no more results.
    /// - Throws: `KuzuError.getNextQueryResultFailed` if retrieving the next query result fails.
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

    /// Resets the iterator of the QueryResult. After calling this method, the `getNext`
    /// method can be called to iterate over the result set from the beginning.
    public func resetIterator() {
        kuzu_query_result_reset_iterator(&cQueryResult)
    }

    /// Returns the column names of the QueryResult as an array of strings.
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

    /// Returns the number of columns in the QueryResult.
    public func getColumnCount() -> UInt64 {
        return kuzu_query_result_get_num_columns(&cQueryResult)
    }

    /// Returns the number of rows in the QueryResult.
    public func getRowCount() -> UInt64 {
        return kuzu_query_result_get_num_tuples(&cQueryResult)
    }

    /// Returns the compiling time of the query in milliseconds.
    public func getCompilingTime() -> Double {
        var cQuerySummary = kuzu_query_summary()
        defer {
            kuzu_query_summary_destroy(&cQuerySummary)
        }
        kuzu_query_result_get_query_summary(&cQueryResult, &cQuerySummary)
        return kuzu_query_summary_get_compiling_time(&cQuerySummary)
    }

    /// Returns the execution time of the query in milliseconds.
    public func getExecutionTime() -> Double {
        var cQuerySummary = kuzu_query_summary()
        defer {
            kuzu_query_summary_destroy(&cQuerySummary)
        }
        kuzu_query_result_get_query_summary(&cQueryResult, &cQuerySummary)
        return kuzu_query_summary_get_execution_time(&cQuerySummary)
    }
}
