//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Foundation
@_implementationOnly import cxx_kuzu

public final class SystemConfig {
    internal var cSystemConfig: kuzu_system_config

    public init() {
        cSystemConfig = kuzu_default_system_config()
    }

    public convenience init(
        bufferPoolSize: UInt64 = 0,
        maxNumThreads: UInt64 = 0,
        enableCompression: Bool = true,
        readOnly: Bool = false,
        maxDbSize: UInt64 = 0,
        autoCheckpoint: Bool = true,
        checkpointThreshold: UInt64 = 0
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
