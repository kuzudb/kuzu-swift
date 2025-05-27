//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

/// Represents the configuration of Kuzu database system.
///
/// The configuration includes settings for buffer pool size, thread management,
/// compression, read-only mode, and database size limits.
public final class SystemConfig : @unchecked Sendable{
    internal var cSystemConfig: kuzu_system_config

    /// Creates a new system configuration with default values.
    ///
    /// The default system configuration is as follows:
    /// - BufferPoolSize: 80% of the total system memory
    /// - MaxNumThreads: Number of CPU cores
    /// - EnableCompression: true
    /// - ReadOnly: false
    /// - MaxDbSize: 0 (unlimited)
    public init() {
        cSystemConfig = kuzu_default_system_config()
    }

    /// Creates a new system configuration with the specified parameters.
    ///
    /// - Parameters:
    ///   - bufferPoolSize: The size of the buffer pool in bytes. If 0, uses default (80% of system memory).
    ///   - maxNumThreads: The maximum number of threads that can be used by the database system. If 0, uses default (number of CPU cores).
    ///   - enableCompression: A boolean flag to enable or disable compression. Default is true.
    ///   - readOnly: A boolean flag to open the database in read-only mode. Default is false.
    ///   - maxDbSize: The maximum size of the database in bytes. If 0, size is unlimited.
    ///   - autoCheckpoint: Whether to automatically create checkpoints. Default is true.
    ///   - checkpointThreshold: The threshold for creating checkpoints. If set to UInt64.max, uses default value.
    public convenience init(
        bufferPoolSize: UInt64 = 0,
        maxNumThreads: UInt64 = 0,
        enableCompression: Bool = true,
        readOnly: Bool = false,
        maxDbSize: UInt64 = 0,
        autoCheckpoint: Bool = true,
        checkpointThreshold: UInt64 = UInt64.max
    ) {
        self.init()
        if bufferPoolSize > 0 {
            cSystemConfig.buffer_pool_size = bufferPoolSize
        }
        if maxNumThreads > 0 {
            cSystemConfig.max_num_threads = maxNumThreads
        }
        cSystemConfig.enable_compression = enableCompression
        cSystemConfig.read_only = readOnly
        if maxDbSize > 0 {
            cSystemConfig.max_db_size = maxDbSize
        }
        cSystemConfig.auto_checkpoint = autoCheckpoint
        if checkpointThreshold > 0 {
            cSystemConfig.checkpoint_threshold = checkpointThreshold
        }
    }
}
