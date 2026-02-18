import Testing
@testable import GikhCore

@Suite("BiMap")
struct BiMapTests {

    // MARK: - Basic forward lookup

    @Test func forwardLookupReturnsValue() {
        let map = BiMap([("a", 1), ("b", 2), ("c", 3)])
        #expect(map.toValue("a") == 1)
        #expect(map.toValue("b") == 2)
        #expect(map.toValue("c") == 3)
    }

    @Test func forwardLookupMissingKeyReturnsNil() {
        let map = BiMap([("a", 1), ("b", 2)])
        #expect(map.toValue("z") == nil)
    }

    // MARK: - Basic reverse lookup

    @Test func reverseLookupReturnsKey() {
        let map = BiMap([("a", 1), ("b", 2), ("c", 3)])
        #expect(map.toKey(1) == "a")
        #expect(map.toKey(2) == "b")
        #expect(map.toKey(3) == "c")
    }

    @Test func reverseLookupMissingValueReturnsNil() {
        let map = BiMap([("a", 1), ("b", 2)])
        #expect(map.toKey(99) == nil)
    }

    // MARK: - Empty BiMap

    @Test func emptyBiMapForwardReturnsNil() {
        let map = BiMap<String, Int>([])
        #expect(map.toValue("anything") == nil)
    }

    @Test func emptyBiMapReverseReturnsNil() {
        let map = BiMap<String, Int>([])
        #expect(map.toKey(0) == nil)
    }

    // MARK: - Bijectivity enforcement
    // Duplicate values (non-bijective mapping) must be caught at init time.
    // We test via the failable initializer init?(safe:).

    @Test func duplicateValuesAreRejected() {
        let map = BiMap<String, Int>(safe: [("a", 1), ("b", 1)])
        #expect(map == nil)
    }

    @Test func duplicateKeysAreRejected() {
        let map = BiMap<String, Int>(safe: [("a", 1), ("a", 2)])
        #expect(map == nil)
    }

    @Test func uniquePairsAreAccepted() {
        let map = BiMap<String, Int>(safe: [("a", 1), ("b", 2)])
        #expect(map != nil)
        #expect(map?.toValue("a") == 1)
    }

    // MARK: - Round-trip: forward then reverse

    @Test func roundTripForwardThenReverse() {
        let map = BiMap([("func", "פֿונקציע"), ("let", "לאָז"), ("var", "באַשטימען")])
        for (english, yiddish) in [("func", "פֿונקציע"), ("let", "לאָז"), ("var", "באַשטימען")] {
            #expect(map.toValue(english) == yiddish)
            #expect(map.toKey(yiddish) == english)
        }
    }

    @Test func roundTripReverseThenForward() {
        let map = BiMap([(1, "one"), (2, "two"), (3, "three")])
        for (num, word) in [(1, "one"), (2, "two"), (3, "three")] {
            let looked = map.toValue(num)
            #expect(looked == word)
            if let looked {
                #expect(map.toKey(looked) == num)
            }
        }
    }

    // MARK: - Yiddish keyword mappings (representative integration check)

    @Test func yiddishKeywordLookups() {
        let keywords = BiMap([
            ("פֿונקציע", "func"),
            ("לאָז", "let"),
            ("באַשטימען", "var"),
            ("צוריק", "return"),
            ("אויב", "if"),
            ("אַנדערש", "else"),
        ])
        // Yiddish → English
        #expect(keywords.toValue("פֿונקציע") == "func")
        #expect(keywords.toValue("לאָז") == "let")
        // English → Yiddish via reverse
        #expect(keywords.toKey("func") == "פֿונקציע")
        #expect(keywords.toKey("let") == "לאָז")
    }

    // MARK: - Large dictionary performance

    @Test func largeDictionaryLookupPerformance() {
        let pairs = (0..<1000).map { i in ("key_\(i)", i) }
        let map = BiMap(pairs)
        #expect(map.toValue("key_0") == 0)
        #expect(map.toValue("key_500") == 500)
        #expect(map.toValue("key_999") == 999)
        #expect(map.toKey(0) == "key_0")
        #expect(map.toKey(500) == "key_500")
        #expect(map.toKey(999) == "key_999")
        #expect(map.toValue("key_1000") == nil)
        #expect(map.toKey(1000) == nil)
    }

    // MARK: - Generic type variety

    @Test func stringToStringMap() {
        let map: BiMap<String, String> = BiMap([("hello", "שלום"), ("world", "וועלט")])
        #expect(map.toValue("hello") == "שלום")
        #expect(map.toKey("שלום") == "hello")
    }

    @Test func intToIntMap() {
        let map: BiMap<Int, Int> = BiMap([(1, 100), (2, 200), (3, 300)])
        #expect(map.toValue(1) == 100)
        #expect(map.toKey(100) == 1)
    }

    // MARK: - Merge: happy path

