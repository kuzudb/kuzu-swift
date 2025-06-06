/*
 * This is a template header used for generating the header 'system_config.h'
 * Any value in the format  can be substituted with a value passed into CMakeLists.txt
 * See https://cmake.org/cmake/help/latest/command/configure_file.html for more details
 */

#pragma once

#include <algorithm>
#include <cstdint>

#include "common/enums/extend_direction.h"

#define BOTH_REL_STORAGE 0
#define FWD_REL_STORAGE 1
#define BWD_REL_STORAGE 2

namespace kuzu {
namespace common {

#define VECTOR_CAPACITY_LOG_2 11
#if VECTOR_CAPACITY_LOG_2 > 12
#error "Vector capacity log2 should be less than or equal to 12"
#endif
constexpr uint64_t DEFAULT_VECTOR_CAPACITY = static_cast<uint64_t>(1) << VECTOR_CAPACITY_LOG_2;

// Currently the system supports files with 2 different pages size, which we refer to as
// PAGE_SIZE and TEMP_PAGE_SIZE. PAGE_SIZE is the default size of the page which is the
// unit of read/write to the database files.
static constexpr uint64_t PAGE_SIZE_LOG2 = 12; // Default to 4KB.
static constexpr uint64_t KUZU_PAGE_SIZE = static_cast<uint64_t>(1) << PAGE_SIZE_LOG2;
// Page size for files with large pages, e.g., temporary files that are used by operators that
// may require large amounts of memory.
static constexpr uint64_t TEMP_PAGE_SIZE_LOG2 = 18;
static const uint64_t TEMP_PAGE_SIZE = static_cast<uint64_t>(1) << TEMP_PAGE_SIZE_LOG2;

#define DEFAULT_REL_STORAGE_DIRECTION BOTH_REL_STORAGE
#if DEFAULT_REL_STORAGE_DIRECTION == FWD_REL_STORAGE
static constexpr ExtendDirection DEFAULT_EXTEND_DIRECTION = ExtendDirection::FWD;
#elif DEFAULT_REL_STORAGE_DIRECTION == BWD_REL_STORAGE
static constexpr ExtendDirection DEFAULT_EXTEND_DIRECTION = ExtendDirection::BWD;
#else
static constexpr ExtendDirection DEFAULT_EXTEND_DIRECTION = ExtendDirection::BOTH;
#endif

struct StorageConfig {
    static constexpr uint64_t NODE_GROUP_SIZE_LOG2 = 17;
    static constexpr uint64_t NODE_GROUP_SIZE = static_cast<uint64_t>(1) << NODE_GROUP_SIZE_LOG2;
    // The number of CSR lists in a leaf region.
    static constexpr uint64_t CSR_LEAF_REGION_SIZE_LOG2 =
        std::min(static_cast<uint64_t>(10), NODE_GROUP_SIZE_LOG2 - 1);
    static constexpr uint64_t CSR_LEAF_REGION_SIZE = static_cast<uint64_t>(1)
                                                     << CSR_LEAF_REGION_SIZE_LOG2;
    static constexpr uint64_t CHUNKED_NODE_GROUP_CAPACITY =
        std::min(static_cast<uint64_t>(2048), NODE_GROUP_SIZE);
};

struct OrderByConfig {
    static constexpr uint64_t MIN_SIZE_TO_REDUCE = common::DEFAULT_VECTOR_CAPACITY * 5;
};

struct CopyConfig {
    static constexpr uint64_t PANDAS_PARTITION_COUNT = 50 * DEFAULT_VECTOR_CAPACITY;
};

} // namespace common
} // namespace kuzu

#undef BOTH_REL_STORAGE
#undef FWD_REL_STORAGE
#undef BWD_REL_STORAGE
