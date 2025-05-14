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

    public func query(_ cypher: String) -> QueryResult {
        var cQueryResult = kuzu_query_result()
        kuzu_connection_query(&cConnection, cypher, &cQueryResult)
        let queryResult = QueryResult(self, cQueryResult)
        return queryResult
    }

    deinit {
        kuzu_connection_destroy(&cConnection)
    }
}
