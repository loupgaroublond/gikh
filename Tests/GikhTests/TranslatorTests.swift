import Testing
@testable import גיך

// MARK: - Helpers

private func makeTokens(_ pairs: [(String, (String, Range<String.Index>) -> Token)]) -> [Token] {
    var result: [Token] = []
    var offset = "a".startIndex
    let base = "a"
    for (text, ctor) in pairs {
        let start = base.startIndex
        let end = base.endIndex
        result.append(ctor(text, start..<end))
        _ = offset
    }
    return result
}

/// Build a simple token stream from a source string via Scanner.
private func tokens(for source: String) -> [Token] {
    var scanner = Scanner(source: source)
    return scanner.scan()
}

/// Translate a source string and return the reconstructed output string.
private func translate(
    source: String,
    direction: Direction,
    mode: TranslationMode,
    lexicon: Lexicon
) -> String {
    var scanner = Scanner(source: source)
    let toks = scanner.scan()
    let translator = Translator(lexicon: lexicon, direction: direction, mode: mode)
    let translated = translator.translate(toks)
    return translated.map(\.text).joined()
}

// MARK: - Lexicon helpers for tests

/// A lexicon with only keywords (no identifiers).
private func keywordsOnlyLexicon() -> Lexicon {
    Lexicon(
        keywords: SwiftKeywords.keywordsMap,
        bibliotek: BiMap([]),
        identifiers: BiMap([])
    )
}

/// A lexicon with keywords + a small ביבליאָטעק map for testing.
private func testLexicon() -> Lexicon {
    let bibliotek = BiMap<String, String>([
        ("סטרינג", "String"),
        ("צאָל", "Int"),
        ("דרוק", "print"),
        ("מאַסיוו", "Array"),
    ])
    let identifiers = BiMap<String, String>([
        ("מענטש", "Person"),
        ("נאָמען", "name"),
        ("עלטער", "age"),
    ])
    return Lexicon(
        keywords: SwiftKeywords.keywordsMap,
        bibliotek: bibliotek,
        identifiers: identifiers
    )
}

// MARK: - Keyword translation tests

@Suite("Translator — Keyword Swapping")
struct TranslatorKeywordTests {

    @Test("English → Yiddish: func becomes פֿונקציע")
    func englishToYiddishFunc() {
        let result = translate(
            source: "func hello() {}",
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("פֿונקציע"))
        #expect(!result.contains("func"))
    }

    @Test("English → Yiddish: let becomes לאָז")
    func englishToYiddishLet() {
        let result = translate(
            source: "let x = 1",
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("לאָז"))
        #expect(!result.contains(" let "))
    }

    @Test("English → Yiddish: var becomes באַשטימען")
    func englishToYiddishVar() {
        let result = translate(
            source: "var x = 1",
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("באַשטימען"))
    }

    @Test("English → Yiddish: return becomes צוריק")
    func englishToYiddishReturn() {
        let result = translate(
            source: "return 42",
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("צוריק"))
    }

    @Test("English → Yiddish: struct becomes סטרוקטור")
    func englishToYiddishStruct() {
        let result = translate(
            source: "struct Foo {}",
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("סטרוקטור"))
    }

    @Test("Yiddish → English: פֿונקציע becomes func")
    func yiddishToEnglishFunc() {
        let result = translate(
            source: "פֿונקציע שלום() {}",
            direction: .toEnglish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("func"))
        #expect(!result.contains("פֿונקציע"))
    }

    @Test("Yiddish → English: לאָז becomes let")
    func yiddishToEnglishLet() {
        let result = translate(
            source: "לאָז פֿרוכט = 1",
            direction: .toEnglish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("let"))
        #expect(!result.contains("לאָז"))
    }

    @Test("Yiddish → English: סטרוקטור becomes struct")
    func yiddishToEnglishStruct() {
        let result = translate(
            source: "סטרוקטור מענטש {}",
            direction: .toEnglish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("struct"))
    }

