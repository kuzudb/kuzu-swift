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

    public func query(_ cypher: String) -> QueryResult {
        var cQueryResult = kuzu_query_result()
        kuzu_connection_query(&cConnection, cypher, &cQueryResult)
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
