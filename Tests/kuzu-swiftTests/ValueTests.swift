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
struct ValueTests: ~Copyable {
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
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.isStudent;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Bool
        #expect(value == true)
    }

    @Test
    func testInt64() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.age;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int64
        #expect(value == 35)
    }

    @Test
    func testInt32() throws {
        let result = try! conn.query("RETURN CAST (170, \"INT32\")")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int32
        #expect(value == 170)
    }

    @Test
    func testInt16() throws {
        let result = try! conn.query("RETURN CAST (888, \"INT16\")")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int16
        #expect(value == 888)
    }

    @Test
    func testInt8() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.level;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int8
        #expect(value == 5)
    }

    @Test
    func testUint64() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.code;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt64
        #expect(value == 9_223_372_036_854_775_808)
    }

    @Test
    func testUint32() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.temperature;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt32
        #expect(value == 32800)
    }

    @Test
    func testUint16() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.ulength;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt16
        #expect(value == 33768)
    }

    @Test
    func testUint8() throws {
        let result = try! conn.query(
            "MATCH (a:person) -[r:studyAt]-> (b:organisation) WHERE r.length = 5 RETURN r.ulevel;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UInt8
        #expect(value == 250)
    }

    @Test
    func testInt128() throws {
        let result = try! conn.query(
            "RETURN CAST (18446744073709551610, \"INT128\")"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Decimal
        #expect(value == Decimal(string: "18446744073709551610")!)

        let result2 = try! conn.query(
            "RETURN CAST (-18446744073709551610, \"INT128\")"
        )
        #expect(result2.hasNext())
        let tuple2 = try! result2.getNext()!
        let value2 = try tuple2.getValue(0) as! Decimal
        #expect(value2 == Decimal(string: "-18446744073709551610")!)
    }

    @Test
    func testSerial() throws {
        let result = try! conn.query(
            "MATCH (a:moviesSerial) WHERE a.ID = 2 RETURN a.ID;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Int64
        #expect(value == 2)
    }

    @Test
    func testDouble() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.eyeSight;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Double
        #expect(abs(value - 5.0) < 0.000001)
    }

    @Test
    func testFloat() throws {
        let result = try! conn.query("RETURN CAST (1.75, \"FLOAT\")")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Float
        #expect(abs(value - 1.75) < 0.000001)
    }

    @Test
    func testString() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a.fName;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! String
        #expect(value == "Alice")
    }

    @Test
    func testBlob() throws {
        let result = try! conn.query(
            "RETURN BLOB('\\\\xAA\\\\xBB\\\\xCD\\\\x1A')"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Data
        #expect(value[0] == 0xAA)
        #expect(value[1] == 0xBB)
        #expect(value[2] == 0xCD)
        #expect(value[3] == 0x1A)
    }
    
    @Test
    func testUUID() throws {
        let result = try! conn.query("RETURN UUID('{a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11}')")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! UUID
        #expect(value == UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!)
    }

    @Test
    func testDate() throws {
        let result = try! conn.query("RETURN DATE('1985-01-01')")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: value
        )
        #expect(components.year == 1985)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }

    @Test
    func testTimestamp() throws {
        let result = try! conn.query("RETURN TIMESTAMP('1970-01-01T00:00:00Z')")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: value
        )
        #expect(components.year == 1970)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test
    func testTimestampNs() throws {
        // Note: Swift's Date is not precise enough to represent the timestamp with nanoseconds.
        // So we use a very small value to test the timestamp with nanoseconds.
        let preparedStatement = try! conn.prepare("RETURN $1")
        let testValue = 0.00011
        let params = ["1": Date(timeIntervalSince1970: testValue)]
        let result = try! conn.execute(preparedStatement, params)
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        #expect(abs(testValue - value.timeIntervalSince1970) < 0.00001)
    }

    @Test
    func testTimestampMs() throws {
        let preparedStatement = try! conn.prepare(
            "RETURN CAST ($1, \"TIMESTAMP_MS\")"
        )
        var inputTime = Date(timeIntervalSince1970: 1_724_929_385)  // 2024-08-29T10:03:05Z
        inputTime = inputTime.addingTimeInterval(0.003)  // Add 3 milliseconds
        let params = ["1": inputTime]
        let result = try! conn.execute(preparedStatement, params)
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        #expect(value == inputTime)
    }

    @Test
    func testTimestampSec() throws {
        let preparedStatement = try! conn.prepare(
            "RETURN CAST ($1, \"TIMESTAMP_SEC\")"
        )
        let inputTime = Date(timeIntervalSince1970: 1_724_929_385)  // 2024-08-29T10:03:05Z
        let params = ["1": inputTime]
        let result = try! conn.execute(preparedStatement, params)
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        #expect(value == inputTime)
    }

    @Test
    func testTimestampTz() throws {
        let preparedStatement = try! conn.prepare(
            "RETURN CAST ($1, \"TIMESTAMP_TZ\")"
        )
        let inputTime = Date(timeIntervalSince1970: 1_724_929_385)  // 2024-08-29T10:03:05Z
        let params = ["1": inputTime]
        let result = try! conn.execute(preparedStatement, params)
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Date
        #expect(value == inputTime)
    }

    @Test
    func testInterval() throws {
        let result = try! conn.query("RETURN INTERVAL(\"3 days\");")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! TimeInterval
        #expect(value == 3 * 24 * 60 * 60)  // 3 days in seconds
    }

    @Test
    func testList() throws {
        let result = try! conn.query("RETURN [[1, 2, 3], [4, 5, 6]]")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        let firstList = value[0] as! [Int64]
        let secondList = value[1] as! [Int64]
        #expect(firstList == [1, 2, 3])
        #expect(secondList == [4, 5, 6])
    }

    @Test
    func testArray() throws {
        let result = try! conn.query("RETURN CAST([3, 4, 12, 11], 'INT64[4]')")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [Int64]
        #expect(value == [3, 4, 12, 11])
    }

    @Test
    func testStruct() throws {
        let result = try! conn.query("RETURN {name: 'Alice', age: 30}")
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [String: Any]
        #expect(value["name"] as! String == "Alice")
        #expect(value["age"] as! Int64 == 30)
    }

    @Test
    func testMap() throws {
        let result = try! conn.query(
            "MATCH (m:movies) WHERE m.length = 2544 RETURN m.audience"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let arrayOfItems = try tuple.getValue(0) as! [(String, Int64)]
        let (name, value) = arrayOfItems[0]
        #expect(name == "audience1")
        #expect(value == 33)
    }

    @Test
    func testDecimal() throws {
        let result = try! conn.query(
            "UNWIND [1] AS A UNWIND [5.7, 8.3, 8.7, 13.7] AS B WITH cast(CAST(A AS DECIMAL) * CAST(B AS DECIMAL) AS DECIMAL(18, 1)) AS PROD RETURN COLLECT(PROD) AS RES"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! [Decimal]
        #expect(value.count == 4)
        #expect(value[0] == Decimal(string: "5.7")!)
        #expect(value[1] == Decimal(string: "8.3")!)
        #expect(value[2] == Decimal(string: "8.7")!)
        #expect(value[3] == Decimal(string: "13.7")!)
    }

    @Test
    func testUnion() throws {
        let result = try! conn.query(
            "MATCH (m:movies) WHERE m.length = 2544 RETURN m.grade;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! Double
        #expect(abs(value - 8.989) < 0.000001)
    }

    @Test
    func testNode() throws {
        let result = try! conn.query(
            "MATCH (a:person) WHERE a.ID = 0 RETURN a;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! KuzuNode
        #expect(value.label == "person")
        #expect(value.properties["ID"] as! Int64 == 0)
        #expect(value.properties["fName"] as! String == "Alice")
        #expect(value.properties["gender"] as! Int64 == 1)
        #expect(value.properties["age"] as! Int64 == 35)
        #expect(value.properties["isStudent"] as! Bool == true)
        #expect(value.properties["isWorker"] as! Bool == false)
        #expect(abs((value.properties["eyeSight"] as! Double) - 5.0) < 0.000001)
    }

    @Test
    func testRelationship() throws {
        let result = try! conn.query(
            "MATCH (p:person)-[r:workAt]->(o:organisation) WHERE p.ID = 5 RETURN p, r, o"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let map = try tuple.getAsDictionary()
        let rel = map["r"] as! KuzuRelationship
        let src = map["p"] as! KuzuNode
        let dst = map["o"] as! KuzuNode
        #expect(rel.label == "workAt")
        #expect(rel.sourceId == src.id)
        #expect(rel.targetId == dst.id)
        #expect(rel.properties["year"] as! Int64 == 2010)
    }

    @Test
    func testRecursiveRel() throws {
        let result = try! conn.query(
            "MATCH (a:person)-[e:studyAt*1..1]->(b:organisation) WHERE a.fName = 'Alice' RETURN e;"
        )
        #expect(result.hasNext())
        let tuple = try! result.getNext()!
        let value = try tuple.getValue(0) as! KuzuRecursiveRelationship
        #expect(value.nodes.count == 0)
        #expect(value.relationships.count == 1)
        let rel = value.relationships[0]
        #expect(rel.label == "studyAt")
        #expect(rel.properties["length"] as! Int16 == 5)
        #expect(rel.properties["year"] as! Int64 == 2021)
    }
}
