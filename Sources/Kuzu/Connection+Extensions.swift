//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import cxx_kuzu

@_spi(Typed)
extension Connection {
    public func execute_(
        _ preparedStatement: PreparedStatement,
        _ parameters: [String: any KuzuEncodable]
    ) throws -> QueryResult {
        var cQueryResult = kuzu_query_result()
        for (key, value) in parameters {
            let kuzuValue = try value.kuzuValue()
            let state = kuzu_prepared_statement_bind_value(
                &preparedStatement.cPreparedStatement,
                key,
                kuzuValue.ptr
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
}
