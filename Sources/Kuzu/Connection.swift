//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

@_implementationOnly import cxx_kuzu

public final class Connection {
    internal var cConnection: kuzu_connection

    public init(_ database: Database) throws {
        cConnection = kuzu_connection()
        let state = kuzu_connection_init(&database.cDatabase, &self.cConnection)
        if state != KuzuSuccess {
            throw KuzuError.connectionInitializationFailed(
                "Connection initialization failed with error code: \(state)"
            )
        }
    }

    deinit {
        kuzu_connection_destroy(&cConnection)
    }

    public func query(_ cypher: String) throws -> QueryResult {
        var cQueryResult = kuzu_query_result()
        kuzu_connection_query(&cConnection, cypher, &cQueryResult)
        if !kuzu_query_result_is_success(&cQueryResult) {
            let cErrorMesage: UnsafeMutablePointer<CChar>? =
                kuzu_query_result_get_error_message(&cQueryResult)
            defer {
                kuzu_query_result_destroy(&cQueryResult)
                kuzu_destroy_string(cErrorMesage)
            }
            if cErrorMesage == nil {
                throw KuzuError.queryExecutionFailed(
                    "Query execution failed with an unknown error."
                )
            } else {
                let errorMessage = String(cString: cErrorMesage!)
                throw KuzuError.queryExecutionFailed(errorMessage)
            }
        }
        let queryResult = QueryResult(self, cQueryResult)
        return queryResult
    }

    public func prepare(_ cypher: String) throws -> PreparedStatement {
        var cPreparedStatement = kuzu_prepared_statement()
        kuzu_connection_prepare(&cConnection, cypher, &cPreparedStatement)
        if !kuzu_prepared_statement_is_success(&cPreparedStatement) {
            let cErrorMesage: UnsafeMutablePointer<CChar>? =
                kuzu_prepared_statement_get_error_message(&cPreparedStatement)
            defer {
                kuzu_destroy_string(cErrorMesage)
                kuzu_prepared_statement_destroy(&cPreparedStatement)
            }
            if cErrorMesage == nil {
                throw KuzuError.prepareStatmentFailed(
                    "Prepare statement failed with an unknown error."
                )
            } else {
                let errorMessage = String(cString: cErrorMesage!)
                throw KuzuError.prepareStatmentFailed(errorMessage)
            }
        }
        let preparedStatement = PreparedStatement(self, cPreparedStatement)
        return preparedStatement
    }

    public func execute<T>(
        _ preparedStatement: PreparedStatement,
        _ parameters: [String: T?]
    ) throws -> QueryResult {
        var cQueryResult = kuzu_query_result()
        for (key, value) in parameters {
            let cValue = try swiftValueToKuzuValue(value)
            defer {
                kuzu_value_destroy(cValue)
            }
            let state = kuzu_prepared_statement_bind_value(
                &preparedStatement.cPreparedStatement,
                key,
                cValue
            )
            if state != KuzuSuccess {
                throw KuzuError.queryExecutionFailed(
                    "Failed to bind value with status \(state)"
                )
            }
        }
        kuzu_connection_execute(
            &cConnection,
            &preparedStatement.cPreparedStatement,
            &cQueryResult
        )
        if !kuzu_query_result_is_success(&cQueryResult) {
            let cErrorMesage: UnsafeMutablePointer<CChar>? =
                kuzu_query_result_get_error_message(&cQueryResult)
            defer {
                kuzu_query_result_destroy(&cQueryResult)
                kuzu_destroy_string(cErrorMesage)
            }
            if cErrorMesage == nil {
                throw KuzuError.queryExecutionFailed(
                    "Query execution failed with an unknown error."
                )
            } else {
                let errorMessage = String(cString: cErrorMesage!)
                throw KuzuError.queryExecutionFailed(errorMessage)
            }
        }
        let queryResult = QueryResult(self, cQueryResult)
        return queryResult
    }

    public func setMaxNumThreadForExec(_ numThreads: UInt64) {
        kuzu_connection_set_max_num_thread_for_exec(&cConnection, numThreads)
    }

    public func getMaxNumThreadForExec() -> UInt64 {
        var numThreads = UInt64()
        kuzu_connection_get_max_num_thread_for_exec(&cConnection, &numThreads)
        return numThreads
    }

    public func setQueryTimeout(_ milliseconds: UInt64) {
        kuzu_connection_set_query_timeout(&cConnection, milliseconds)
    }

    public func interrupt() {
        kuzu_connection_interrupt(&cConnection)
    }
}
