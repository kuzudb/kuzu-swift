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
struct ParameterTests: ~Copyable {
    var db: Database!
    var conn: Connection!
    var path: String

    init() {
        (db, conn, path) = try! getTestDatabase()
    }

    deinit {
        deleteTestDatabaseDirectory(path)
    }

    func basicParamTestHelper(_ param: Any?) throws {
        let preparedStatement = try conn.prepare("RETURN $1")
        let params = ["1": param]
        let result = try conn.execute(preparedStatement, params)
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        
        if param == nil && value == nil{
            return
        }
        
        // Handle different types explicitly
        switch (param, value) {
        case (let p as String, let v as String):
            #expect(p == v)
        case (let p as Bool, let v as Bool):
            #expect(p == v)
        case (let p as Int64, let v as Int64):
            #expect(p == v)
        case (let p as Int32, let v as Int32):
            #expect(p == v)
        case (let p as Int16, let v as Int16):
            #expect(p == v)
        case (let p as Int8, let v as Int8):
            #expect(p == v)
        case (let p as UInt64, let v as UInt64):
            #expect(p == v)
        case (let p as KuzuUInt32Wrapper, let v as UInt32):
            #expect(p.value == v)
        case (let p as KuzuUInt16Wrapper, let v as UInt16):
            #expect(p.value == v)
        case (let p as KuzuUInt8Wrapper, let v as UInt8):
            #expect(p.value == v)
        case (let p as TimeInterval, let v as TimeInterval):
            #expect(p == v)
        case (is NSNull, is NSNull):
            // Both are NSNull, which is what we want
            break
        case (let p as [String: Any], let v as [String: Any]):
            #expect(p.count == v.count)
            for (key, pValue) in p {
                guard v[key] != nil else {
                    #expect(Bool(false), "Missing key in result: \(key)")
                    continue
                }
                try basicParamTestHelper(pValue)
            }
        case (let p as [(String, Any)], let v as [(String, Any)]):
            #expect(p.count == v.count)
            for i in 0..<p.count {
                #expect(p[i].0 == v[i].0)
                try basicParamTestHelper(p[i].1)
            }
        case (let p as [Any], let v as [Any]):
            #expect(p.count == v.count)
            for i in 0..<p.count {
                try basicParamTestHelper(p[i])
            }
        default:
            #expect(Bool(false), "Type mismatch: expected \(type(of: param!)), got \(type(of: value!))")
        }
    }

