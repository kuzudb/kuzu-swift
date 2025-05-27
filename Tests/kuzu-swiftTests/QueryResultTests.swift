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
struct QueryResultTests: ~Copyable {
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
    func testQueryResultToString() throws {
        let result = try conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;")
        let queryResultString = result.description
        #expect(queryResultString == "a.fName|a.age|a.isStudent|a.isWorker\nAlice|35|True|False\n")
    }

    @Test
    func testQueryResultResetIterator() throws {
        let result = try conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.ID;")
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        #expect(value as! Int64 == 0)
        result.resetIterator()
        #expect(result.hasNext())
        let tuple2 = try result.getNext()!
        let value2 = try tuple2.getValue(0)
        #expect(value2 as! Int64 == 0)
    }

    @Test
    func testQueryResultGetColumnNames() throws {
        let result = try conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;")
        let columnNames = result.getColumnNames()
        #expect(columnNames.count == 4)
        #expect(columnNames[0] == "a.fName")
        #expect(columnNames[1] == "a.age")
        #expect(columnNames[2] == "a.isStudent")
        #expect(columnNames[3] == "a.isWorker")
    }

    @Test
    func testQueryResultGetNumberOfColumns() throws {
        let result = try conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;")
        let numColumns = result.getColumnCount()
        #expect(numColumns == 4)
    }

    @Test
    func testQueryResultGetNumberOfRows() throws {
        let result = try conn.query("MATCH (a:person) RETURN a;")
        let numRows = result.getRowCount()
        #expect(numRows == 8)
    }

    @Test
    func testQueryResultHasNext() throws {
        let result = try conn.query("MATCH (a:person) RETURN a LIMIT 1;")
        #expect(result.hasNext())
        _ = try result.getNext()!
        #expect(!result.hasNext())
    }

    @Test
    func testQueryResultNext() throws {
        let result = try conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;")
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        #expect(values.count == 4)
        #expect(values[0] as! String == "Alice")
        #expect(values[1] as! Int64 == 35)
        #expect(values[2] as! Bool == true)
        #expect(values[3] as! Bool == false)
    }

    @Test
    func testMultipleQueryResults() throws {
        let result = try conn.query("RETURN 1; RETURN 2; RETURN 3;")
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        #expect(value as! Int64 == 1)
        #expect(!result.hasNext())
        #expect(result.hasNextQueryResult())
        
        let result2 = try result.getNextQueryResult()!
        #expect(result2.hasNext())
        let tuple2 = try result2.getNext()!
        let value2 = try tuple2.getValue(0)
        #expect(value2 as! Int64 == 2)
        #expect(!result2.hasNext())
        #expect(result2.hasNextQueryResult())
        
        let result3 = try result2.getNextQueryResult()!
        #expect(result3.hasNext())
        let tuple3 = try result3.getNext()!
        let value3 = try tuple3.getValue(0)
        #expect(value3 as! Int64 == 3)
        #expect(!result3.hasNext())
        #expect(!result3.hasNextQueryResult())
    }

    @Test
    func testQueryResultGetCompilingTime() throws {
        let result = try conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;")
        #expect(result.getCompilingTime() > 0)
    }

    @Test
    func testQueryResultGetExecutionTime() throws {
        let result = try conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.fName, a.age, a.isStudent, a.isWorker;")
        #expect(result.getExecutionTime() > 0)
    }
}
