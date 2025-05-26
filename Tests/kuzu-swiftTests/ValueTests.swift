//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import Testing

@testable import Kuzu

@Suite
struct ValueTests : ~Copyable{
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
    func testBool() throws {
        let result = try! conn.query("MATCH (a:person) WHERE a.ID = 0 RETURN a.isStudent;")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Bool
        #expect (value == true)
    }
}

