//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import XCTest

@testable import Kuzu

final class ThreadSafetyTests: XCTestCase {

    /// Test for HNSW index insertions with internal multi-threading
    /// This reproduces the crash scenario where the TaskScheduler uses multiple worker threads
    /// during transaction commit, which could cause race conditions in RelTable::detachDeleteForCSRRels
    /// The bug was that concurrent access to DirectedCSRIndex vector wasn't properly synchronized
    func testConcurrentHNSWIndexInsertions() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 256 * 1024 * 1024,
            maxNumThreads: 8,  // Multiple threads for internal parallelism
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_thread_safety_test_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        // Create schema with HNSW index
        let setupConn = try Connection(db)
        _ = try setupConn.query("CREATE NODE TABLE Document(id INT64, embedding FLOAT[3], PRIMARY KEY(id));")
        _ = try setupConn.query("CALL CREATE_VECTOR_INDEX('Document', 'embedding_index', 'embedding');")

        // Insert multiple documents in a single transaction
        // The internal TaskScheduler will use multiple threads during commit
        let numDocs = 200
        for i in 0..<numDocs {
            let x = Float.random(in: 0...1)
            let y = Float.random(in: 0...1)
            let z = Float.random(in: 0...1)
            let query = "CREATE (d:Document {id: \(i), embedding: [\(x), \(y), \(z)]});"
            _ = try setupConn.query(query)
        }

        // Verify all data was inserted correctly
        let result = try setupConn.query("MATCH (d:Document) RETURN count(d);")
        XCTAssertTrue(result.hasNext())
        let count = try result.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(count, Int64(numDocs))

