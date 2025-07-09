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
public final class SystemConfig: @unchecked Sendable {
    internal var cSystemConfig: kuzu_system_config

    /// Creates a new system configuration with default values.
    ///
    /// The default system configuration is as follows:
    /// - bufferPoolSize: 80% of the total system memory on macOS and Linux, 2GB on iOS, 1GB on tvOS, and 128MB on watchOS
    /// - maxNumThreads: Number of CPU cores available in the system
    /// - enableCompression: true
    /// - readOnly: false
    /// - threadQos: QOS_CLASS_DEFAULT (Apple platforms only)
    public init() {
        cSystemConfig = kuzu_default_system_config()
        #if os(iOS)
            cSystemConfig.buffer_pool_size = 2048 * 1024 * 1024
        #endif
        #if os(tvOS)
            cSystemConfig.buffer_pool_size = 1024 * 1024 * 1024
        #endif
        #if os(watchOS)
            cSystemConfig.buffer_pool_size = 128 * 1024 * 1024
        #endif
    }

    /// Creates a new system configuration with the specified parameters.
    ///
    /// - Parameters:
    ///   - bufferPoolSize: The size of the buffer pool in bytes. If 0, uses default (80% of system memory).
    ///   - maxNumThreads: The maximum number of threads that can be used by the database system. If 0, uses default (number of CPU cores).
    ///   - enableCompression: A boolean flag to enable or disable compression. Default is true.
    ///   - readOnly: A boolean flag to open the database in read-only mode. Default is false.
    ///   - autoCheckpoint: Whether to automatically create checkpoints. Default is true.
    ///   - checkpointThreshold: The threshold for creating checkpoints. If set to UInt64.max, uses default value.
    ///   - threadQoS: The thread quality of service (QoS) for the worker threads. This is only available on Apple platforms. The default value is QOS_CLASS_DEFAULT.
    public convenience init(
        bufferPoolSize: UInt64 = 0,
        maxNumThreads: UInt64 = 0,
        enableCompression: Bool = true,
        readOnly: Bool = false,
        autoCheckpoint: Bool = true,
        checkpointThreshold: UInt64 = UInt64.max,
        threadQos: qos_class_t = QOS_CLASS_DEFAULT
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
        cSystemConfig.auto_checkpoint = autoCheckpoint
        if checkpointThreshold > 0 {
            cSystemConfig.checkpoint_threshold = checkpointThreshold
        }
#if !os(Linux)
        
            cSystemConfig.thread_qos = threadQos.rawValue
        #endif
    }
}
