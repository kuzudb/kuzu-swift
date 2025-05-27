//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import XCTest

@testable import Kuzu

final class ParameterTests: XCTestCase {
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

    private func basicParamTestHelper(_ param: Any?) throws {
        let preparedStatement = try conn.prepare("RETURN $1")
        let params = ["1": param]
        let result = try conn.execute(preparedStatement, params)
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        
        if param == nil && value == nil {
            return
        }
        
        // Handle different types explicitly
        switch (param, value) {
        case (let p as String, let v as String):
            XCTAssertEqual(p, v)
        case (let p as Bool, let v as Bool):
            XCTAssertEqual(p, v)
        case (let p as Int64, let v as Int64):
            XCTAssertEqual(p, v)
        case (let p as Int32, let v as Int32):
            XCTAssertEqual(p, v)
        case (let p as Int16, let v as Int16):
            XCTAssertEqual(p, v)
        case (let p as Int8, let v as Int8):
            XCTAssertEqual(p, v)
        case (let p as UInt64, let v as UInt64):
            XCTAssertEqual(p, v)
        case (let p as KuzuUInt32Wrapper, let v as UInt32):
            XCTAssertEqual(p.value, v)
        case (let p as KuzuUInt16Wrapper, let v as UInt16):
            XCTAssertEqual(p.value, v)
        case (let p as KuzuUInt8Wrapper, let v as UInt8):
            XCTAssertEqual(p.value, v)
        case (let p as TimeInterval, let v as TimeInterval):
            XCTAssertEqual(p, v)
        case (is NSNull, is NSNull):
            // Both are NSNull, which is what we want
            break
        case (let p as [String: Any], let v as [String: Any]):
            XCTAssertEqual(p.count, v.count)
            for (key, pValue) in p {
                guard v[key] != nil else {
                    XCTFail("Missing key in result: \(key)")
                    continue
                }
                try basicParamTestHelper(pValue)
            }
        case (let p as [(String, Any)], let v as [(String, Any)]):
            XCTAssertEqual(p.count, v.count)
            for i in 0..<p.count {
                XCTAssertEqual(p[i].0, v[i].0)
                try basicParamTestHelper(p[i].1)
            }
        case (let p as [Any], let v as [Any]):
            XCTAssertEqual(p.count, v.count)
            for i in 0..<p.count {
                try basicParamTestHelper(p[i])
            }
        default:
            XCTFail("Type mismatch: expected \(type(of: param!)), got \(type(of: value!))")
        }
    }

    private func floatParamTestHelper(_ param: Any) throws {
        let preparedStatement = try conn.prepare("RETURN $1")
        let params = ["1": param]
        let result = try conn.execute(preparedStatement, params)
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        if let floatValue = value as? Double, let paramValue = param as? Double {
            XCTAssertLessThan(abs(floatValue - paramValue), 0.000001)
        } else if let floatValue = value as? Float, let paramValue = param as? Float {
            XCTAssertLessThan(abs(floatValue - paramValue), 0.000001)
        } else {
            XCTFail("Type mismatch in floatParamTestHelper")
        }
    }

    private func timeParamTestHelper(_ param: Date) throws {
        let preparedStatement = try conn.prepare("RETURN $1")
        let params = ["1": param]
        let result = try conn.execute(preparedStatement, params)
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! Date
        XCTAssertEqual(value, param)
    }

    func testStringParam() throws {
        try basicParamTestHelper("Hello World")
    }

    func testBoolParam() throws {
        try basicParamTestHelper(true)
        try basicParamTestHelper(false)
    }

    func testInt64Param() throws {
        try basicParamTestHelper(Int64(1000000000000))
    }

    func testInt32Param() throws {
        try basicParamTestHelper(Int32(200))
    }

    func testInt16Param() throws {
        try basicParamTestHelper(Int16(300))
    }

    func testInt8Param() throws {
        try basicParamTestHelper(Int8(4))
    }

    func testUint64Param() throws {
        try basicParamTestHelper(UInt64.max)
    }

