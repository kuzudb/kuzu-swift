//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

@_implementationOnly import cxx_kuzu

/// A class representing a prepared statement in Kuzu.
/// PreparedStatement can be used to execute a query with parameters.
/// It is returned by the `prepare` method of Connection.
public final class PreparedStatement : @unchecked Sendable{
    internal var cPreparedStatement: kuzu_prepared_statement
    internal var connection: Connection
    
    /// Initializes a new PreparedStatement instance.
    /// - Parameters:
    ///   - connection: The connection associated with this prepared statement.
    ///   - cPreparedStatement: The underlying C prepared statement.
    internal init(
        _ connection: Connection,
        _ cPreparedStatement: kuzu_prepared_statement
    ) {
        self.cPreparedStatement = cPreparedStatement
        self.connection = connection
    }

    deinit {
        kuzu_prepared_statement_destroy(&cPreparedStatement)
    }
}
