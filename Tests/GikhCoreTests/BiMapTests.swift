// BiMapTests.swift
// GikhCore — Tests for the BiMap bidirectional dictionary.

import XCTest
@testable import GikhCore

final class BiMapTests: XCTestCase {

    // MARK: - Init from Pairs

    func testInitFromPairs_lookupsWork() {
        let map = BiMap<String, String>([
            ("א", "a"),
            ("ב", "b"),
            ("ג", "c"),
        ])

        XCTAssertEqual(map.toValue("א"), "a")
        XCTAssertEqual(map.toValue("ב"), "b")
        XCTAssertEqual(map.toValue("ג"), "c")

        XCTAssertEqual(map.toKey("a"), "א")
        XCTAssertEqual(map.toKey("b"), "ב")
        XCTAssertEqual(map.toKey("c"), "ג")
    }

    func testInitFromPairs_missingKeyReturnsNil() {
        let map = BiMap<String, String>([("key", "value")])
        XCTAssertNil(map.toValue("missing"))
    }

    func testInitFromPairs_missingValueReturnsNil() {
        let map = BiMap<String, String>([("key", "value")])
        XCTAssertNil(map.toKey("missing"))
    }

    // MARK: - Empty BiMap

    func testEmptyBiMap() {
        let map = BiMap<String, String>()
        XCTAssertTrue(map.isEmpty)
        XCTAssertEqual(map.count, 0)
        XCTAssertNil(map.toValue("anything"))
        XCTAssertNil(map.toKey("anything"))
        XCTAssertTrue(map.allPairs.isEmpty)
    }

    // MARK: - Insert

    func testInsert_succeedsForNewPair() throws {
        var map = BiMap<String, String>()
        try map.insert("key1", "value1")

        XCTAssertEqual(map.toValue("key1"), "value1")
        XCTAssertEqual(map.toKey("value1"), "key1")
        XCTAssertEqual(map.count, 1)
    }

    func testInsert_multipleNewPairs() throws {
        var map = BiMap<String, String>()
        try map.insert("a", "1")
        try map.insert("b", "2")
        try map.insert("c", "3")

        XCTAssertEqual(map.count, 3)
        XCTAssertEqual(map.toValue("b"), "2")
        XCTAssertEqual(map.toKey("3"), "c")
    }

    func testInsert_throwsForDuplicateKey() throws {
        var map = BiMap<String, String>()
        try map.insert("key", "value1")

        XCTAssertThrowsError(try map.insert("key", "value2")) { error in
            guard case BiMapError.duplicateKey = error else {
                XCTFail("Expected BiMapError.duplicateKey, got \(error)")
                return
            }
        }
    }

    func testInsert_throwsForDuplicateValue() throws {
        var map = BiMap<String, String>()
        try map.insert("key1", "value")

        XCTAssertThrowsError(try map.insert("key2", "value")) { error in
            guard case BiMapError.duplicateValue = error else {
                XCTFail("Expected BiMapError.duplicateValue, got \(error)")
                return
            }
        }
    }

    // MARK: - Merged

    func testMerged_succeedsWithoutConflict() throws {
        let map1 = BiMap<String, String>([("a", "1"), ("b", "2")])
        let map2 = BiMap<String, String>([("c", "3"), ("d", "4")])

        let merged = try map1.merged(with: map2)
        XCTAssertEqual(merged.count, 4)
        XCTAssertEqual(merged.toValue("a"), "1")
        XCTAssertEqual(merged.toValue("c"), "3")
        XCTAssertEqual(merged.toKey("4"), "d")
    }

    func testMerged_throwsOnKeyConflict() {
        let map1 = BiMap<String, String>([("a", "1")])
        let map2 = BiMap<String, String>([("a", "2")])

        XCTAssertThrowsError(try map1.merged(with: map2)) { error in
            guard case BiMapError.duplicateKey = error else {
                XCTFail("Expected BiMapError.duplicateKey, got \(error)")
                return
            }
        }
    }

    func testMerged_throwsOnValueConflict() {
        let map1 = BiMap<String, String>([("a", "1")])
        let map2 = BiMap<String, String>([("b", "1")])

        XCTAssertThrowsError(try map1.merged(with: map2)) { error in
            guard case BiMapError.duplicateValue = error else {
                XCTFail("Expected BiMapError.duplicateValue, got \(error)")
                return
            }
        }
    }

    // MARK: - Remove