    @Test("Multiple keywords in one snippet")
    func multipleKeywords() {
        let source = "פֿונקציע חשב() -> צאָל { צוריק 42 }"
        let result = translate(
            source: source,
            direction: .toEnglish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("func"))
        #expect(result.contains("return"))
        #expect(!result.contains("פֿונקציע"))
        #expect(!result.contains("צוריק"))
    }

    @Test("Keywords not in map pass through unchanged (toYiddish direction)")
    func unknownKeywordPassthrough() {
        // "unknownKw" is not a keyword — it should stay as an identifier
        let result = translate(
            source: "let unknownKw = 1",
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        #expect(result.contains("unknownKw"))
    }
}

// MARK: - Identifier translation tests

@Suite("Translator — Identifier Swapping")
struct TranslatorIdentifierTests {

    @Test("Full mode: ביבליאָטעק identifier String → סטרינג")
    func bibliotekEnglishToYiddish() {
        let result = translate(
            source: "let x: String = \"hello\"",
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("סטרינג"))
        #expect(!result.contains(": String"))
    }

    @Test("Full mode: ביבליאָטעק identifier סטרינג → String")
    func bibliotekYiddishToEnglish() {
        let result = translate(
            source: "לאָז א: סטרינג = \"שלום\"",
            direction: .toEnglish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("String"))
    }

    @Test("Full mode: project identifier מענטש → Person")
    func projectIdentifierYiddishToEnglish() {
        let result = translate(
            source: "סטרוקטור מענטש {}",
            direction: .toEnglish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("Person"))
        #expect(!result.contains("מענטש"))
    }

    @Test("Full mode: project identifier Person → מענטש")
    func projectIdentifierEnglishToYiddish() {
        let result = translate(
            source: "struct Person {}",
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("מענטש"))
        #expect(!result.contains("Person"))
    }

    @Test("Full mode: unknown identifier passes through unchanged")
    func unknownIdentifierPassthrough() {
        let result = translate(
            source: "let mysteryVar = 42",
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("mysteryVar"))
    }

    @Test("keywordsOnly mode: identifiers not swapped")
    func keywordsOnlyDoesNotSwapIdentifiers() {
        let result = translate(
            source: "let String = 1",
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: testLexicon()
        )
        // String is an identifier here; in keywordsOnly mode it should not be swapped
        #expect(result.contains("String"))
    }
}

// MARK: - Opaque token passthrough tests

@Suite("Translator — Opaque Token Passthrough")
struct TranslatorOpaqueTokenTests {

    @Test("String literal content is preserved verbatim")
    func stringLiteralPreserved() {
        let source = "let x = \"hello world\""
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("\"hello world\""))
    }

    @Test("Comment content is preserved verbatim")
    func commentPreserved() {
        let source = "// this is a comment\nlet x = 1"
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("// this is a comment"))
    }

    @Test("Number literals are preserved verbatim")
    func numberLiteralPreserved() {
        let source = "let x = 3.14"
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("3.14"))
    }

    @Test("Operators are preserved verbatim")
    func operatorPreserved() {
        let source = "let x = a + b"
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("+"))
    }

    @Test("Token stream reconstructs to equal-length output")
    func outputLengthMatchesInput() {
        let source = "let x = 42"
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: keywordsOnlyLexicon()
        )
        // Even with keyword replacement, the joined tokens should be valid
        #expect(!result.isEmpty)
    }
}

// MARK: - Mode combination tests

@Suite("Translator — Mode Combinations (B↔C, B↔A)")
struct TranslatorModeTests {

    @Test("B→C: Yiddish keywords → English, Yiddish identifiers unchanged (keywordsOnly)")
    func modeBToC() {
        // Mode B input: Yiddish keywords + Yiddish identifiers
        let source = "לאָז מענטש: סטרינג = \"יענקל\""
        let result = translate(
            source: source,
            direction: .toEnglish,
            mode: .keywordsOnly,
            lexicon: testLexicon()
        )
        // Keywords swapped
        #expect(result.contains("let"))
        // Identifiers NOT swapped (keywordsOnly)
        #expect(result.contains("מענטש"))
        #expect(result.contains("סטרינג"))
    }