        // Verify data can be queried
        let queryResult = try setupConn.query("MATCH (d:Document) RETURN d.id ORDER BY d.id LIMIT 5;")
        var queryCount = 0
        while queryResult.hasNext() {
            _ = try queryResult.getNext()
            queryCount += 1
        }
        XCTAssertEqual(queryCount, 5)

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }

    /// Test for detach delete operations with internal multi-threading
    /// This tests the scenario where TaskScheduler's worker threads execute detach delete
    /// on relationships during transaction commit, which was causing crashes in LocalRelTable::delete_
    /// due to improper synchronization of DirectedCSRIndex vector access
    func testDetachDeleteWithInternalThreads() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 256 * 1024 * 1024,
            maxNumThreads: 8,  // Multiple threads for internal parallelism
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_detach_delete_test_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        // Create schema
        let conn = try Connection(db)
        _ = try conn.query("CREATE NODE TABLE Person(id INT64, PRIMARY KEY(id));")
        _ = try conn.query("CREATE REL TABLE Knows(FROM Person TO Person);")

        // Create initial data - central node with many relationships
        _ = try conn.query("CREATE (p0:Person {id: 0});")
        for i in 1...100 {
            _ = try conn.query("CREATE (p:Person {id: \(i)});")
            _ = try conn.query("MATCH (p0:Person {id: 0}), (p:Person {id: \(i)}) CREATE (p0)-[:Knows]->(p);")
        }

        // Verify initial relationship count
        let countResult = try conn.query("MATCH (p0:Person {id: 0})-[:Knows]->(p) RETURN count(p);")
        XCTAssertTrue(countResult.hasNext())
        let initialCount = try countResult.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(initialCount, 100)

        // Perform detach delete - internal threads will process this in parallel
        _ = try conn.query("MATCH (p:Person) WHERE p.id > 0 AND p.id <= 50 DETACH DELETE p;")

        // Verify deletions completed successfully
        let finalResult = try conn.query("MATCH (p:Person) RETURN count(p);")
        XCTAssertTrue(finalResult.hasNext())
        let finalCount = try finalResult.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(finalCount, 51) // Person 0 and 51-100 remain

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }

    /// Test for read operations with internal multi-threading
    /// This tests the shared_mutex implementation where multiple internal worker threads
    /// can read concurrently during query execution
    func testReadWithInternalThreads() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 256 * 1024 * 1024,
            maxNumThreads: 8,  // Multiple threads for internal parallelism
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_read_test_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        // Create schema
        let conn = try Connection(db)
        _ = try conn.query("CREATE NODE TABLE Node(id INT64, PRIMARY KEY(id));")
        _ = try conn.query("CREATE REL TABLE Edge(FROM Node TO Node, weight DOUBLE);")

        // Create initial data - create nodes and relationships
        for i in 0..<100 {
            _ = try conn.query("CREATE (n:Node {id: \(i)});")
        }

        // Create edges
        for i in 0..<100 {
            let dstId = (i + 1) % 100
            let weight = Double(i) / 100.0
            _ = try conn.query(
                "MATCH (n:Node {id: \(i)}), (m:Node {id: \(dstId)}) CREATE (n)-[:Edge {weight: \(weight)}]->(m);"
            )
        }

        // Verify initial edge count
        let initialResult = try conn.query("MATCH (n:Node)-[e:Edge]->(m:Node) RETURN count(e);")
        XCTAssertTrue(initialResult.hasNext())
        let initialCount = try initialResult.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(initialCount, 100)

        // Perform a complex query that will utilize multiple internal threads
        let complexResult = try conn.query(
            "MATCH (n:Node)-[e:Edge]->(m:Node) WHERE e.weight > 0.5 RETURN n.id, m.id, e.weight ORDER BY e.weight;"
        )

        var resultCount = 0
        while complexResult.hasNext() {
            _ = try complexResult.getNext()
            resultCount += 1
        }
        XCTAssertGreaterThan(resultCount, 0)

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }

    /// Test for stress scenario with HNSW index operations
    /// Reproduces the exact stack trace scenario: bulk inserts with HNSW index
    /// that trigger shrinkForNode, createRels, and detachDelete operations
    /// with internal multi-threading during commit
    func testHNSWIndexStressWithInternalThreads() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 256 * 1024 * 1024,
            maxNumThreads: 8,  // Multiple threads for internal parallelism during commit
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_hnsw_stress_test_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        // Create schema with HNSW index
        let conn = try Connection(db)
        _ = try conn.query("CREATE NODE TABLE Item(id INT64, vec FLOAT[5], PRIMARY KEY(id));")
        _ = try conn.query("CALL CREATE_VECTOR_INDEX('Item', 'vec_index', 'vec');")

        // Insert many items - this will trigger internal parallelism during commit
        // which exercises the RelTable::detachDeleteForCSRRels path that was buggy
        let numItems = 150
        for i in 0..<numItems {
            let vec = (0..<5).map { _ in Float.random(in: 0...1) }
            let vecStr = vec.map { String($0) }.joined(separator: ", ")
            _ = try conn.query("CREATE (item:Item {id: \(i), vec: [\(vecStr)]});")
        }

        // Verify all inserts completed
        let countResult = try conn.query("MATCH (item:Item) RETURN count(item);")
        XCTAssertTrue(countResult.hasNext())
        let count = try countResult.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(count, Int64(numItems))

        // Test query - this also uses internal threading
        let result = try conn.query("MATCH (item:Item) RETURN item.id ORDER BY item.id LIMIT 10;")

        var resultCount = 0
        while result.hasNext() {
            _ = try result.getNext()
            resultCount += 1
        }
        XCTAssertEqual(resultCount, 10)

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }

    /// Large-scale stress test with 1000+ items
    /// Simulates real-world photo indexing scenario with HNSW vector indexes
    /// This test reproduces the exact workload that was causing crashes in production
    func testLargeScaleHNSWIndexing() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 512 * 1024 * 1024,  // Larger buffer for stress test
            maxNumThreads: 8,
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_large_scale_test_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        let conn = try Connection(db)
        _ = try conn.query("CREATE NODE TABLE Photo(id STRING, embedding FLOAT[128], timestamp INT64, PRIMARY KEY(id));")
        _ = try conn.query("CALL CREATE_VECTOR_INDEX('Photo', 'photo_embedding_index', 'embedding');")

        // Simulate photo indexing workload: 1000 photos in batches of 100
        let totalPhotos = 1000
        let batchSize = 100
        let batches = totalPhotos / batchSize

        print("🔄 Starting large-scale test: \(totalPhotos) photos in \(batches) batches")

        for batchNum in 0..<batches {
            let batchStart = batchNum * batchSize
            let batchEnd = batchStart + batchSize

            // Insert batch
            for i in batchStart..<batchEnd {
                let photoID = "photo-\(i)"
                let embedding = (0..<128).map { _ in Float.random(in: 0...1) }
                let embeddingStr = embedding.map { String($0) }.joined(separator: ", ")
                let timestamp = Int64(Date().timeIntervalSince1970) + Int64(i)

                _ = try conn.query("CREATE (p:Photo {id: '\(photoID)', embedding: [\(embeddingStr)], timestamp: \(timestamp)});")
            }

            // Verify batch was committed successfully
            let countResult = try conn.query("MATCH (p:Photo) RETURN count(p);")
            XCTAssertTrue(countResult.hasNext())
            let count = try countResult.getNext()!.getValue(0) as! Int64
            XCTAssertEqual(count, Int64(batchEnd))

            print("✅ Batch \(batchNum + 1)/\(batches) completed (\(batchEnd) photos total)")
        }

        // Final verification
        let finalResult = try conn.query("MATCH (p:Photo) RETURN count(p);")
        XCTAssertTrue(finalResult.hasNext())
        let finalCount = try finalResult.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(finalCount, Int64(totalPhotos))

        print("🎉 Large-scale test completed successfully: \(totalPhotos) photos indexed")

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }

    /// Extreme stress test with single large transaction
    /// This test commits 500 items at once to trigger maximum internal parallelism
    /// Reproduces the worst-case scenario for the DirectedCSRIndex race condition
    func testSingleLargeTransactionStress() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 512 * 1024 * 1024,
            maxNumThreads: 8,
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_single_tx_stress_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        let conn = try Connection(db)
        _ = try conn.query("CREATE NODE TABLE Document(id STRING, vec FLOAT[64], PRIMARY KEY(id));")
        _ = try conn.query("CALL CREATE_VECTOR_INDEX('Document', 'doc_vec_index', 'vec');")

        // Single transaction with 500 inserts
        // This maximizes the chance of thread race conditions during commit
        let itemCount = 500

        print("🔄 Starting single transaction stress test: \(itemCount) items")

        for i in 0..<itemCount {
            let docID = "doc-\(i)"
            let vec = (0..<64).map { _ in Float.random(in: 0...1) }
            let vecStr = vec.map { String($0) }.joined(separator: ", ")

            _ = try conn.query("CREATE (d:Document {id: '\(docID)', vec: [\(vecStr)]});")
        }

        // Verify all items were inserted
        let result = try conn.query("MATCH (d:Document) RETURN count(d);")
        XCTAssertTrue(result.hasNext())
        let count = try result.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(count, Int64(itemCount))

        print("✅ Single transaction stress test completed: \(itemCount) items")

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }

    /// Rapid sequential batches stress test
    /// This test performs many small sequential transactions rapidly
    /// Tests the lock acquisition/release pattern under heavy load
    func testRapidSequentialBatches() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 256 * 1024 * 1024,
            maxNumThreads: 8,
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_rapid_batches_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        let conn = try Connection(db)
        _ = try conn.query("CREATE NODE TABLE Item(id STRING, embedding FLOAT[32], PRIMARY KEY(id));")
        _ = try conn.query("CALL CREATE_VECTOR_INDEX('Item', 'item_idx', 'embedding');")

        // 200 batches of 5 items each = 1000 total
        let batchCount = 200
        let itemsPerBatch = 5

        print("🔄 Starting rapid batches test: \(batchCount) batches")

        for batchNum in 0..<batchCount {
            for itemNum in 0..<itemsPerBatch {
                let itemID = "item-\(batchNum * itemsPerBatch + itemNum)"
                let embedding = (0..<32).map { _ in Float.random(in: 0...1) }
                let embeddingStr = embedding.map { String($0) }.joined(separator: ", ")

                _ = try conn.query("CREATE (i:Item {id: '\(itemID)', embedding: [\(embeddingStr)]});")
            }

            // Every 50 batches, verify progress
            if (batchNum + 1) % 50 == 0 {
                let result = try conn.query("MATCH (i:Item) RETURN count(i);")
                XCTAssertTrue(result.hasNext())
                let count = try result.getNext()!.getValue(0) as! Int64
                XCTAssertEqual(count, Int64((batchNum + 1) * itemsPerBatch))
                print("✅ Progress: \(batchNum + 1)/\(batchCount) batches")
            }
        }

        // Final verification
        let finalResult = try conn.query("MATCH (i:Item) RETURN count(i);")
        XCTAssertTrue(finalResult.hasNext())
        let finalCount = try finalResult.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(finalCount, Int64(batchCount * itemsPerBatch))

        print("🎉 Rapid batches test completed: \(batchCount) batches, \(finalCount) items")

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }

    /// Mixed operations stress test
    /// Combines inserts, deletes, and queries in a realistic pattern
    /// Simulates real application behavior with concurrent operations
    func testMixedOperationsStress() async throws {
        let systemConfig = SystemConfig(
            bufferPoolSize: 256 * 1024 * 1024,
            maxNumThreads: 8,
            enableCompression: true,
            readOnly: false,
            autoCheckpoint: true,
            checkpointThreshold: UInt64.max
        )

        let dbPath = NSTemporaryDirectory() + "kuzu_mixed_ops_test_" + UUID().uuidString
        let db = try Database(dbPath, systemConfig)

        let conn = try Connection(db)
        _ = try conn.query("CREATE NODE TABLE Record(id STRING, data FLOAT[16], PRIMARY KEY(id));")
        _ = try conn.query("CALL CREATE_VECTOR_INDEX('Record', 'record_idx', 'data');")

        print("🔄 Starting mixed operations stress test")

        // Phase 1: Insert 300 records
        for i in 0..<300 {
            let recordID = "record-\(i)"
            let data = (0..<16).map { _ in Float.random(in: 0...1) }
            let dataStr = data.map { String($0) }.joined(separator: ", ")

            _ = try conn.query("CREATE (r:Record {id: '\(recordID)', data: [\(dataStr)]});")
        }

        let afterInsert = try conn.query("MATCH (r:Record) RETURN count(r);")
        XCTAssertTrue(afterInsert.hasNext())
        let insertCount = try afterInsert.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(insertCount, 300)
        print("✅ Phase 1: Inserted 300 records")

        // Phase 2: Delete 100 records
        for i in 0..<100 {
            let recordID = "record-\(i)"
            _ = try conn.query("MATCH (r:Record {id: '\(recordID)'}) DELETE r;")
        }

        let afterDelete = try conn.query("MATCH (r:Record) RETURN count(r);")
        XCTAssertTrue(afterDelete.hasNext())
        let deleteCount = try afterDelete.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(deleteCount, 200)
        print("✅ Phase 2: Deleted 100 records")

        // Phase 3: Insert another 200 records
        for i in 300..<500 {
            let recordID = "record-\(i)"
            let data = (0..<16).map { _ in Float.random(in: 0...1) }
            let dataStr = data.map { String($0) }.joined(separator: ", ")

            _ = try conn.query("CREATE (r:Record {id: '\(recordID)', data: [\(dataStr)]});")
        }

        let finalResult = try conn.query("MATCH (r:Record) RETURN count(r);")
        XCTAssertTrue(finalResult.hasNext())
        let finalCount = try finalResult.getNext()!.getValue(0) as! Int64
        XCTAssertEqual(finalCount, 400)
        print("✅ Phase 3: Added 200 more records")

        // Phase 4: Query all remaining records
        let queryResult = try conn.query("MATCH (r:Record) RETURN r.id ORDER BY r.id LIMIT 10;")
        var queryCount = 0
        while queryResult.hasNext() {
            _ = try queryResult.getNext()
            queryCount += 1
        }
        XCTAssertEqual(queryCount, 10)
        print("✅ Phase 4: Queried records successfully")

        print("🎉 Mixed operations stress test completed")

        // Cleanup
        deleteTestDatabaseDirectory(dbPath)
    }
}
