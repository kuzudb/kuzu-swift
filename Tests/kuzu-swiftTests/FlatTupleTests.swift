//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import XCTest

@testable import Kuzu

final class FlatTupleTests: XCTestCase {
    private var db: Database!
    private var conn: Connection!
    private var path: String!

    override func setUp() {
        super.setUp()
        (db, conn, path) = try! getTestDatabase()
    }

    override func tearDown() {
        deleteTestDatabaseDirectory(path)
        super.tearDown()
    }

    func testTupleGetAsString() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let str = tuple.description
        XCTAssertTrue(str.contains("Alice|35"))
    }

    func testTupleGetAsArray() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.gender, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        XCTAssertEqual(values.count, 3)
        XCTAssertEqual(values[0] as! String, "Alice")
        XCTAssertEqual(values[1] as! Int64, 1)
        XCTAssertEqual(values[2] as! Int64, 35)
    }

    func testTupleGetAsDictionary() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.gender, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let m = try tuple.getAsDictionary()
        XCTAssertEqual(m.count, 3)
        XCTAssertNotNil(m["a.fName"])
        XCTAssertNotNil(m["a.gender"])
        XCTAssertNotNil(m["a.age"])
        XCTAssertEqual(m["a.fName"] as! String, "Alice")
        XCTAssertEqual(m["a.gender"] as! Int64, 1)
        XCTAssertEqual(m["a.age"] as! Int64, 35)
    }

    func testGetValue() throws {
        let query = "MATCH (a:person) RETURN a.fName, a.gender, a.age ORDER BY a.fName LIMIT 1;"
        let result = try conn.query(query)
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value1 = try tuple.getValue(0)
        XCTAssertEqual(value1 as! String, "Alice")
        let value2 = try tuple.getValue(1)
        XCTAssertEqual(value2 as! Int64, 1)
        let value3 = try tuple.getValue(2)
        XCTAssertEqual(value3 as! Int64, 35)
    }
}
