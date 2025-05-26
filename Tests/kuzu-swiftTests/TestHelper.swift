//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
import Kuzu

internal func getTestDatabase() throws -> (Database, Connection, String){
    let systemConfig = SystemConfig(
        bufferPoolSize: 256 * 1024 * 1024,
        maxNumThreads: 4,
        enableCompression: true,
        readOnly: false,
        maxDbSize: 16 * 1024 * 1024 * 1024,
        autoCheckpoint: true,
        checkpointThreshold: UInt64.max
    )
    let dbPath = NSTemporaryDirectory() + "kuzu_swift_test_db_" + UUID().uuidString
    let db = try! Database(dbPath, systemConfig)
    let conn = try! Connection(db)
    try initTinySNB(conn: conn)
    return (db, conn, dbPath)
}

private func initTinySNB(conn: Connection) throws {
    // Get absolute path to dataset/tinysnb
    let datasetDir = Bundle.module.url(forResource: "Dataset", withExtension: nil)!
    
    let tinySnbPath = datasetDir
        .appendingPathComponent("tinysnb")
        .standardized.path

    let schemaPath = "\(tinySnbPath)/schema.cypher"
    try executeCypherFromFile(filePath: schemaPath, conn: conn, originalString: nil, replaceString: nil)

    let copyPath = "\(tinySnbPath)/copy.cypher"
    let originalPath = "dataset/tinysnb"
    try executeCypherFromFile(filePath: copyPath, conn: conn, originalString: originalPath, replaceString: tinySnbPath)

    _ = try conn.query("create node table moviesSerial (ID SERIAL, name STRING, length INT32, note STRING, PRIMARY KEY (ID));")

    let moviesSerialPath = "\(tinySnbPath)/vMoviesSerial.csv"
    let moviesSerialCopyQuery = "copy moviesSerial from \"\(moviesSerialPath)\""
    _ = try conn.query(moviesSerialCopyQuery)
}

private func executeCypherFromFile(filePath: String, conn: Connection, originalString: String?, replaceString: String?) throws {
    let content = try String(contentsOfFile: filePath, encoding: .utf8)
    let lines = content.components(separatedBy: .newlines)

    for var line in lines {
        line = line.trimmingCharacters(in: .whitespaces)
        if line.isEmpty {
            continue
        }
        if let original = originalString, let replacement = replaceString {
            line = line.replacingOccurrences(of: original, with: replacement)
        }
        _ = try conn.query(line)
    }
}

internal func deleteTestDatabaseDirectory(_ dbPath: String){
    try? FileManager.default.removeItem(atPath: dbPath)
}
