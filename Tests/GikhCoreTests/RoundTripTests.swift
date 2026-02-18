// RoundTripTests.swift
// GikhCore — Round-trip verification tests.
// CRITICAL: The design doc requires lossless round-tripping between all modes.

import XCTest
@testable import GikhCore

final class RoundTripTests: XCTestCase {

    // MARK: - Helpers

    private func compilationLexicon() -> Lexicon {
        Lexicon.forCompilation()
    }

    private func developerLexicon(
        identifiers: [(String, String)] = []
    ) throws -> Lexicon {
        try Lexicon.forDeveloper(projectIdentifiers: BiMap(identifiers))
    }

    /// Unicode BiDi control characters that are added/stripped during mode transitions.
    /// These are rendering aids, not semantic content, so round-trip comparison
    /// strips them from both sides.
    private static let bidiControls: Set<Character> = [
        "\u{2066}", // LRI
        "\u{2067}", // RLI
        "\u{2068}", // FSI
        "\u{2069}", // PDI
        "\u{200E}", // LRM
        "\u{200F}", // RLM
        "\u{202A}", // LRE
        "\u{202B}", // RLE
        "\u{202C}", // PDF
        "\u{202D}", // LRO
        "\u{202E}", // RLO
    ]

    private func stripBidi(_ s: String) -> String {
        String(s.filter { !Self.bidiControls.contains($0) })
    }

    /// Transpile and then transpile back, asserting the semantic content matches.
    /// BiDi control characters are stripped before comparison since they are
    /// rendering aids that get re-inserted on each Mode B emission.
    private func assertRoundTrip(
        source: String,
        from sourceMode: TargetMode,
        through intermediateMode: TargetMode,
        lexicon: Lexicon,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let intermediate = Transpiler.transpile(
            source: source,
            from: sourceMode,
            to: intermediateMode,
            lexicon: lexicon
        )
        let roundTripped = Transpiler.transpile(
            source: intermediate,
            from: intermediateMode,
            to: sourceMode,
            lexicon: lexicon
        )

        let strippedOriginal = stripBidi(source)
        let strippedResult = stripBidi(roundTripped)

        XCTAssertEqual(
            strippedResult, strippedOriginal,
            """
            Round-trip failed (\(sourceMode) -> \(intermediateMode) -> \(sourceMode)):
            Original:     \(strippedOriginal.debugDescription)
            Intermediate: \(intermediate.debugDescription)
            Round-trip:   \(strippedResult.debugDescription)
            """,
            file: file, line: line
        )
    }

    // MARK: - Mode B -> Mode C -> Mode B

