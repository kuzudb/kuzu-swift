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
struct FlatTupleTests: ~Copyable {
    var db: Database!
    var conn: Connection!
    var path: String

    init() {
        (db, conn, path) = try! getTestDatabase()
    }

    deinit {
        deleteTestDatabaseDirectory(path)
    }

    @Test
    func testTupleGetAsString() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let str = tuple.description
        #expect(str.contains("Alice|35"))
    }

    @Test
    func testTupleGetAsArray() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.gender, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        #expect(values.count == 3)
        #expect(values[0] as! String == "Alice")
        #expect(values[1] as! Int64 == 1)
        #expect(values[2] as! Int64 == 35)
    }

    @Test
    func testTupleGetAsDictionary() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.gender, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let m = try tuple.getAsDictionary()
        #expect(m.count == 3)
        #expect(m["a.fName"] != nil)
        #expect(m["a.gender"] != nil)
        #expect(m["a.age"] != nil)
        #expect(m["a.fName"] as! String == "Alice")
        #expect(m["a.gender"] as! Int64 == 1)
        #expect(m["a.age"] as! Int64 == 35)
    }

    @Test
    func testGetValue() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.gender, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value1 = try tuple.getValue(0)
        #expect(value1 as! String == "Alice")
        let value2 = try tuple.getValue(1)
        #expect(value2 as! Int64 == 1)
        let value3 = try tuple.getValue(2)
        #expect(value3 as! Int64 == 35)
    }
}