    func testUint32Param() throws {
        try basicParamTestHelper(KuzuUInt32Wrapper(value: 600))
    }

    func testUint16Param() throws {
        try basicParamTestHelper(KuzuUInt16Wrapper(value: 700))
    }

    func testUint8Param() throws {
        try basicParamTestHelper(KuzuUInt8Wrapper(value: 8))
    }

    func testDoubleParam() throws {
        try floatParamTestHelper(Double(3.14159235))
    }

    func testFloatParam() throws {
        try floatParamTestHelper(Float(2.71828))
    }

    func testTimeParam() throws {
        let date = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        try timeParamTestHelper(date)
    }

    func testTimeWithNanosecondsParam() throws {
        var components = DateComponents()
        components.year = 2020
        components.month = 1
        components.day = 1
        components.nanosecond = 1
        let date = Calendar.current.date(from: components)!
        try timeParamTestHelper(date)
    }

    func testDurationParam() throws {
        try basicParamTestHelper(TimeInterval(1000000000))
    }

    func testNilParam() throws {
        try basicParamTestHelper(nil)
    }

    func testStructParam() throws {
        let structParam: [String: Any] = [
            "name": "Alice",
            "age": Int64(30),
            "isStudent": false
        ]
        try basicParamTestHelper(structParam)
    }

    func testStructWithNestedStructParam() throws {
        let structParam: [String: Any] = [
            "name": "Alice",
            "address": [
                "city": "New York",
                "country": "USA"
            ] as [String: Any]
        ]
        try basicParamTestHelper(structParam)
    }