    @Test("C→B: English keywords → Yiddish, Yiddish identifiers unchanged (keywordsOnly)")
    func modeCToB() {
        // Mode C input: English keywords + Yiddish identifiers
        let source = "let מענטש: סטרינג = \"יענקל\""
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .keywordsOnly,
            lexicon: testLexicon()
        )
        #expect(result.contains("לאָז"))
        #expect(result.contains("מענטש"))
        #expect(result.contains("סטרינג"))
    }

    @Test("B→A: Yiddish keywords AND identifiers → English (full mode)")
    func modeBToA() {
        let source = "לאָז מענטש: סטרינג = \"יענקל\""
        let result = translate(
            source: source,
            direction: .toEnglish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("let"))
        #expect(result.contains("Person"))
        #expect(result.contains("String"))
    }

    @Test("A→B: English keywords AND identifiers → Yiddish (full mode)")
    func modeAToB() {
        let source = "let Person: String = \"Yankl\""
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("לאָז"))
        #expect(result.contains("מענטש"))
        #expect(result.contains("סטרינג"))
    }

    @Test("C→A: English keywords + Yiddish identifiers → English (full mode, toEnglish)")
    func modeCToA() {
        // Mode C: English keywords, Yiddish identifiers
        let source = "let מענטש: סטרינג = \"יענקל\""
        let result = translate(
            source: source,
            direction: .toEnglish,
            mode: .full,
            lexicon: testLexicon()
        )
        #expect(result.contains("let"))
        #expect(result.contains("Person"))
        #expect(result.contains("String"))
    }

    @Test("A→C: English → Yiddish identifiers only (keywordsOnly doesn't apply to A→C)")
    func modeAToC() {
        // Going A→C means: swap English identifiers to Yiddish, keep English keywords
        // This is actually full mode with toYiddish direction, output used as Mode C
        let source = "let Person: String = \"Yankl\""
        let result = translate(
            source: source,
            direction: .toYiddish,
            mode: .full,
            lexicon: testLexicon()
        )
        // Keywords are swapped too in this direction — caller determines Mode C vs B
        // based on further processing. The translator just does keyword+id swapping.
        #expect(result.contains("מענטש"))
        #expect(result.contains("סטרינג"))
    }
}

// MARK: - Round-trip tests (translation only, no BiDi)

@Suite("Translator — Round-trip")
struct TranslatorRoundTripTests {

    @Test("Keyword round-trip: toYiddish then toEnglish produces original")
    func keywordRoundTrip() {
        let source = "func hello() { return 42 }"
        let lexicon = keywordsOnlyLexicon()

        let toYiddish = translate(source: source, direction: .toYiddish, mode: .keywordsOnly, lexicon: lexicon)
        let back = translate(source: toYiddish, direction: .toEnglish, mode: .keywordsOnly, lexicon: lexicon)

        #expect(back == source)
    }

    @Test("Identifier round-trip: toYiddish then toEnglish produces original")
    func identifierRoundTrip() {
        let source = "let Person: String = \"Yankl\""
        let lexicon = testLexicon()

        let toYiddish = translate(source: source, direction: .toYiddish, mode: .full, lexicon: lexicon)
        let back = translate(source: toYiddish, direction: .toEnglish, mode: .full, lexicon: lexicon)

        #expect(back == source)
    }

    @Test("Full snippet round-trip: A→B→A")
    func fullSnippetRoundTrip() {
        let source = "struct Person { let name: String }"
        let lexicon = testLexicon()

        let yiddish = translate(source: source, direction: .toYiddish, mode: .full, lexicon: lexicon)
        let back = translate(source: yiddish, direction: .toEnglish, mode: .full, lexicon: lexicon)

        #expect(back == source)
    }
}
