// KeywordsTests.swift
// GikhCore — Tests for the compiled-in keyword dictionary.

import XCTest
@testable import GikhCore

final class KeywordsTests: XCTestCase {

    // MARK: - Dictionary is Not Empty

    func testDictionaryIsNotEmpty() {
        XCTAssertFalse(Keywords.dictionary.isEmpty)
        XCTAssertGreaterThan(Keywords.dictionary.count, 0)
    }

    // MARK: - Spot-Check Expected Keywords

    func testKeywordMapping_func() {
        XCTAssertEqual(Keywords.dictionary.toValue("פֿונקציע"), "func")
        XCTAssertEqual(Keywords.dictionary.toKey("func"), "פֿונקציע")
    }

    func testKeywordMapping_let() {
        XCTAssertEqual(Keywords.dictionary.toValue("לאָז"), "let")
        XCTAssertEqual(Keywords.dictionary.toKey("let"), "לאָז")
    }

    func testKeywordMapping_var() {
        XCTAssertEqual(Keywords.dictionary.toValue("באַשטימען"), "var")
        XCTAssertEqual(Keywords.dictionary.toKey("var"), "באַשטימען")
    }

    func testKeywordMapping_return() {
        XCTAssertEqual(Keywords.dictionary.toValue("צוריק"), "return")
    }

    func testKeywordMapping_if() {
        XCTAssertEqual(Keywords.dictionary.toValue("אויב"), "if")
    }

    func testKeywordMapping_else() {
        XCTAssertEqual(Keywords.dictionary.toValue("אַנדערש"), "else")
    }

    func testKeywordMapping_struct() {
        XCTAssertEqual(Keywords.dictionary.toValue("סטרוקטור"), "struct")
    }

    func testKeywordMapping_class() {
        XCTAssertEqual(Keywords.dictionary.toValue("קלאַס"), "class")
    }

    func testKeywordMapping_protocol() {
        XCTAssertEqual(Keywords.dictionary.toValue("פּראָטאָקאָל"), "protocol")
    }

    func testKeywordMapping_import() {
        XCTAssertEqual(Keywords.dictionary.toValue("אימפּאָרט"), "import")
    }

    func testKeywordMapping_true() {
        XCTAssertEqual(Keywords.dictionary.toValue("אמת"), "true")
    }

    func testKeywordMapping_false() {
        XCTAssertEqual(Keywords.dictionary.toValue("פֿאַלש"), "false")
    }

    func testKeywordMapping_nil() {
        XCTAssertEqual(Keywords.dictionary.toValue("גאָרנישט"), "nil")
    }

    func testKeywordMapping_self() {
        XCTAssertEqual(Keywords.dictionary.toValue("זיך"), "self")
    }

    func testKeywordMapping_super() {
        XCTAssertEqual(Keywords.dictionary.toValue("העכער"), "super")
    }

    // MARK: - swiftKeywords Set

    func testSwiftKeywordsContainsExpected() {
        let expected = ["func", "let", "var", "return", "if", "else", "struct",
                        "class", "enum", "protocol", "import", "for", "while",
                        "guard", "switch", "case", "break"]
        for keyword in expected {
            XCTAssertTrue(
                Keywords.swiftKeywords.contains(keyword),
                "swiftKeywords should contain '\(keyword)'"
            )
        }
    }

    func testSwiftKeywordsDoesNotContainYiddish() {
        XCTAssertFalse(Keywords.swiftKeywords.contains("פֿונקציע"))
        XCTAssertFalse(Keywords.swiftKeywords.contains("לאָז"))
    }

    // MARK: - yiddishKeywords Set

    func testYiddishKeywordsContainsExpected() {
        let expected = ["פֿונקציע", "לאָז", "באַשטימען", "צוריק", "אויב",
                        "אַנדערש", "סטרוקטור", "קלאַס", "פּראָטאָקאָל"]
        for keyword in expected {
            XCTAssertTrue(
                Keywords.yiddishKeywords.contains(keyword),
                "yiddishKeywords should contain '\(keyword)'"
            )
        }
    }

    func testYiddishKeywordsDoesNotContainEnglish() {
        XCTAssertFalse(Keywords.yiddishKeywords.contains("func"))
        XCTAssertFalse(Keywords.yiddishKeywords.contains("let"))
    }

    // MARK: - Bijectivity

    func testBijectivity_setsHaveEqualCount() {
        XCTAssertEqual(
            Keywords.swiftKeywords.count,
            Keywords.yiddishKeywords.count,
            "Swift and Yiddish keyword sets must have equal count"
        )
        XCTAssertEqual(
            Keywords.dictionary.count,
            Keywords.swiftKeywords.count,
            "Dictionary count must match keyword set counts"
        )
        XCTAssertEqual(
            Keywords.dictionary.count,
            Keywords.yiddishKeywords.count,
            "Dictionary count must match keyword set counts"
        )
    }

    func testBijectivity_everySwiftKeywordMapsBack() {
        for swiftKw in Keywords.swiftKeywords {
            let yiddishKw = Keywords.dictionary.toKey(swiftKw)
            XCTAssertNotNil(yiddishKw, "Swift keyword '\(swiftKw)' should map to a Yiddish keyword")

            if let yiddishKw = yiddishKw {
                let roundTrip = Keywords.dictionary.toValue(yiddishKw)
                XCTAssertEqual(
                    roundTrip, swiftKw,
                    "Round-trip failed: '\(swiftKw)' -> '\(yiddishKw)' -> '\(roundTrip ?? "nil")'"
                )
            }
        }
    }

    func testBijectivity_everyYiddishKeywordMapsBack() {
        for yiddishKw in Keywords.yiddishKeywords {
            let swiftKw = Keywords.dictionary.toValue(yiddishKw)
            XCTAssertNotNil(swiftKw, "Yiddish keyword '\(yiddishKw)' should map to a Swift keyword")

            if let swiftKw = swiftKw {
                let roundTrip = Keywords.dictionary.toKey(swiftKw)
                XCTAssertEqual(
                    roundTrip, yiddishKw,
                    "Round-trip failed: '\(yiddishKw)' -> '\(swiftKw)' -> '\(roundTrip ?? "nil")'"
                )
            }
        }
    }
}
