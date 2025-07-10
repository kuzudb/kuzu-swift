//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)
import Foundation
import XCTest

@testable import Kuzu

final class DatabaseTests: XCTestCase {
    func testOpenDatabaseWithDefaultConfig() throws {
        let dbPath =
            NSTemporaryDirectory() + "kuzu_swift_test_db_" + UUID().uuidString
        _ = try Database(dbPath)
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testOpenDatabaseWithCustomConfig() throws {
        let dbPath =
            NSTemporaryDirectory() + "kuzu_swift_test_db_" + UUID().uuidString
        let systemConfig = SystemConfig(
            bufferPoolSize: 16 * 1024 * 1024,
            maxNumThreads: 1,
            enableCompression: false,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: 0
        )
        _ = try Database(dbPath, systemConfig)
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testOpenDatabaseInMemory() throws {
        let db = try Database()

        let conn = try Connection(db)

        _ = try conn.query(
            "CREATE NODE TABLE person(name STRING, age INT64, PRIMARY KEY(name));"
        )
        _ = try conn.query("CREATE (:person {name: 'Alice', age: 30});")
        _ = try conn.query("CREATE (:person {name: 'Bob', age: 40});")

        let result = try conn.query("MATCH (a:person) RETURN a.name, a.age;")
        XCTAssertTrue(result.hasNext())

        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0] as! String, "Alice")
        XCTAssertEqual(values[1] as! Int64, 30)

        XCTAssertTrue(result.hasNext())
        let tuple2 = try result.getNext()!
        let values2 = try tuple2.getAsArray()
        XCTAssertEqual(values2.count, 2)
        XCTAssertEqual(values2[0] as! String, "Bob")
        XCTAssertEqual(values2[1] as! Int64, 40)

        XCTAssertFalse(result.hasNext())
    }
    
    #if !os(Linux)
    func testOpenDatabaseWithCustomQos() throws {
        let dbPath = ":memory:"
        let systemConfig = SystemConfig(
            bufferPoolSize: 16 * 1024 * 1024,
            maxNumThreads: 1,
            enableCompression: false,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: 0,
            threadQoS: QOS_CLASS_BACKGROUND
        )
        let db = try Database(dbPath, systemConfig)
        let conn = try Connection(db)

        _ = try conn.query(
            "CREATE NODE TABLE person(name STRING, age INT64, PRIMARY KEY(name));"
        )
        _ = try conn.query("CREATE (:person {name: 'Alice', age: 30});")
        _ = try conn.query("CREATE (:person {name: 'Bob', age: 40});")

        let result = try conn.query("MATCH (a:person) RETURN a.name, a.age;")
        XCTAssertTrue(result.hasNext())

        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[0] as! String, "Alice")
        XCTAssertEqual(values[1] as! Int64, 30)

        XCTAssertTrue(result.hasNext())
        let tuple2 = try result.getNext()!
        let values2 = try tuple2.getAsArray()
        XCTAssertEqual(values2.count, 2)
        XCTAssertEqual(values2[0] as! String, "Bob")
        XCTAssertEqual(values2[1] as! Int64, 40)

        XCTAssertFalse(result.hasNext())
    }
    #endif
}