    func testStructWithUnsupportedTypeParam() throws {
        let structParam: [String: Any] = [
            "name": "Alice",
            "age": try! NSRegularExpression(pattern: ".*", options: [])
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": structParam])
            XCTFail("Expected error for unsupported type")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("Unsupported Swift type"))
        }
    }

    func testEmptyMapParam() throws {
        let emptyMap: [String: Any] = [:]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": emptyMap])
            XCTFail("Expected error for empty map")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("empty"))
        }
    }

    func testMapParam() throws {
        let mapParam: [(String, Int64)] = [
            ("1", 1),
            ("2", 2),
            ("3", 3)
        ]
        try basicParamTestHelper(mapParam)
    }

    func testMapParamNested() throws {
        let mapParam: [(String, [(String, String)])] = [
            ("1", [("a", "A")]),
            ("2", [("b", "B")]),
            ("3", [("c", "C")])
        ]
        try basicParamTestHelper(mapParam)
    }

    func testMapParamWithUnsupportedType() throws {
        let mapParam: [(String, Any)] = [
            ("1", try! NSRegularExpression(pattern: ".*", options: []))
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": mapParam])
            XCTFail("Expected error for unsupported type")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("Unsupported Swift type"))
        }
    }

    func testMapWithMixedTypesParam() throws {
        let mapParam: [(String, Any)] = [
            ("1", "One"),
            ("2", "Two"),
            ("3", "Three"),
            ("4", 4)
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": mapParam])
            XCTFail("Expected error for mixed types")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("the same type"))
        }
    }

    func testArrayParam() throws {
        let arrayParam: [Any] = ["One", "Two", "Three"]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        XCTAssertEqual(value.count, arrayParam.count)
        for i in 0..<arrayParam.count {
            XCTAssertEqual(value[i] as! String, arrayParam[i] as! String)
        }
        XCTAssertFalse(result.hasNext())
    }

    func testArrayParamNested() throws {
        let arrayParam: [[Any]] = [
            ["a", "A"],
            ["b", "B"],
            ["c", "C"]
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [[Any]]
        XCTAssertEqual(value.count, arrayParam.count)
        for i in 0..<arrayParam.count {
            XCTAssertEqual(value[i].count, arrayParam[i].count)
            for j in 0..<arrayParam[i].count {
                XCTAssertEqual(value[i][j] as! String, arrayParam[i][j] as! String)
            }
        }
        XCTAssertFalse(result.hasNext())
    }

    func testArrayParamNestedStruct() throws {
        let arrayParam: [[String: Any]] = [
            ["name": "Alice", "age": Int64(30)],
            ["name": "Bob", "age": Int64(40)],
            ["name": "Charlie", "age": Int64(50)]
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [[String: Any]]
        XCTAssertEqual(value.count, arrayParam.count)
        for i in 0..<arrayParam.count {
            XCTAssertEqual(value[i].count, arrayParam[i].count)
            for (key, paramValue) in arrayParam[i] {
                let resultValue = value[i][key]!
                if let paramInt = paramValue as? Int64, let resultInt = resultValue as? Int64 {
                    XCTAssertEqual(paramInt, resultInt)
                } else if let paramString = paramValue as? String, let resultString = resultValue as? String {
                    XCTAssertEqual(paramString, resultString)
                } else {
                    XCTFail("Unexpected type in nested struct")
                }
            }
        }
        XCTAssertFalse(result.hasNext())
    }

    func testArrayParamWithUnsupportedType() throws {
        let arrayParam: [Any] = ["One", try! NSRegularExpression(pattern: ".*", options: [])]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": arrayParam])
            XCTFail("Expected error for unsupported type")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("Unsupported Swift type"))
        }
    }

    func testArrayWithMixedTypesParam() throws {
        let arrayParam: [Any] = ["One", "Two", "Three", 4]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": arrayParam])
            XCTFail("Expected error for mixed types")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("are of the same type"))
        }
    }

    func testInt64ArrayParam() throws {
        let arrayParam: [Int64] = [1, 2, 3]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        XCTAssertEqual(value.count, arrayParam.count)
        for i in 0..<arrayParam.count {
            XCTAssertEqual(value[i] as! Int64, arrayParam[i])
        }
        XCTAssertFalse(result.hasNext())
    }

    func testStringArrayParam() throws {
        let arrayParam: [String] = ["One", "Two", "Three"]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        XCTAssertEqual(value.count, arrayParam.count)
        for i in 0..<arrayParam.count {
            XCTAssertEqual(value[i] as! String, arrayParam[i])
        }
        XCTAssertFalse(result.hasNext())
    }

    func testNestedInt64ArrayParam() throws {
        let arrayParam: [[Int64]] = [
            [0, 1, 2, 3],
            [4, 5, 6, 7]
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        XCTAssertTrue(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [[Any]]
        XCTAssertEqual(value.count, arrayParam.count)
        for i in 0..<arrayParam.count {
            XCTAssertEqual(value[i].count, arrayParam[i].count)
            for j in 0..<arrayParam[i].count {
                XCTAssertEqual(value[i][j] as! Int64, arrayParam[i][j])
            }
        }
        XCTAssertFalse(result.hasNext())
    }

    func testDictionaryParam() throws {
        let dictParam: [(String, Int64)] = [
            ("1", 1),
            ("2", 2),
            ("3", 3)
        ]
        try basicParamTestHelper(dictParam)
    }

    func testDictionaryParamNested() throws {
        let dictParam: [(String, [(String, String)])] = [
            ("1", [("a", "A")]),
            ("2", [("b", "B")]),
            ("3", [("c", "C")])
        ]
        try basicParamTestHelper(dictParam)
    }

    func testDictionaryParamWithUnsupportedType() throws {
        let dictParam: [(String, Any)] = [
            ("1", try! NSRegularExpression(pattern: ".*", options: []))
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": dictParam])
            XCTFail("Expected error for unsupported type")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("Unsupported Swift type"))
        }
    }

    func testDictionaryWithMixedTypesParam() throws {
        let dictParam: [(String, Any)] = [
            ("1", "One"),
            ("2", "Two"),
            ("3", "Three"),
            ("4", 4)
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": dictParam])
            XCTFail("Expected error for mixed types")
        } catch let error as KuzuError {
            XCTAssertTrue(error.message.contains("are of the same type"))
        }
    }
}
