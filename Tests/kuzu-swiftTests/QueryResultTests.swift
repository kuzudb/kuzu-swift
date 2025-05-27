//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import XCTest

@testable import Kuzu

final class QueryResultTests: XCTestCase {
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

    func testQueryResultToString() throws {
        let result = try conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;"
        )
        let queryResultString = result.description
        XCTAssertEqual(
            queryResultString,
            "a.fName|a.age|a.isStudent|a.isWorker\nAlice|35|True|False\n"
        )
    }

    func testQueryResultResetIterator() throws {
        let result = try conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.ID;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        XCTAssertEqual(value as! Int64, 0)
        result.resetIterator()
        XCTAssertTrue(result.hasNext())
        let tuple2 = try result.getNext()!
        let value2 = try tuple2.getValue(0)
        XCTAssertEqual(value2 as! Int64, 0)
    }

    func testQueryResultGetColumnNames() throws {
        let result = try conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;"
        )
        let columnNames = result.getColumnNames()
        XCTAssertEqual(columnNames.count, 4)
        XCTAssertEqual(columnNames[0], "a.fName")
        XCTAssertEqual(columnNames[1], "a.age")
        XCTAssertEqual(columnNames[2], "a.isStudent")
        XCTAssertEqual(columnNames[3], "a.isWorker")
    }

    func testQueryResultGetNumberOfColumns() throws {
        let result = try conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;"
        )
        let numColumns = result.getColumnCount()
        XCTAssertEqual(numColumns, 4)
    }

    func testQueryResultGetNumberOfRows() throws {
        let result = try conn.query("MATCH (a:person) RETURN a;")
        let numRows = result.getRowCount()
        XCTAssertEqual(numRows, 8)
    }

    func testQueryResultHasNext() throws {
        let result = try conn.query("MATCH (a:person) RETURN a LIMIT 1;")
        XCTAssertTrue(result.hasNext())
        _ = try result.getNext()!
        XCTAssertFalse(result.hasNext())
    }

    func testQueryResultNext() throws {
        let result = try conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        XCTAssertEqual(values.count, 4)
        XCTAssertEqual(values[0] as! String, "Alice")
        XCTAssertEqual(values[1] as! Int64, 35)
        XCTAssertTrue(values[2] as! Bool)
        XCTAssertFalse(values[3] as! Bool)
    }

    func testMultipleQueryResults() throws {
        let result = try conn.query("RETURN 1; RETURN 2; RETURN 3;")
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        XCTAssertEqual(value as! Int64, 1)
        XCTAssertFalse(result.hasNext())
        XCTAssertTrue(result.hasNextQueryResult())

        let result2 = try result.getNextQueryResult()!
        XCTAssertTrue(result2.hasNext())
        let tuple2 = try result2.getNext()!
        let value2 = try tuple2.getValue(0)
        XCTAssertEqual(value2 as! Int64, 2)
        XCTAssertFalse(result2.hasNext())
        XCTAssertTrue(result2.hasNextQueryResult())

        let result3 = try result2.getNextQueryResult()!
        XCTAssertTrue(result3.hasNext())
        let tuple3 = try result3.getNext()!
        let value3 = try tuple3.getValue(0)
        XCTAssertEqual(value3 as! Int64, 3)
        XCTAssertFalse(result3.hasNext())
        XCTAssertFalse(result3.hasNextQueryResult())
    }

    func testQueryResultGetCompilingTime() throws {
        let result = try conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;"
        )
        XCTAssertGreaterThan(result.getCompilingTime(), 0)
    }

    func testQueryResultGetExecutionTime() throws {
        let result = try conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;"
        )
        XCTAssertGreaterThan(result.getExecutionTime(), 0)
    }
}
