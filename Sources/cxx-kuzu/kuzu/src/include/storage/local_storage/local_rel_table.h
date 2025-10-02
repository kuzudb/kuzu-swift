#pragma once

#include <map>
#include <shared_mutex>
#include <unordered_map>

#include "common/enums/rel_direction.h"
#include "storage/local_storage/local_table.h"
#include "storage/table/csr_node_group.h"

namespace kuzu {
namespace storage {
class MemoryManager;

static constexpr common::column_id_t LOCAL_BOUND_NODE_ID_COLUMN_ID = 0;
static constexpr common::column_id_t LOCAL_NBR_NODE_ID_COLUMN_ID = 1;
static constexpr common::column_id_t LOCAL_REL_ID_COLUMN_ID = 2;

class RelTable;
struct TableScanState;
struct RelTableUpdateState;

struct DirectedCSRIndex {
    using index_t = std::map<common::offset_t, row_idx_vec_t>;

    explicit DirectedCSRIndex(common::RelDataDirection direction) : direction(direction) {}

    bool isEmpty() const { return index.empty(); }
    void clear() { index.clear(); }

    common::RelDataDirection direction;
    index_t index;
};

class LocalRelTable final : public LocalTable {
public:
    LocalRelTable(const catalog::TableCatalogEntry* tableEntry, const Table& table,
        MemoryManager& mm);
    DELETE_COPY_AND_MOVE(LocalRelTable);

    bool insert(transaction::Transaction* transaction, TableInsertState& state) override;
    bool update(transaction::Transaction* transaction, TableUpdateState& state) override;
    bool delete_(transaction::Transaction* transaction, TableDeleteState& state) override;
    bool addColumn(TableAddColumnState& addColumnState) override;

    bool checkIfNodeHasRels(common::ValueVector* srcNodeIDVector,
        common::RelDataDirection direction) const;

    common::TableType getTableType() const override { return common::TableType::REL; }

    static void initializeScan(TableScanState& state);
    bool scan(const transaction::Transaction* transaction, TableScanState& state) const;

    void clear(MemoryManager&) override {
        localNodeGroup.reset();
        for (auto& [_, index] : directedIndices) {
            index.clear();
        }
    }
    bool isEmpty() const {
        KU_ASSERT(!directedIndices.empty());
        // Check if all indices are empty (should be consistent)
        for (const auto& [_, index] : directedIndices) {
            if (!index.isEmpty()) {
                return false;
            }
        }
        return true;
    }

    common::column_id_t getNumColumns() const { return localNodeGroup->getDataTypes().size(); }
    common::row_idx_t getNumTotalRows() override { return localNodeGroup->getNumRows(); }

    DirectedCSRIndex::index_t& getCSRIndex(common::RelDataDirection direction) {
        KU_ASSERT(directedIndices.contains(direction));
        return directedIndices.at(direction).index;
    }
    NodeGroup& getLocalNodeGroup() const { return *localNodeGroup; }

    static std::vector<common::column_id_t> rewriteLocalColumnIDs(
        common::RelDataDirection direction, const std::vector<common::column_id_t>& columnIDs);
    static common::column_id_t rewriteLocalColumnID(common::RelDataDirection direction,
        common::column_id_t columnID);

private:
    common::row_idx_t findMatchingRow(const transaction::Transaction* transaction,
        const std::vector<row_idx_vec_t*>& rowIndicesToCheck, common::offset_t relOffset) const;

private:
    // We don't duplicate local rel tuples. Tuples are stored same as node tuples.
    // Chunks stored in local rel table are organized as follows:
    // [srcNodeID, dstNodeID, relID, property1, property2, ...]
    // All local rel tuples are stored in a single node group, and they are indexed by src/dst
    // NodeID.
    mutable std::shared_mutex mutex;  // Protects directedIndices and localNodeGroup
    std::unordered_map<common::RelDataDirection, DirectedCSRIndex> directedIndices;
    std::unique_ptr<NodeGroup> localNodeGroup;
};

} // namespace storage
} // namespace kuzu