    @Test func mergingDisjointMapsSucceeds() throws {
        let keywords = BiMap([("פֿונקציע", "func"), ("לאָז", "let")])
        let project = BiMap([("מענטש", "Person"), ("נאָמען", "name")])
        let merged = try keywords.merging(project, sourceTier: "keywords", incomingTier: "project")
        #expect(merged.toValue("פֿונקציע") == "func")
        #expect(merged.toValue("לאָז") == "let")
        #expect(merged.toValue("מענטש") == "Person")
        #expect(merged.toValue("נאָמען") == "name")
        #expect(merged.toKey("func") == "פֿונקציע")
        #expect(merged.toKey("Person") == "מענטש")
    }

    @Test func mergingEmptyIntoNonEmptySucceeds() throws {
        let base = BiMap([("פֿונקציע", "func")])
        let empty = BiMap<String, String>([])
        let merged = try base.merging(empty, sourceTier: "keywords", incomingTier: "project")
        #expect(merged.toValue("פֿונקציע") == "func")
    }

    @Test func mergingNonEmptyIntoEmptySucceeds() throws {
        let empty = BiMap<String, String>([])
        let other = BiMap([("פֿונקציע", "func")])
        let merged = try empty.merging(other, sourceTier: "base", incomingTier: "keywords")
        #expect(merged.toValue("פֿונקציע") == "func")
    }

    // MARK: - Merge: key collision

    @Test func mergingWithDuplicateKeyThrows() throws {
        let keywords = BiMap([("פֿונקציע", "func"), ("לאָז", "let")])
        // Project tries to redefine "פֿונקציע" with a different English value.
        let project = BiMap([("פֿונקציע", "function")])
        #expect(throws: (any Error).self) {
            _ = try keywords.merging(project, sourceTier: "keywords", incomingTier: "project")
        }
    }

    @Test func mergingWithDuplicateKeyCollisionDescribesConflict() {
        let keywords = BiMap([("פֿונקציע", "func")])
        let project = BiMap([("פֿונקציע", "function")])
        do {
            _ = try keywords.merging(project, sourceTier: "keywords", incomingTier: "project")
            Issue.record("Expected collision to be thrown")
        } catch let collision as BiMapCollision<String, String> {
            #expect(collision.description.contains("keywords"))
            #expect(collision.description.contains("project"))
            #expect(collision.description.contains("פֿונקציע"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Merge: value (bijectivity) collision

    @Test func mergingWithDuplicateValueThrows() throws {
        let keywords = BiMap([("פֿונקציע", "func")])
        // Project maps a different Yiddish key to the same English value "func".
        let project = BiMap([("פֿונקציאָן", "func")])
        #expect(throws: (any Error).self) {
            _ = try keywords.merging(project, sourceTier: "keywords", incomingTier: "project")
        }
    }

    @Test func mergingWithDuplicateValueCollisionDescribesConflict() {
        let keywords = BiMap([("פֿונקציע", "func")])
        let project = BiMap([("פֿונקציאָן", "func")])
        do {
            _ = try keywords.merging(project, sourceTier: "keywords", incomingTier: "project")
            Issue.record("Expected collision to be thrown")
        } catch let collision as BiMapCollision<String, String> {
            #expect(collision.description.contains("keywords"))
            #expect(collision.description.contains("project"))
            #expect(collision.description.contains("func"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Merge: tier labels in collision message

    @Test func collisionMessageIncludesSourceTierLabel() {
        let tier1 = BiMap([("א", "a")])
        let tier2 = BiMap([("א", "b")])
        do {
            _ = try tier1.merging(tier2, sourceTier: "built-in", incomingTier: "user-project")
            Issue.record("Expected collision")
        } catch let collision as BiMapCollision<String, String> {
            #expect(collision.description.contains("built-in"))
            #expect(collision.description.contains("user-project"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Merge: three-tier chain (keywords → ביבליאָטעק → project)

    @Test func mergingThreeTiersWithNoCollisionsSucceeds() throws {
        let keywords = BiMap([("פֿונקציע", "func"), ("לאָז", "let")])
        let bibliotek = BiMap([("מאַסיוו", "Array"), ("סטרינג", "String")])
        let project = BiMap([("מענטש", "Person")])
        let step1 = try keywords.merging(bibliotek, sourceTier: "keywords", incomingTier: "ביבליאָטעק")
        let merged = try step1.merging(project, sourceTier: "keywords+ביבליאָטעק", incomingTier: "project")
        #expect(merged.toValue("פֿונקציע") == "func")
        #expect(merged.toValue("מאַסיוו") == "Array")
        #expect(merged.toValue("מענטש") == "Person")
    }

    @Test func projectCollisionWithBibliotekIsDetected() throws {
        let keywords = BiMap([("פֿונקציע", "func")])
        let bibliotek = BiMap([("מאַסיוו", "Array")])
        let project = BiMap([("מאַסיוו", "Collection")])  // same Yiddish as ביבליאָטעק
        let step1 = try keywords.merging(bibliotek, sourceTier: "keywords", incomingTier: "ביבליאָטעק")
        #expect(throws: (any Error).self) {
            _ = try step1.merging(project, sourceTier: "keywords+ביבליאָטעק", incomingTier: "project")
        }
    }
}
