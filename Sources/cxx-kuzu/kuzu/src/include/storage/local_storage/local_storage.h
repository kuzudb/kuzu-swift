#pragma once

#include <shared_mutex>
#include <unordered_map>

#include "common/copy_constructors.h"
#include "storage/local_storage/local_table.h"
#include "storage/optimistic_allocator.h"

namespace kuzu {
namespace main {
class ClientContext;
} // namespace main
namespace storage {
// LocalStorage is now thread-safe for concurrent access during transaction commit.
// Multiple TaskScheduler worker threads can safely access LocalStorage simultaneously.
// All data structures are protected by appropriate synchronization primitives.
class LocalStorage {
public:
    explicit LocalStorage(main::ClientContext& clientContext) : clientContext{clientContext} {}
    DELETE_COPY_AND_MOVE(LocalStorage);

    // Do nothing if the table already exists, otherwise create a new local table.
    LocalTable* getOrCreateLocalTable(Table& table);
    // Return nullptr if no local table exists.
    LocalTable* getLocalTable(common::table_id_t tableID) const;

    PageAllocator* addOptimisticAllocator();

    void commit();
    void rollback();

private:
    main::ClientContext& clientContext;
    mutable std::shared_mutex storageMutex;  // Protects tables map
    std::unordered_map<common::table_id_t, std::unique_ptr<LocalTable>> tables;

    // The mtx mutex is only needed when working with the optimistic allocators
    std::mutex mtx;
    std::vector<std::unique_ptr<OptimisticAllocator>> optimisticAllocators;
};

} // namespace storage
} // namespace kuzu
