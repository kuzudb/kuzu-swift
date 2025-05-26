//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

@_implementationOnly import cxx_kuzu

public final class PreparedStatement {
    internal var cPreparedStatement: kuzu_prepared_statement
    internal var connection: Connection
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
