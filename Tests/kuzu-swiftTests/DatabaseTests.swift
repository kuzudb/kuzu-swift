//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)
import Foundation
import Testing

@testable import Kuzu

@Suite(.serialized)
struct DatabaseTests {
    @Test
    func testOpenDatabaseWithDefaultConfig() throws {
        let dbPath = NSTemporaryDirectory() + "kuzu_swift_test_db_" + UUID().uuidString
        _ = try Database(dbPath)
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    @Test
    func testOpenDatabaseWithCustomConfig() throws {
        let dbPath = NSTemporaryDirectory() + "kuzu_swift_test_db_" + UUID().uuidString
        let systemConfig = SystemConfig(
            bufferPoolSize: 16*1024*1024, maxNumThreads: 1, enableCompression: false, readOnly: false, maxDbSize: 4 * 1024 * 1024 * 1024, autoCheckpoint: true, checkpointThreshold: 0
        )
        _ = try Database(dbPath, systemConfig)
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    @Test
    func testOpenDatabaseInMemory() throws {
        let db = try Database()
        
        let conn = try Connection(db)
        
        _ = try conn.query("CREATE NODE TABLE person(name STRING, age INT64, PRIMARY KEY(name));")
        _ = try conn.query("CREATE (:person {name: 'Alice', age: 30});")
        _ = try conn.query("CREATE (:person {name: 'Bob', age: 40});")
        
        let result = try conn.query("MATCH (a:person) RETURN a.name, a.age;")
        #expect(result.hasNext())
        
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        #expect(values.count == 2)
        #expect(values[0] as! String == "Alice")
        #expect(values[1] as! Int64 == 30)
        
        #expect(result.hasNext())
        let tuple2 = try result.getNext()!
        let values2 = try tuple2.getAsArray()
        #expect(values2.count == 2)
        #expect(values2[0] as! String == "Bob")
        #expect(values2[1] as! Int64 == 40)
        
        #expect(!result.hasNext())
    }
}
