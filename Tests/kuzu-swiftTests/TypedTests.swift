//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import Testing
@testable @_spi(Typed) import Kuzu

@Suite
struct TypedTests {
    let conn: Connection
    
    init() throws {
        let db = try Database()
        self.conn = try Connection(db)
    }
    
    @Test
    func testExecutePrimatives() throws {
        let stmt = try conn.prepare("""
            RETURN 
                $bool,
                $int8,
                $uint8,
                $int16,
                $uint16,
                $int32,
                $uint32,
                $int64,
                $uint64,
                $float,
                $double,
                $string,
                TIMESTAMP($date),
                INTERVAL($interval),
                UUID($uuid)
                ;
            """)
        let result = try conn.execute_(stmt, [
            "bool": true,
            "int8": Int8(8),
            "uint8": UInt8(8),
            "int16": Int16(16),
            "uint16": UInt16(16),
            "int32": Int32(32),
            "uint32": UInt32(32),
            "int64": Int64(64),
            "uint64": UInt64(64),
            "float": 3.14,
            "double": 3.14159,
            "string": "hello",
            "date": Date(timeIntervalSince1970: 3600),
            "interval": KuzuInterval(1000.0),
            "uuid": UUID(uuidString: "83313081-D4D3-4175-B118-BCCE83E708D1")
        ])

        let tuple = try #require(try result.getNext())
        #expect(try tuple[0])
        #expect(try tuple[1, as: Int8.self] == 8)
        #expect(try tuple[2, as: UInt8.self] == 8)
        #expect(try tuple[3, as: Int16.self] == 16)
        #expect(try tuple[4, as: UInt16.self] == 16)
        #expect(try tuple[5, as: Int32.self] == 32)
        #expect(try tuple[6, as: UInt32.self] == 32)
        #expect(try tuple[7, as: Int64.self] == 64)
        #expect(try tuple[8, as: UInt64.self] == 64)
        #expect(try tuple[9, as: Double.self] == 3.14)
        #expect(try tuple[10, as: Double.self] == 3.14159)
        #expect(try tuple[11, as: String.self] == "hello")
        #expect(try tuple[12, as: Date.self].timeIntervalSince1970 == 3600)
        #expect(try tuple[13, as: KuzuInterval.self].micros == 1000000000)
        #expect(try tuple[14, as: UUID.self] == UUID(uuidString: "83313081-D4D3-4175-B118-BCCE83E708D1"))
    }
    
    @Test
    func testExecuteNil() throws {
        let stmt = try conn.prepare("""
            RETURN 
                $nilInt32,
                $notNilInt32,
                $nilString,
                $notNilString
                ;
            """)
        let result = try conn.execute_(stmt, [
            "nilInt32": nil as Int32?,
            "notNilInt32": 1 as Int32?,
            "nilString": nil as String?,
            "notNilString": "hello" as String?
        ])

        let tuple = try #require(try result.getNext())
        #expect(try tuple[0, as: Int32?.self] == nil)
        #expect(try tuple[1, as: Int32?.self] == 1)
        #expect(try tuple[2, as: String?.self] == nil)
        #expect(try tuple[3, as: String?.self] == "hello")
    }
    
    @Test
    func testExecuteList() throws {
        let stmt = try conn.prepare("""
            RETURN 
                $intList,
                $stringList
                ;
            """)
        let result = try conn.execute_(stmt, [
            "intList": [1, 2, 3],
            "stringList": ["hi", "there"],
        ])

        let tuple = try #require(try result.getNext())
        #expect(try tuple[0, as: [Double].self] == [1, 2, 3])
        #expect(try tuple[1, as: [String].self] == ["hi", "there"])
    }
    
    @Test
    func testExecuteStruct() throws {
        let stmt = try conn.prepare("""
            RETURN 
                $intStruct, 
                $stringStruct
                ;
            """)
        let result = try conn.execute_(stmt, [
            "intStruct": ["1": 1, "2": 2],
            "stringStruct": ["1": "1", "2": "2"]
        ])
        
        let tuple = try #require(try result.getNext())
        #expect(try tuple[0, as: [String: Double].self] == ["1": 1, "2": 2])
        #expect(try tuple[1, as: [String: String].self] == ["1": "1", "2": "2"])
    }
    
    @Test
    func testExecuteMap() throws {
        let stmt = try conn.prepare("""
            RETURN 
                $map1, 
                $map2
                ;
            """)
        let result = try conn.execute_(stmt, [
            "map1": KuzuMap([("1", 1), ("2", 2)]),
            "map2": KuzuMap([("1", "1"), ("2", "2")])
        ])

        let tuple = try #require(try result.getNext())
        let map1 = try tuple[0, as: [(String, Double)].self]
        #expect(map1.map(\.0) == ["1", "2"])
        #expect(map1.map(\.1) == [1, 2])
        let map2 = try tuple[1, as: KuzuMap<String, String>.self]
        #expect(map2.tuples.map(\.0) == ["1", "2"])
        #expect(map2.tuples.map(\.1) == ["1", "2"])
    }
}
