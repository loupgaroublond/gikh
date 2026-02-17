// TranslatorTests.swift
// GikhCore — Tests for the token Translator.

import XCTest
@testable import GikhCore

final class TranslatorTests: XCTestCase {

    // MARK: - Helpers

    /// Create a dummy range for test tokens.
    private var dummyRange: Range<String.Index> {
        let s = ""
        return s.startIndex..<s.startIndex
    }

    /// Create a Lexicon with keywords and optional bibliotek/identifiers.
    private func makeLexicon(
        bibliotek: [(String, String)] = [],
        identifiers: [(String, String)] = []
    ) -> Lexicon {
        Lexicon(
            keywords: Keywords.dictionary,
            bibliotek: BiMap(bibliotek),
            identifiers: BiMap(identifiers)
        )
    }

    // MARK: - Keywords toEnglish

    func testKeywordsToEnglish_func() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .keywordsOnly)

        let tokens = [Token.keyword("פֿונקציע", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "func")
    }

    func testKeywordsToEnglish_multipleKeywords() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .keywordsOnly)

        let tokens = [
            Token.keyword("לאָז", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.identifier("x", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.operatorToken("=", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.numberLiteral("42", dummyRange),
        ]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "let")
        XCTAssertEqual(result[2].text, "x")  // identifier unchanged
    }

    // MARK: - Keywords toYiddish

    func testKeywordsToYiddish_func() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toYiddish, mode: .keywordsOnly)

        let tokens = [Token.keyword("func", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].text, "פֿונקציע")
    }

    func testKeywordsToYiddish_let() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toYiddish, mode: .keywordsOnly)

        let tokens = [Token.keyword("let", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "לאָז")
    }

    func testKeywordsToYiddish_var() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toYiddish, mode: .keywordsOnly)

        let tokens = [Token.keyword("var", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "באַשטימען")
    }

    // MARK: - Identifiers in Full Mode

    func testIdentifiers_fullMode_translatesFromBibliotek() {
        let lexicon = makeLexicon(bibliotek: [("דרוקן", "print")])
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.identifier("דרוקן", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "print")
    }

    func testIdentifiers_fullMode_translatesFromIdentifiers() {
        let lexicon = makeLexicon(identifiers: [("נאָמען", "name")])
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.identifier("נאָמען", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "name")
    }

    func testIdentifiers_fullMode_toYiddish() {
        let lexicon = makeLexicon(identifiers: [("נאָמען", "name")])
        let translator = Translator(lexicon: lexicon, direction: .toYiddish, mode: .full)

        let tokens = [Token.identifier("name", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "נאָמען")
    }

    // MARK: - Identifiers in KeywordsOnly Mode

    func testIdentifiers_keywordsOnlyMode_passThrough() {
        let lexicon = makeLexicon(identifiers: [("נאָמען", "name")])
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .keywordsOnly)

        let tokens = [Token.identifier("נאָמען", dummyRange)]
        let result = translator.translate(tokens)

        // In keywordsOnly mode, identifiers are NOT translated
        XCTAssertEqual(result[0].text, "נאָמען")
    }

    // MARK: - Unknown Keywords/Identifiers Pass Through

    func testUnknownKeyword_passesThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        // A keyword token that doesn't map to anything passes through
        let tokens = [Token.keyword("unknownkw", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "unknownkw")
    }

    func testUnknownIdentifier_passesThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.identifier("myCustomVar", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "myCustomVar")
    }

    // MARK: - Non-translatable Tokens Pass Through

    func testStringLiterals_passThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.stringLiteral("\"hello world\"", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "\"hello world\"")
    }

    func testComments_passThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.comment("// some comment", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "// some comment")
    }

    func testWhitespace_passesThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.whitespace("  \n  ", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "  \n  ")
    }

    func testPunctuation_passesThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.punctuation("(", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "(")
    }

    func testOperator_passesThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.operatorToken("==", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "==")
    }

    func testNumberLiteral_passesThrough() {
        let lexicon = makeLexicon()
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.numberLiteral("42", dummyRange)]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "42")
    }

    // MARK: - Mixed Token Translation

    func testMixedTokenTranslation() {
        let lexicon = makeLexicon(identifiers: [("נאָמען", "name")])
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [
            Token.keyword("פֿונקציע", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.identifier("נאָמען", dummyRange),
            Token.punctuation("(", dummyRange),
            Token.punctuation(")", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.punctuation("{", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.keyword("צוריק", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.stringLiteral("\"hello\"", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.punctuation("}", dummyRange),
        ]
        let result = translator.translate(tokens)

        XCTAssertEqual(result[0].text, "func")       // keyword translated
        XCTAssertEqual(result[1].text, " ")           // whitespace preserved
        XCTAssertEqual(result[2].text, "name")        // identifier translated
        XCTAssertEqual(result[3].text, "(")           // punctuation preserved
        XCTAssertEqual(result[8].text, "return")      // keyword translated
        XCTAssertEqual(result[10].text, "\"hello\"")  // string preserved
    }

    // MARK: - Bibliotek Priority over Identifiers

    func testBibliotekPriorityOverIdentifiers() {
        // If the same word is in both bibliotek and identifiers,
        // bibliotek should win (translator checks bibliotek first)
        let lexicon = Lexicon(
            keywords: Keywords.dictionary,
            bibliotek: BiMap([("דרוקן", "print")]),
            identifiers: BiMap([("דרוקן2", "print2")])
        )
        let translator = Translator(lexicon: lexicon, direction: .toEnglish, mode: .full)

        let tokens = [Token.identifier("דרוקן", dummyRange)]
        let result = translator.translate(tokens)
        XCTAssertEqual(result[0].text, "print")
    }
}
