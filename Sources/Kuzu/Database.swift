//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

/// A class representing a Kuzu database instance.
public final class Database: @unchecked Sendable {
    internal var cDatabase: kuzu_database

    /// Initializes a new Kuzu database instance.
    /// - Parameters:
    ///   - databasePath: The path to the database. Defaults to ":memory:" for in-memory database.
    ///   - systemConfig: Optional configuration for the database system. If nil, default configuration will be used.
    /// - Throws: `KuzuError.databaseInitializationFailed` if the database initialization fails.
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

    /// The version of the Kuzu library as a string.
    ///
    /// This property returns the version of the underlying Kuzu library.
    /// Useful for debugging and ensuring compatibility.
    public static var version: String {
        let resultCString = kuzu_get_version()
        defer { kuzu_destroy_string(resultCString) }
        return String(cString: resultCString!)
    }

    /// The storage version of the Kuzu library as an unsigned 64-bit integer.
    ///
    /// This property returns the storage format version used by the Kuzu library.
    /// It can be used to check compatibility of database files.
    public static var storageVersion: UInt64 {
        let storageVersion = kuzu_get_storage_version()
        return storageVersion
    }

    deinit {
        kuzu_database_destroy(&self.cDatabase)
    }
}
