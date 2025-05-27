//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import XCTest

@testable import Kuzu

final class ConnectionTests: XCTestCase {
    var db: Database!
    var path: String!

    override func setUp() {
        super.setUp()
        (db, _, path) = try! getTestDatabase()
    }

    override func tearDown() {
        deleteTestDatabaseDirectory(path)
        super.tearDown()
    }

    func testOpenConnection() throws {
        _ = try Connection(db)
    }

    func testGetMaxNumThreads() throws {
        let conn = try Connection(db)
        XCTAssertEqual(conn.getMaxNumThreadForExec(), 4) // Default value
    }

    func testSetMaxNumThreads() throws {
        let conn = try Connection(db)
        conn.setMaxNumThreadForExec(3)
        XCTAssertEqual(conn.getMaxNumThreadForExec(), 3)
    }

    // TODO: fix this test on Linux.
    #if !os(Linux)
    func testInterrupt() async throws {
        let conn = try Connection(db)
        let largeQuery = "UNWIND RANGE(1,100000) AS x UNWIND RANGE(1, 100000) AS y RETURN COUNT(x + y);"
        
        // Launch the query on a Task
        let task = Task { @Sendable in
            do {
                _ = try conn.query(largeQuery)
                XCTFail("Expected query to be interrupted")
            } catch let error as KuzuError {
                XCTAssertEqual(error.message, "Interrupted.")
            } catch {
                XCTFail("Query failed, but not due to interruption")
            }
        }
        
        // Give the query time to start
        try await Task.sleep(nanoseconds: 500_000_000)
        conn.interrupt()
        
        // Wait for task to finish
        await task.value
    }
    #endif
    
    func testSetTimeout() throws {
        let conn = try Connection(db)
        conn.setQueryTimeout(100)
        
        do {
            _ = try conn.query("UNWIND RANGE(1,100000) AS x UNWIND RANGE(1, 100000) AS y RETURN COUNT(x + y);")
            XCTFail("Expected timeout error")
        } catch let error as KuzuError {
            XCTAssertEqual(error.message, "Interrupted.")
        } catch {
            XCTFail("Query failed, but not due to interruption")
        }
    }

    func testQuery() throws {
        let conn = try Connection(db)
        let result = try conn.query("RETURN CAST(1, \"INT64\");")
        XCTAssertTrue(result.hasNext())
        
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        XCTAssertEqual(values[0] as! Int64, 1)
    }

    func testQueryError() throws {
        let conn = try Connection(db)
        do {
            _ = try conn.query("RETURN a;")
            XCTFail("Expected error")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("Variable a is not in scope."))
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testPrepare() throws {
        let conn = try Connection(db)
        _ = try conn.prepare("RETURN $a;")
    }

    func testPrepareError() throws {
        let conn = try Connection(db)
        do {
            _ = try conn.prepare("MATCH RETURN $a;")
            XCTFail("Expected error")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("Parser exception"))
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    func testExecute() throws {
        let conn = try Connection(db)
        let stmt = try conn.prepare("RETURN $a;")
        let result = try conn.execute(stmt, ["a": Int64(1)])
        
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        XCTAssertEqual(values[0] as! Int64, 1)
    }

    func testExecuteError() throws {
        let conn = try Connection(db)
        let stmt = try conn.prepare("RETURN $a;")
        
        do {
            _ = try conn.execute(stmt, ["b": Int64(1)])
            XCTFail("Expected error")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("Parameter b not found"))
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}
