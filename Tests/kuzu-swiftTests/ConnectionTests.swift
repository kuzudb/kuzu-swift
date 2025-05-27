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
struct ConnectionTests: ~Copyable {
    var db: Database!
    var path: String

    init() {
        (db, _, path) = try! getTestDatabase()
    }

    deinit {
        deleteTestDatabaseDirectory(path)
    }

    @Test
    func testOpenConnection() throws {
       _ = try Connection(db)
    }

    @Test
    func testGetMaxNumThreads() throws {
        let conn = try Connection(db)
        #expect(conn.getMaxNumThreadForExec() == 4) // Default value
    }

    @Test
    func testSetMaxNumThreads() throws {
        let conn = try Connection(db)
        conn.setMaxNumThreadForExec(3)
        #expect(conn.getMaxNumThreadForExec() == 3)
    }

    @Test
    func testInterrupt() async throws {
        let conn = try Connection(db)
        let largeQuery = "UNWIND RANGE(1,100000) AS x UNWIND RANGE(1, 100000) AS y RETURN COUNT(x + y);"

        // Launch the query on a Task
        let task = Task { @Sendable in
            do {
                _ = try conn.query(largeQuery)
                #expect(Bool(false), "Expected query to be interrupted")
            } catch let error as KuzuError {
                #expect(error.message == "Interrupted.")
            } catch {
                #expect(Bool(false), "Query failed, but not due to interruption")
            }
        }

        // Give the query time to start
        try await Task.sleep(nanoseconds: 500_000_000)
        conn.interrupt()

        // Wait for task to finish
        await task.value
    }

    @Test
    func testSetTimeout() throws {
        let conn = try Connection(db)
        conn.setQueryTimeout(100)
        
        do {
            _ = try conn.query("UNWIND RANGE(1,100000) AS x UNWIND RANGE(1, 100000) AS y RETURN COUNT(x + y);")
            #expect(Bool(false), "Expected timeout error")
        } catch let error as KuzuError {
            #expect(error.message == "Interrupted.")
        } catch {
            #expect(Bool(false), "Query failed, but not due to interruption")
        }
    }

    @Test
    func testQuery() throws {
        let conn = try Connection(db)
        let result = try conn.query("RETURN CAST(1, \"INT64\");")
        #expect(result.hasNext())
        
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        #expect(values[0] as! Int64 == 1)
    }

    @Test
    func testQueryError() throws {
        let conn = try Connection(db)
        do {
            _ = try conn.query("RETURN a;")
            #expect(Bool(false), "Expected error")
        } catch let error as KuzuError {
            #expect(error.message.contains("Variable a is not in scope."))
        } catch {
            #expect(Bool(false), "Unexpected error type")
        }
    }

    @Test
    func testPrepare() throws {
        let conn = try Connection(db)
        _ = try conn.prepare("RETURN $a;")
    }

    @Test
    func testPrepareError() throws {
        let conn = try Connection(db)
        do {
            _ = try conn.prepare("MATCH RETURN $a;")
            #expect(Bool(false), "Expected error")
        } catch let error as KuzuError {
            #expect(error.message.contains("Parser exception"))
        } catch {
            #expect(Bool(false), "Unexpected error type")
        }
    }

    @Test
    func testExecute() throws {
        let conn = try Connection(db)
        let stmt = try conn.prepare("RETURN $a;")
        let result = try conn.execute(stmt, ["a": Int64(1)])
        
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let values = try tuple.getAsArray()
        #expect(values[0] as! Int64 == 1)
    }

    @Test
    func testExecuteError() throws {
        let conn = try Connection(db)
        let stmt = try conn.prepare("RETURN $a;")
        
        do {
            _ = try conn.execute(stmt, ["b": Int64(1)])
            #expect(Bool(false), "Expected error")
        } catch let error as KuzuError {
            #expect(error.message.contains("Parameter b not found"))
        } catch {
            #expect(Bool(false), "Unexpected error type")
        }
    }
}
