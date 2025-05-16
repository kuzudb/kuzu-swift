//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

public final class Database {
    internal var cDatabase: kuzu_database

    public init(
        _ databasePath: String = ":memory:",
        _ systemConfig: SystemConfig? = nil
    ) throws {
        cDatabase = kuzu_database()
        let cSystemConfg =
            systemConfig?.cSystemConfig ?? kuzu_default_system_config()
        let state = kuzu_database_init(
            databasePath,
            cSystemConfg,
            &self.cDatabase
        )
        if state == KuzuSuccess {
            return
        } else {
            throw KuzuError.databaseInitializationFailed(
                "Database initialization failed with error code: \(state)"
            )
        }
    }

    deinit {
        kuzu_database_destroy(&self.cDatabase)
    }
}