    func testRemoveKey_removesExistingPair() throws {
        var map = BiMap<String, String>([("a", "1"), ("b", "2")])
        let removed = map.removeKey("a")

        XCTAssertEqual(removed, "1")
        XCTAssertNil(map.toValue("a"))
        XCTAssertNil(map.toKey("1"))
        XCTAssertEqual(map.count, 1)
    }

    func testRemoveKey_returnsNilForMissingKey() {
        var map = BiMap<String, String>([("a", "1")])
        let removed = map.removeKey("missing")
        XCTAssertNil(removed)
        XCTAssertEqual(map.count, 1)
    }

    func testRemoveValue_removesExistingPair() throws {
        var map = BiMap<String, String>([("a", "1"), ("b", "2")])
        let removed = map.removeValue("2")

        XCTAssertEqual(removed, "b")
        XCTAssertNil(map.toValue("b"))
        XCTAssertNil(map.toKey("2"))
        XCTAssertEqual(map.count, 1)
    }

    func testRemoveValue_returnsNilForMissingValue() {
        var map = BiMap<String, String>([("a", "1")])
        let removed = map.removeValue("missing")
        XCTAssertNil(removed)
        XCTAssertEqual(map.count, 1)
    }

    // MARK: - Properties

    func testCount() {
        let map = BiMap<String, String>([("a", "1"), ("b", "2"), ("c", "3")])
        XCTAssertEqual(map.count, 3)
    }

    func testIsEmpty_trueWhenEmpty() {
        let map = BiMap<String, String>()
        XCTAssertTrue(map.isEmpty)
    }

    func testIsEmpty_falseWhenPopulated() {
        let map = BiMap<String, String>([("a", "1")])
        XCTAssertFalse(map.isEmpty)
    }

    func testAllPairs() {
        let map = BiMap<String, String>([("a", "1"), ("b", "2")])
        let pairs = map.allPairs
        XCTAssertEqual(pairs.count, 2)

        let pairsDict = Dictionary(uniqueKeysWithValues: pairs)
        XCTAssertEqual(pairsDict["a"], "1")
        XCTAssertEqual(pairsDict["b"], "2")
    }

    func testKeys() {
        let map = BiMap<String, String>([("a", "1"), ("b", "2")])
        let keys = Set(map.keys)
        XCTAssertEqual(keys, ["a", "b"])
    }

    func testValues() {
        let map = BiMap<String, String>([("a", "1"), ("b", "2")])
        let values = Set(map.values)
        XCTAssertEqual(values, ["1", "2"])
    }

    // MARK: - ContainsKey / ContainsValue

    func testContainsKey() {
        let map = BiMap<String, String>([("a", "1")])
        XCTAssertTrue(map.containsKey("a"))
        XCTAssertFalse(map.containsKey("b"))
    }

    func testContainsValue() {
        let map = BiMap<String, String>([("a", "1")])
        XCTAssertTrue(map.containsValue("1"))
        XCTAssertFalse(map.containsValue("2"))
    }

    // MARK: - Codable Round-Trip

    func testCodableRoundTrip() throws {
        let original = BiMap<String, String>([
            ("פֿונקציע", "func"),
            ("לאָז", "let"),
            ("באַשטימען", "var"),
        ])

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BiMap<String, String>.self, from: data)

        XCTAssertEqual(decoded.count, original.count)
        XCTAssertEqual(decoded.toValue("פֿונקציע"), "func")
        XCTAssertEqual(decoded.toValue("לאָז"), "let")
        XCTAssertEqual(decoded.toValue("באַשטימען"), "var")
        XCTAssertEqual(decoded.toKey("func"), "פֿונקציע")
        XCTAssertEqual(decoded.toKey("let"), "לאָז")
        XCTAssertEqual(decoded.toKey("var"), "באַשטימען")
    }

    func testCodableRoundTrip_emptyBiMap() throws {
        let original = BiMap<String, String>()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BiMap<String, String>.self, from: data)

        XCTAssertTrue(decoded.isEmpty)
        XCTAssertEqual(decoded.count, 0)
    }

    // MARK: - Init from Dictionary

    func testInitFromDictionary() {
        let map = BiMap<String, String>(uniqueKeysWithValues: ["a": "1", "b": "2"])
        XCTAssertEqual(map.count, 2)
        XCTAssertEqual(map.toValue("a"), "1")
        XCTAssertEqual(map.toKey("2"), "b")
    }
}
