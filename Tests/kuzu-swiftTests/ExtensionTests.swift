//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)
import Foundation
import XCTest

@testable import Kuzu

final class ExtensionTests: XCTestCase {
    func testGds() async throws {
        func normalize(_ rows: [[String]]) -> [[String]] {
            return rows
                .map { $0.sorted() }
                .sorted { $0.lexicographicallyPrecedes($1) }
        }
        
        let systemConfig = SystemConfig(
            bufferPoolSize: 256 * 1024 * 1024, maxNumThreads: 4, enableCompression: true, readOnly: false, maxDbSize: 512 * 1024 * 1024, autoCheckpoint: true, checkpointThreshold: UInt64.max
        )
        let db = try Kuzu.Database(":memory:", systemConfig)
        let conn = try Kuzu.Connection(db)
        _ = try conn.query(
            "CREATE NODE TABLE Node(id STRING PRIMARY KEY);"
        )
        _ = try conn.query(
            "CREATE REL TABLE Edge(FROM Node to Node, id INT64);"
        )
        _ = try conn.query(
        """
        CREATE (u0:Node {id: 'A'}),
               (u1:Node {id: 'B'}),
               (u2:Node {id: 'C'}),
               (u3:Node {id: 'D'}),
               (u4:Node {id: 'E'}),
               (u5:Node {id: 'F'}),
               (u6:Node {id: 'G'}),
               (u7:Node {id: 'H'}),
               (u8:Node {id: 'I'}),
               (u0)-[:Edge {id:0}]->(u1),
               (u1)-[:Edge {id:1}]->(u2),
               (u5)-[:Edge {id:2}]->(u4),
               (u6)-[:Edge {id:3}]->(u4),
               (u6)-[:Edge {id:4}]->(u5),
               (u6)-[:Edge {id:5}]->(u7),
               (u7)-[:Edge {id:6}]->(u4),
               (u6)-[:Edge {id:7}]->(u5)
        """
        )
        _ = try conn.query("CALL project_graph('Graph', ['Node'], ['Edge']);")
        let result = try conn.query(
            "CALL weakly_connected_components('Graph') RETURN group_id, collect(node.id);"
        )
        var rows : [[String]] = []
        for row in result {
            let rowValue = try row.getValue(1) as! [String]
            rows.append(rowValue)
        }
        let groundTruth: [[String]] = [["I"], ["D"], ["B", "C", "A"], ["G", "F", "H", "E"]]
        XCTAssertEqual(normalize(groundTruth), normalize(rows))
    }
}
