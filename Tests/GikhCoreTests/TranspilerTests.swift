// TranspilerTests.swift
// GikhCore — Tests for the high-level Transpiler orchestrator.

import XCTest
@testable import GikhCore

final class TranspilerTests: XCTestCase {

    // MARK: - Helpers

    private func compilationLexicon() -> Lexicon {
        Lexicon.forCompilation()
    }

    private func developerLexicon(
        bibliotek: [(String, String)] = [],
        identifiers: [(String, String)] = []
    ) throws -> Lexicon {
        try Lexicon.forDeveloper(
            bibliotekMappings: BiMap(bibliotek),
            projectIdentifiers: BiMap(identifiers)
        )
    }

    // MARK: - Mode B -> Mode C (Keywords Only)

    func testTranspile_modeBToModeC_keywordsTranslated() {
        let source = "פֿונקציע שלום() { צוריק 42 }"
        let lexicon = compilationLexicon()

        let result = Transpiler.transpile(
            source: source,
            from: .modeB,
            to: .modeC,
            lexicon: lexicon
        )

        // Keywords should be translated to English, identifiers left alone
        XCTAssertTrue(result.contains("func"))
        XCTAssertTrue(result.contains("return"))
        XCTAssertTrue(result.contains("שלום"))  // identifier passes through
        XCTAssertTrue(result.contains("42"))
        XCTAssertFalse(result.contains("פֿונקציע"))
        XCTAssertFalse(result.contains("צוריק"))
    }

    // MARK: - Mode B -> Mode A (Full)

    func testTranspile_modeBToModeA_fullTranslation() throws {
        let lexicon = try developerLexicon(identifiers: [("שלום", "hello")])
        let source = "פֿונקציע שלום() { צוריק 42 }"

        let result = Transpiler.transpile(
            source: source,
            from: .modeB,
            to: .modeA,
            lexicon: lexicon
        )

        // Both keywords and identifiers translated
        XCTAssertTrue(result.contains("func"))
        XCTAssertTrue(result.contains("hello"))
        XCTAssertTrue(result.contains("return"))
        XCTAssertFalse(result.contains("פֿונקציע"))
        XCTAssertFalse(result.contains("שלום"))
    }

    // MARK: - Mode A -> Mode B (Full)

    func testTranspile_modeAToModeB_fullTranslation() throws {
        let lexicon = try developerLexicon(identifiers: [("שלום", "hello")])
        let source = "func hello() { return 42 }"

        let result = Transpiler.transpile(
            source: source,
            from: .modeA,
            to: .modeB,
            lexicon: lexicon
        )

        // Keywords and identifiers translated to Yiddish
        // Mode B adds BiDi annotations
        XCTAssertTrue(result.contains("פֿונקציע"))
        XCTAssertTrue(result.contains("שלום"))
        XCTAssertTrue(result.contains("צוריק"))
        XCTAssertFalse(result.contains("func"))
        XCTAssertFalse(result.contains("hello"))
        XCTAssertFalse(result.contains("return"))
    }

    // MARK: - detectMode

    func testDetectMode_gikhExtension() {
        XCTAssertEqual(Transpiler.detectMode(path: "main.gikh"), .modeB)
    }

    func testDetectMode_gikhInPath() {
        XCTAssertEqual(Transpiler.detectMode(path: "/path/to/file.gikh"), .modeB)
    }

    func testDetectMode_swiftExtension() {
        XCTAssertEqual(Transpiler.detectMode(path: "main.swift"), .modeC)
    }

    func testDetectMode_swiftInPath() {
        XCTAssertEqual(Transpiler.detectMode(path: "/path/to/file.swift"), .modeC)
    }

    func testDetectMode_unknownExtension() {
        XCTAssertEqual(Transpiler.detectMode(path: "file.txt"), .modeC)
    }

    func testDetectMode_noExtension() {
        XCTAssertEqual(Transpiler.detectMode(path: "Makefile"), .modeC)
    }

    // MARK: - determineTranslation

    func testDetermineTranslation_BtoC() {
        let (direction, mode) = Transpiler.determineTranslation(from: .modeB, to: .modeC)
        XCTAssertEqual(direction, .toEnglish)
        XCTAssertEqual(mode, .keywordsOnly)
    }

    func testDetermineTranslation_CtoB() {
        let (direction, mode) = Transpiler.determineTranslation(from: .modeC, to: .modeB)
        XCTAssertEqual(direction, .toYiddish)
        XCTAssertEqual(mode, .keywordsOnly)
    }

    func testDetermineTranslation_BtoA() {
        let (direction, mode) = Transpiler.determineTranslation(from: .modeB, to: .modeA)
        XCTAssertEqual(direction, .toEnglish)
        XCTAssertEqual(mode, .full)
    }

    func testDetermineTranslation_AtoB() {
        let (direction, mode) = Transpiler.determineTranslation(from: .modeA, to: .modeB)
        XCTAssertEqual(direction, .toYiddish)
        XCTAssertEqual(mode, .full)
    }

    func testDetermineTranslation_CtoA() {
        let (direction, mode) = Transpiler.determineTranslation(from: .modeC, to: .modeA)
        XCTAssertEqual(direction, .toEnglish)
        XCTAssertEqual(mode, .full)
    }

    func testDetermineTranslation_AtoC() {
        let (direction, mode) = Transpiler.determineTranslation(from: .modeA, to: .modeC)
        XCTAssertEqual(direction, .toYiddish)
        XCTAssertEqual(mode, .full)
    }

    func testDetermineTranslation_sameMode() {
        // Same mode is a no-op pass-through
        let (direction, mode) = Transpiler.determineTranslation(from: .modeA, to: .modeA)
        // Direction is arbitrary for same-mode, but mode should be keywordsOnly
        XCTAssertEqual(direction, .toEnglish)
        XCTAssertEqual(mode, .keywordsOnly)
    }

    func testDetermineTranslation_sameModeB() {
        let (direction, mode) = Transpiler.determineTranslation(from: .modeB, to: .modeB)
        XCTAssertEqual(direction, .toEnglish)
        XCTAssertEqual(mode, .keywordsOnly)
    }

    // MARK: - Transpile Preserves Non-translatable Content

    func testTranspile_preservesStrings() {
        let source = "let x = \"hello world\""
        let lexicon = compilationLexicon()

        let result = Transpiler.transpile(
            source: source,
            from: .modeA,
            to: .modeC,
            lexicon: lexicon
        )

        XCTAssertTrue(result.contains("\"hello world\""))
    }

    func testTranspile_preservesComments() {
        let source = "// this is a comment\nfunc test() {}"
        let lexicon = compilationLexicon()

        let result = Transpiler.transpile(
            source: source,
            from: .modeA,
            to: .modeC,
            lexicon: lexicon
        )

        XCTAssertTrue(result.contains("// this is a comment"))
    }

    func testTranspile_preservesNumbers() {
        let source = "let x = 42"
        let lexicon = compilationLexicon()

        let result = Transpiler.transpile(
            source: source,
            from: .modeA,
            to: .modeC,
            lexicon: lexicon
        )

        XCTAssertTrue(result.contains("42"))
    }

    // MARK: - Empty Source

    func testTranspile_emptySource() {
        let result = Transpiler.transpile(
            source: "",
            from: .modeA,
            to: .modeB,
            lexicon: compilationLexicon()
        )

        XCTAssertEqual(result, "")
    }
}

// Direction, TranslationMode, and TargetMode already conform to Equatable
// (they are simple enums, so Swift synthesizes Equatable automatically).