    func floatParamTestHelper(_ param: Any) throws {
        let preparedStatement = try conn.prepare("RETURN $1")
        let params = ["1": param]
        let result = try conn.execute(preparedStatement, params)
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0)
        if let floatValue = value as? Double, let paramValue = param as? Double {
            #expect(abs(floatValue - paramValue) < 0.000001)
        } else if let floatValue = value as? Float, let paramValue = param as? Float {
            #expect(abs(floatValue - paramValue) < 0.000001)
        } else {
            #expect(Bool(false), "Type mismatch in floatParamTestHelper")
        }
    }

    func timeParamTestHelper(_ param: Date) throws {
        let preparedStatement = try conn.prepare("RETURN $1")
        let params = ["1": param]
        let result = try conn.execute(preparedStatement, params)
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! Date
        #expect(value == param)
    }

    @Test
    func testStringParam() throws {
        try basicParamTestHelper("Hello World")
    }

    @Test
    func testBoolParam() throws {
        try basicParamTestHelper(true)
        try basicParamTestHelper(false)
    }

    @Test
    func testInt64Param() throws {
        try basicParamTestHelper(Int64(1000000000000))
    }

    @Test
    func testInt32Param() throws {
        try basicParamTestHelper(Int32(200))
    }

    @Test
    func testInt16Param() throws {
        try basicParamTestHelper(Int16(300))
    }

    @Test
    func testInt8Param() throws {
        try basicParamTestHelper(Int8(4))
    }

    @Test
    func testUint64Param() throws {
        try basicParamTestHelper(UInt64.max)
    }

    @Test
    func testUint32Param() throws {
        try basicParamTestHelper(KuzuUInt32Wrapper(value: 600))
    }

    @Test
    func testUint16Param() throws {
        try basicParamTestHelper(KuzuUInt16Wrapper(value: 700))
    }

    @Test
    func testUint8Param() throws {
        try basicParamTestHelper(KuzuUInt8Wrapper(value: 8))
    }

    @Test
    func testDoubleParam() throws {
        try floatParamTestHelper(Double(3.14159235))
    }

    @Test
    func testFloatParam() throws {
        try floatParamTestHelper(Float(2.71828))
    }

    @Test
    func testTimeParam() throws {
        let date = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        try timeParamTestHelper(date)
    }

    @Test
    func testTimeWithNanosecondsParam() throws {
        var components = DateComponents()
        components.year = 2020
        components.month = 1
        components.day = 1
        components.nanosecond = 1
        let date = Calendar.current.date(from: components)!
        try timeParamTestHelper(date)
    }

    @Test
    func testDurationParam() throws {
        try basicParamTestHelper(TimeInterval(1000000000))
    }

    @Test
    func testNilParam() throws {
        try basicParamTestHelper(nil)
    }

    @Test
    func testStructParam() throws {
        let structParam: [String: Any] = [
            "name": "Alice",
            "age": Int64(30),
            "isStudent": false
        ]
        try basicParamTestHelper(structParam)
    }

    @Test
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

    @Test
    func testStructWithUnsupportedTypeParam() throws {
        let structParam: [String: Any] = [
            "name": "Alice",
            "age": try! NSRegularExpression(pattern: ".*", options: [])
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": structParam])
            #expect(Bool(false), "Expected error for unsupported type")
        } catch let error as KuzuError{
            #expect(error.message.contains("Unsupported Swift type"))
        }
    }

    @Test
    func testEmptyMapParam() throws {
        let emptyMap: [String: Any] = [:]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": emptyMap])
            #expect(Bool(false), "Expected error for empty map")
        } catch let error as KuzuError{
            #expect(error.message.contains("empty"))
        }
    }

    @Test
    func testMapParam() throws {
        let mapParam: [(String, Int64)] = [
            ("1", 1),
            ("2", 2),
            ("3", 3)
        ]
        try basicParamTestHelper(mapParam)
    }

    @Test
    func testMapParamNested() throws {
        let mapParam: [(String, [(String, String)])] = [
            ("1", [("a", "A")]),
            ("2", [("b", "B")]),
            ("3", [("c", "C")])
        ]
        try basicParamTestHelper(mapParam)
    }

    @Test
    func testMapParamWithUnsupportedType() throws {
        let mapParam: [(String, Any)] = [
            ("1", try! NSRegularExpression(pattern: ".*", options: []))
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": mapParam])
            #expect(Bool(false), "Expected error for unsupported type")
        } catch let error as KuzuError{
            #expect(error.message.contains("Unsupported Swift type"))
        }
    }

    @Test
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
            #expect(Bool(false), "Expected error for mixed types")
        } catch let error as KuzuError{
            #expect(error.message.contains("the same type"))
        }    }

    @Test
    func testArrayParam() throws {
        let arrayParam: [Any] = ["One", "Two", "Three"]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        #expect(value.count == arrayParam.count)
        for i in 0..<arrayParam.count {
            #expect(value[i] as! String == arrayParam[i] as! String)
        }
        #expect(!result.hasNext())
    }

    @Test
    func testArrayParamNested() throws {
        let arrayParam: [[Any]] = [
            ["a", "A"],
            ["b", "B"],
            ["c", "C"]
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [[Any]]
        #expect(value.count == arrayParam.count)
        for i in 0..<arrayParam.count {
            #expect(value[i].count == arrayParam[i].count)
            for j in 0..<arrayParam[i].count {
                #expect(value[i][j] as! String == arrayParam[i][j] as! String)
            }
        }
        #expect(!result.hasNext())
    }

    @Test
    func testArrayParamNestedStruct() throws {
        let arrayParam: [[String: Any]] = [
            ["name": "Alice", "age": Int64(30)],
            ["name": "Bob", "age": Int64(40)],
            ["name": "Charlie", "age": Int64(50)]
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [[String: Any]]
        #expect(value.count == arrayParam.count)
        for i in 0..<arrayParam.count {
            #expect(value[i].count == arrayParam[i].count)
            for (key, paramValue) in arrayParam[i] {
                let resultValue = value[i][key]!
                if let paramInt = paramValue as? Int64, let resultInt = resultValue as? Int64 {
                    #expect(paramInt == resultInt)
                } else if let paramString = paramValue as? String, let resultString = resultValue as? String {
                    #expect(paramString == resultString)
                } else {
                    #expect(Bool(false), "Unexpected type in nested struct")
                }
            }
        }
        #expect(!result.hasNext())
    }

    @Test
    func testArrayParamWithUnsupportedType() throws {
        let arrayParam: [Any] = ["One", try! NSRegularExpression(pattern: ".*", options: [])]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": arrayParam])
            #expect(Bool(false), "Expected error for unsupported type")
                 } catch let error as KuzuError{
            #expect(error.message.contains("Unsupported Swift type"))
        }
    }

    @Test
    func testArrayWithMixedTypesParam() throws {
        let arrayParam: [Any] = ["One", "Two", "Three", 4]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": arrayParam])
            #expect(Bool(false), "Expected error for mixed types")
        } catch let error as KuzuError{
            #expect(error.message.contains("are of the same type"))
        }
    }

    @Test
    func testInt64ArrayParam() throws {
        let arrayParam: [Int64] = [1, 2, 3]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        #expect(value.count == arrayParam.count)
        for i in 0..<arrayParam.count {
            #expect(value[i] as! Int64 == arrayParam[i])
        }
        #expect(!result.hasNext())
    }

    @Test
    func testStringArrayParam() throws {
        let arrayParam: [String] = ["One", "Two", "Three"]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [Any]
        #expect(value.count == arrayParam.count)
        for i in 0..<arrayParam.count {
            #expect(value[i] as! String == arrayParam[i])
        }
        #expect(!result.hasNext())
    }

    @Test
    func testNestedInt64ArrayParam() throws {
        let arrayParam: [[Int64]] = [
            [0, 1, 2, 3],
            [4, 5, 6, 7]
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        let result = try conn.execute(preparedStatement, ["1": arrayParam])
        #expect(result.hasNext())
        let tuple = try result.getNext()!
        let value = try tuple.getValue(0) as! [[Any]]
        #expect(value.count == arrayParam.count)
        for i in 0..<arrayParam.count {
            #expect(value[i].count == arrayParam[i].count)
            for j in 0..<arrayParam[i].count {
                #expect(value[i][j] as! Int64 == arrayParam[i][j])
            }
        }
        #expect(!result.hasNext())
    }

    @Test
    func testDictionaryParam() throws {
        let dictParam: [(String, Int64)] = [
            ("1", 1),
            ("2", 2),
            ("3", 3)
        ]
        try basicParamTestHelper(dictParam)
    }

    @Test
    func testDictionaryParamNested() throws {
        let dictParam: [(String, [(String, String)])] = [
            ("1", [("a", "A")]),
            ("2", [("b", "B")]),
            ("3", [("c", "C")])
        ]
        try basicParamTestHelper(dictParam)
    }

    @Test
    func testDictionaryParamWithUnsupportedType() throws {
        let dictParam: [(String, Any)] = [
            ("1", try! NSRegularExpression(pattern: ".*", options: []))
        ]
        let preparedStatement = try conn.prepare("RETURN $1")
        do {
            _ = try conn.execute(preparedStatement, ["1": dictParam])
            #expect(Bool(false), "Expected error for unsupported type")
        }  catch let error as KuzuError{
            #expect(error.message.contains("Unsupported Swift type"))
        }
    }

    @Test
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
            #expect(Bool(false), "Expected error for mixed types")
         } catch let error as KuzuError{
            #expect(error.message.contains("are of the same type"))
        }
    }
}
