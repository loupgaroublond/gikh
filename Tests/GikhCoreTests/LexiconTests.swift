// LexiconTests.swift
// GikhCore — Tests for the Lexicon dictionary stack.

import XCTest
@testable import GikhCore

final class LexiconTests: XCTestCase {

    // MARK: - forCompilation

    func testForCompilation_hasKeywords() {
        let lexicon = Lexicon.forCompilation()
        XCTAssertFalse(lexicon.keywords.isEmpty)
        XCTAssertEqual(lexicon.keywords.toValue("פֿונקציע"), "func")
    }

    func testForCompilation_hasEmptyIdentifiers() {
        let lexicon = Lexicon.forCompilation()
        XCTAssertTrue(lexicon.identifiers.isEmpty)
    }

    func testForCompilation_acceptsBibliotekMappings() {
        let bib = BiMap<String, String>([("דרוקן", "print")])
        let lexicon = Lexicon.forCompilation(bibliotekMappings: bib)

        XCTAssertEqual(lexicon.bibliotek.toValue("דרוקן"), "print")
        XCTAssertTrue(lexicon.identifiers.isEmpty)
    }

    // MARK: - forDeveloper

    func testForDeveloper_hasAllTiers() throws {
        let bib = BiMap<String, String>([("דרוקן", "print")])
        let ids = BiMap<String, String>([("נאָמען", "name")])
        let lexicon = try Lexicon.forDeveloper(
            bibliotekMappings: bib,
            projectIdentifiers: ids
        )

        XCTAssertFalse(lexicon.keywords.isEmpty)
        XCTAssertEqual(lexicon.bibliotek.toValue("דרוקן"), "print")
        XCTAssertEqual(lexicon.identifiers.toValue("נאָמען"), "name")
    }

    func testForDeveloper_emptyDictionaries() throws {
        let lexicon = try Lexicon.forDeveloper()
        XCTAssertFalse(lexicon.keywords.isEmpty)
        XCTAssertFalse(lexicon.bibliotek.isEmpty, "Default bibliotek should be BibliotekMappings")
        XCTAssertTrue(lexicon.identifiers.isEmpty)
    }

    func testForDeveloper_throwsOnCollisionWithKeyword_key() {
        // "פֿונקציע" is already a keyword key
        let bib = BiMap<String, String>([("פֿונקציע", "myFunc")])

        XCTAssertThrowsError(try Lexicon.forDeveloper(bibliotekMappings: bib)) { error in
            guard case LexiconError.collision = error else {
                XCTFail("Expected LexiconError.collision, got \(error)")
                return
            }
        }
    }

    func testForDeveloper_throwsOnCollisionWithKeyword_value() {
        // "func" is already a keyword value
        let ids = BiMap<String, String>([("מיין_פֿונקציע", "func")])

        XCTAssertThrowsError(
            try Lexicon.forDeveloper(projectIdentifiers: ids)
        ) { error in
            guard case LexiconError.collision = error else {
                XCTFail("Expected LexiconError.collision, got \(error)")
                return
            }
        }
    }

    func testForDeveloper_throwsOnBibliotekIdentifierConflict() {
        let bib = BiMap<String, String>([("דרוקן", "print")])
        let ids = BiMap<String, String>([("דרוקן", "printAlt")])

        XCTAssertThrowsError(
            try Lexicon.forDeveloper(bibliotekMappings: bib, projectIdentifiers: ids)
        ) { error in
            // This should throw BiMapError.duplicateKey from the merge
            guard case BiMapError.duplicateKey = error else {
                XCTFail("Expected BiMapError.duplicateKey, got \(error)")
                return
            }
        }
    }

    // MARK: - translate()

    func testTranslate_findsInKeywordsTier() {
        let lexicon = Lexicon.forCompilation()

        let result = lexicon.translate("פֿונקציע", direction: .toEnglish)
        XCTAssertEqual(result, "func")
    }

    func testTranslate_findsInKeywordsTier_toYiddish() {
        let lexicon = Lexicon.forCompilation()

        let result = lexicon.translate("func", direction: .toYiddish)
        XCTAssertEqual(result, "פֿונקציע")
    }

    func testTranslate_findsInBibliotekTier() throws {
        let bib = BiMap<String, String>([("דרוקן", "print")])
        let lexicon = try Lexicon.forDeveloper(bibliotekMappings: bib)

        let result = lexicon.translate("דרוקן", direction: .toEnglish)
        XCTAssertEqual(result, "print")
    }

    func testTranslate_findsInIdentifiersTier() throws {
        let ids = BiMap<String, String>([("נאָמען", "name")])
        let lexicon = try Lexicon.forDeveloper(projectIdentifiers: ids)

        let result = lexicon.translate("נאָמען", direction: .toEnglish)
        XCTAssertEqual(result, "name")
    }

    func testTranslate_returnsNilForUnknown() {
        let lexicon = Lexicon.forCompilation()

        let result = lexicon.translate("unknownWord", direction: .toEnglish)
        XCTAssertNil(result)
    }

    func testTranslate_returnsNilForUnknown_toYiddish() {
        let lexicon = Lexicon.forCompilation()

        let result = lexicon.translate("unknownWord", direction: .toYiddish)
        XCTAssertNil(result)
    }

    // MARK: - Priority: keywords > bibliotek > identifiers

    func testTranslate_keywordsHavePriorityOverBibliotek() throws {
        // If the same Yiddish word appears in both keywords and bibliotek,
        // keywords should take precedence. However, forDeveloper would reject
        // collisions, so we construct the Lexicon directly.
        let lexicon = Lexicon(
            keywords: BiMap([("אמת", "true")]),
            bibliotek: BiMap([("אמת2", "trueAlt")]),
            identifiers: BiMap()
        )

        // Keywords tier has "אמת" -> "true"
        let result = lexicon.translate("אמת", direction: .toEnglish)
        XCTAssertEqual(result, "true")
    }

    func testTranslate_bibliotekHasPriorityOverIdentifiers() throws {
        let lexicon = Lexicon(
            keywords: BiMap(),
            bibliotek: BiMap([("דרוקן", "print")]),
            identifiers: BiMap([("דרוקן2", "printAlt")])
        )

        let result = lexicon.translate("דרוקן", direction: .toEnglish)
        XCTAssertEqual(result, "print")

        let result2 = lexicon.translate("דרוקן2", direction: .toEnglish)
        XCTAssertEqual(result2, "printAlt")
    }

    // MARK: - Direct Init

    func testDirectInit() {
        let lexicon = Lexicon(
            keywords: BiMap([("א", "a")]),
            bibliotek: BiMap([("ב", "b")]),
            identifiers: BiMap([("ג", "c")])
        )

        XCTAssertEqual(lexicon.keywords.count, 1)
        XCTAssertEqual(lexicon.bibliotek.count, 1)
        XCTAssertEqual(lexicon.identifiers.count, 1)
    }
}