    func testRoundTrip_BtoCthenCtoB_simpleKeywords() {
        let source = "פֿונקציע שלום() { צוריק 42 }"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_BtoCthenCtoB_multipleKeywords() {
        let source = "אויב אמת { לאָז x = 1 } אַנדערש { באַשטימען y = 2 }"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_BtoCthenCtoB_structDeclaration() {
        let source = "סטרוקטור מבנה { לאָז נאָמען: סטרינג }"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    // MARK: - Mode A -> Mode B -> Mode A

    func testRoundTrip_AtoBthenBtoA_simpleFunction() throws {
        let lexicon = try developerLexicon(identifiers: [("שלום", "hello")])
        let source = "func hello() { return 42 }"

        assertRoundTrip(source: source, from: .modeA, through: .modeB, lexicon: lexicon)
    }

    func testRoundTrip_AtoBthenBtoA_ifElse() throws {
        let lexicon = try developerLexicon(identifiers: [("x", "x")])
        let source = "if true { let x = 1 } else { var x = 2 }"

        assertRoundTrip(source: source, from: .modeA, through: .modeB, lexicon: lexicon)
    }

    // MARK: - Whitespace Preservation

    func testRoundTrip_BtoC_preservesWhitespace() {
        let source = "פֿונקציע    שלום()   {\n\t\tצוריק   42\n}"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_AtoB_preservesWhitespace() throws {
        let lexicon = try developerLexicon()
        let source = "func    test()   {\n\t\treturn   42\n}"

        assertRoundTrip(source: source, from: .modeA, through: .modeB, lexicon: lexicon)
    }

    func testRoundTrip_preservesNewlines() {
        let source = "פֿונקציע\n\nשלום\n\n()\n\n{}\n"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    // MARK: - String Literal Preservation

    func testRoundTrip_BtoC_preservesStringLiterals() {
        let source = "לאָז x = \"hello world\""
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_AtoB_preservesStringLiterals() throws {
        let lexicon = try developerLexicon()
        let source = "let x = \"hello world\""

        assertRoundTrip(source: source, from: .modeA, through: .modeB, lexicon: lexicon)
    }

    func testRoundTrip_preservesStringWithInterpolation() {
        let source = "לאָז x = \"שלום \\(name)\""
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_preservesEmptyString() {
        let source = "לאָז x = \"\""
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_preservesMultilineString() throws {
        let lexicon = try developerLexicon()
        let source = "let x = \"\"\"\nhello\nworld\n\"\"\""

        assertRoundTrip(source: source, from: .modeA, through: .modeB, lexicon: lexicon)
    }

    // MARK: - Comment Preservation

    func testRoundTrip_BtoC_preservesSingleLineComment() {
        let source = "// this is a comment\nפֿונקציע test() {}"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_AtoB_preservesSingleLineComment() throws {
        let lexicon = try developerLexicon()
        let source = "// this is a comment\nfunc test() {}"

        assertRoundTrip(source: source, from: .modeA, through: .modeB, lexicon: lexicon)
    }

    func testRoundTrip_preservesMultiLineComment() {
        let source = "/* multi\nline\ncomment */ פֿונקציע test() {}"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_preservesNestedComment() {
        let source = "/* outer /* inner */ end */ פֿונקציע test() {}"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    // MARK: - Number Literals

    func testRoundTrip_preservesNumberLiterals() {
        let source = "לאָז x = 42"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_preservesHexLiteral() {
        let source = "לאָז x = 0xFF"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_preservesFloatLiteral() {
        let source = "לאָז x = 3.14"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    // MARK: - Operators and Punctuation

    func testRoundTrip_preservesPunctuation() {
        // Mode B source must use Yiddish bibliotek names (צאָל, not Int)
        let source = "פֿונקציע test(a: צאָל, b: צאָל) -> צאָל {}"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_preservesOperators() {
        let source = "לאָז x = 1 + 2 * 3"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    // MARK: - Mixed Content

    func testRoundTrip_BtoC_complexSource() {
        // Mode B source must use Yiddish bibliotek names (סטרינג, not String)
        let source = """
        // A greeting function
        פֿונקציע greet(name: סטרינג) -> סטרינג {
            צוריק "Hello, \\(name)!"
        }
        """
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_AtoB_complexSource() throws {
        let lexicon = try developerLexicon()
        let source = """
        // A greeting function
        func greet(name: String) -> String {
            return "Hello, \\(name)!"
        }
        """

        assertRoundTrip(source: source, from: .modeA, through: .modeB, lexicon: lexicon)
    }

    // MARK: - Empty Source

    func testRoundTrip_emptySource_BtoC() {
        let lexicon = compilationLexicon()
        assertRoundTrip(source: "", from: .modeB, through: .modeC, lexicon: lexicon)
    }

    func testRoundTrip_emptySource_AtoB() throws {
        let lexicon = try developerLexicon()
        assertRoundTrip(source: "", from: .modeA, through: .modeB, lexicon: lexicon)
    }

    // MARK: - Keywords-Only Source

    func testRoundTrip_keywordsOnly() {
        let source = "פֿונקציע לאָז באַשטימען צוריק אויב אַנדערש"
        let lexicon = compilationLexicon()

        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }

    // MARK: - Identifiers-Only Source

    func testRoundTrip_identifiersOnly() {
        let source = "שלום עולם test hello"
        let lexicon = compilationLexicon()

        // With keywords-only mode (B->C), identifiers pass through unchanged
        assertRoundTrip(source: source, from: .modeB, through: .modeC, lexicon: lexicon)
    }
}
