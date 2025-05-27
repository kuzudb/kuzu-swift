//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import XCTest

@testable import Kuzu

final class ValueTests: XCTestCase {
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

    func testBool() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.isStudent;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Bool
        XCTAssertTrue(value)
    }

    func testInt64() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.age;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int64
        XCTAssertEqual(value, 35)
    }

    func testInt32() throws {
        let result = try! conn.query("RETURN CAST (170, \"INT32\")")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int32
        XCTAssertEqual(value, 170)
    }

    func testInt16() throws {
        let result = try! conn.query("RETURN CAST (888, \"INT16\")")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int16
        XCTAssertEqual(value, 888)
    }

    func testInt8() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.level;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int8
        XCTAssertEqual(value, 5)
    }

    func testUint64() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.code;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt64
        XCTAssertEqual(value, 9_223_372_036_854_775_808)
    }

    func testUint32() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.temperature;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt32
        XCTAssertEqual(value, 32800)
    }

    func testUint16() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.ulength;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt16
        XCTAssertEqual(value, 33768)
    }

    func testUint8() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.ulevel;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt8
        XCTAssertEqual(value, 250)
    }

    func testInt128() throws {
        let result = try! conn.query(
            "RETURN CAST (18446744073709551610, \"INT128\")"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Decimal
        XCTAssertEqual(value, Decimal(string: "18446744073709551610")!)

        let result2 = try! conn.query(
            "RETURN CAST (-18446744073709551610, \"INT128\")"
        )
        XCTAssertTrue(result2.hasNext())
        let tuple2 = try! result2.getNext()!
        let value2 = try tuple2.getValue(0) as! Decimal
        XCTAssertEqual(value2, Decimal(string: "-18446744073709551610")!)
    }

    func testSerial() throws {
        let result = try! conn.query(
            "MATCH (a:moviesSerial) WHERE a.ID = 2 RETURN a.ID;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int64
        XCTAssertEqual(value, 2)
    }

    func testDouble() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.eyeSight;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Double
        XCTAssertLessThan(abs(value - 5.0), 0.000001)
    }

    func testFloat() throws {
        let result = try! conn.query("RETURN CAST (1.75, \"FLOAT\")")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Float
        XCTAssertLessThan(abs(value - 1.75), 0.000001)
    }

    func testString() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! String
        XCTAssertEqual(value, "Alice")
    }

    func testBlob() throws {
        let result = try! conn.query(
            "RETURN BLOB('\\\\xAA\\\\xBB\\\\xCD\\\\x1A')"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Data
        XCTAssertEqual(value[0], 0xAA)
        XCTAssertEqual(value[1], 0xBB)
        XCTAssertEqual(value[2], 0xCD)
        XCTAssertEqual(value[3], 0x1A)
    }

    func testUUID() throws {
        let result = try! conn.query(
            "RETURN UUID('{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}')"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UUID
        XCTAssertEqual(
            value,
            UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!
        )
    }

    func testDate() throws {
        let result = try! conn.query("RETURN DATE('1985-01-01')")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: value
        )
        XCTAssertEqual(components.year, 1985)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
    }

    func testTimestamp() throws {
        let result = try! conn.query("RETURN TIMESTAMP('1970-01-01T00:00:00Z')")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: value
        )
        XCTAssertEqual(components.year, 1970)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testTimestampNs() throws {
        // Note: Swift's Date is not precise enough to represent the timestamp with nanoseconds.
        // So we use a very small value to test the timestamp with nanoseconds.
        let preparedStatement = try! conn.prepare("RETURN $1")
        let testValue = 0.00011
        let params = ["1": Date(timeIntervalSince1970: testValue)]
        let result = try! conn.execute(preparedStatement, params)
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        XCTAssertLessThan(abs(testValue - value.timeIntervalSince1970), 0.00001)
    }

    func testTimestampMs() throws {
        let preparedStatement = try! conn.prepare(
            "RETURN CAST ($1, \"TIMESTAMP_MS\")"
        )
        var inputTime = Date(timeIntervalSince1970: 1_724_929_385)  // 2024-08-29T10:03:05Z
        inputTime = inputTime.addingTimeInterval(0.003)  // Add 3 milliseconds
        let params = ["1": inputTime]
        let result = try! conn.execute(preparedStatement, params)
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        XCTAssertEqual(value, inputTime)
    }

    func testTimestampSec() throws {
        let preparedStatement = try! conn.prepare(
            "RETURN CAST ($1, \"TIMESTAMP_SEC\")"
        )
        let inputTime = Date(timeIntervalSince1970: 1_724_929_385)  // 2024-08-29T10:03:05Z
        let params = ["1": inputTime]
        let result = try! conn.execute(preparedStatement, params)
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        XCTAssertEqual(value, inputTime)
    }

    func testTimestampTz() throws {
        let preparedStatement = try! conn.prepare(
            "RETURN CAST ($1, \"TIMESTAMP_TZ\")"
        )
        let inputTime = Date(timeIntervalSince1970: 1_724_929_385)  // 2024-08-29T10:03:05Z
        let params = ["1": inputTime]
        let result = try! conn.execute(preparedStatement, params)
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        XCTAssertEqual(value, inputTime)
    }

    func testInterval() throws {
        let result = try! conn.query("RETURN INTERVAL(\"3 days\");")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! TimeInterval
        XCTAssertEqual(value, 3 * 24 * 60 * 60)  // 3 days in seconds
    }

    func testList() throws {
        let result = try! conn.query("RETURN [[1, 2, 3], [4, 5, 6]]")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        let firstList = value[0] as! [Int64]
        let secondList = value[1] as! [Int64]
        XCTAssertEqual(firstList, [1, 2, 3])
        XCTAssertEqual(secondList, [4, 5, 6])
    }

    func testArray() throws {
        let result = try! conn.query("RETURN CAST([3, 4, 12, 11], 'INT64[4]')")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [Int64]
        XCTAssertEqual(value, [3, 4, 12, 11])
    }

    func testStruct() throws {
        let result = try! conn.query("RETURN {name: 'Alice', age: 30}")
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [String: Any]
        XCTAssertEqual(value["name"] as! String, "Alice")
        XCTAssertEqual(value["age"] as! Int64, 30)
    }

    func testMap() throws {
        let result = try! conn.query(
            "MATCH (m:movies) WHERE m.length = 2544 RETURN m.audience"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let arrayOfItems = try tuple.getValue(0) as! [(String, Int64)]
        let (name, value) = arrayOfItems[0]
        XCTAssertEqual(name, "audience1")
        XCTAssertEqual(value, 33)
    }

    func testDecimal() throws {
        let result = try! conn.query(
            "UNWIND [1] AS A UNWIND [5.7, 8.3, 8.7, 13.7] AS B WITH cast(CAST(A AS DECIMAL) * CAST(B AS DECIMAL) AS DECIMAL(18, 1)) AS PROD RETURN COLLECT(PROD) AS RES"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [Decimal]
        XCTAssertEqual(value.count, 4)
        XCTAssertEqual(value[0], Decimal(string: "5.7")!)
        XCTAssertEqual(value[1], Decimal(string: "8.3")!)
        XCTAssertEqual(value[2], Decimal(string: "8.7")!)
        XCTAssertEqual(value[3], Decimal(string: "13.7")!)
    }

    func testUnion() throws {
        let result = try! conn.query(
            "MATCH (m:movies) WHERE m.length = 2544 RETURN m.grade;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Double
        XCTAssertLessThan(abs(value - 8.989), 0.000001)
    }

    func testNode() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! KuzuNode
        XCTAssertEqual(value.label, "person")
        XCTAssertEqual(value.properties["ID"] as! Int64, 0)
        XCTAssertEqual(value.properties["fName"] as! String, "Alice")
        XCTAssertEqual(value.properties["gender"] as! Int64, 1)
        XCTAssertEqual(value.properties["age"] as! Int64, 35)
        XCTAssertTrue(value.properties["isStudent"] as! Bool)
        XCTAssertFalse(value.properties["isWorker"] as! Bool)
        XCTAssertLessThan(
            abs((value.properties["eyeSight"] as! Double) - 5.0),
            0.000001
        )
    }

    func testRelationship() throws {
        let result = try! conn.query(
            "MATCH (p:person)-[r:workAt]->(o:organisation) WHERE p.ID = 5 RETURN p, r, o"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let map = try tuple.getAsDictionary()
        let rel = map["r"] as! KuzuRelationship
        let src = map["p"] as! KuzuNode
        let dst = map["o"] as! KuzuNode
        XCTAssertEqual(rel.label, "workAt")
        XCTAssertEqual(rel.sourceId, src.id)
        XCTAssertEqual(rel.targetId, dst.id)
        XCTAssertEqual(rel.properties["year"] as! Int64, 2010)
    }

    func testRecursiveRel() throws {
        let result = try! conn.query(
            "MATCH (a:person)-[e:studyAt*1..1]->(b:organisation) WHERE a.fName = 'Alice' RETURN e;"
        )
        XCTAssertTrue(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! KuzuRecursiveRelationship
        XCTAssertEqual(value.nodes.count, 0)
        XCTAssertEqual(value.relationships.count, 1)
        let rel = value.relationships[0]
        XCTAssertEqual(rel.label, "studyAt")
        XCTAssertEqual(rel.properties["length"] as! Int16, 5)
        XCTAssertEqual(rel.properties["year"] as! Int64, 2021)
    }
}
