//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation

enum KuzuError: Error {
    case databaseInitializationFailed(String)
    case connectionInitializationFailed(String)
    case queryExecutionFailed(String)
    case prepareStatmentFailed(String)
    case valueConversionFailed(String)
    case getFlatTupleFailed(String)
}
