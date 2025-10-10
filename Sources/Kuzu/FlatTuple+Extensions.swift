//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import cxx_kuzu

@_spi(Typed)
extension FlatTuple {
    private func extractKuzu(
        index: Int,
        into cValue: inout kuzu_value
    ) throws -> KuzuValue {
        let state = kuzu_flat_tuple_get_value(&cFlatTuple, UInt64(index), &cValue)
        let value = KuzuValue(ptr: &cValue)
        guard state == KuzuSuccess else {
            throw KuzuError.getValueFailed(
                "Get value failed with error code: \(state)"
            )
        }
        return value
    }
    
    private func checkIndex(_ index: Int) throws {
        let count = queryResult.getColumnCount()
        guard index < count else {
            throw KuzuError.getValueFailed(
                "Index overflow on columns count of \(count)"
            )
        }
    }
    
    public subscript<T>(
        _ index: Int,
        as type: T.Type = T.self
    ) -> T where T: KuzuDecodable {
        get throws {
            try checkIndex(index)
            var cValue = kuzu_value()
            let value = try extractKuzu(index: index, into: &cValue)
            return try T.kuzuDecode(from: value)
        }
    }

    // tuples cannot conform to protocols - helper to not have to specify `KuzuMap<T, U>`
    public subscript<T, U>(
        _ index: Int,
        as type: [(T, U)].Type = [(T, U)].self
    ) -> [(T, U)] where T: KuzuDecodable, U: KuzuDecodable {
        get throws {
            try checkIndex(index)
            var cValue = kuzu_value()
            let value = try extractKuzu(index: index, into: &cValue)
            return try KuzuMap<T, U>.kuzuDecode(from: value).tuples
        }
    }
}
