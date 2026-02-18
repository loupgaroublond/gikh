import Testing
@testable import GikhCore

// MARK: - Round-trip helpers

/// A test lexicon with a representative set of keywords + identifiers.
private func makeTestLexicon() -> Lexicon {
    let bibliotek = BiMap<String, String>([
        ("סטרינג", "String"),
        ("צאָל", "Int"),
        ("דרוק", "print"),
        ("באָאָל", "Bool"),
        ("מאַסיוו", "Array"),
        ("טאָפּל", "Double"),
    ])
    let identifiers = BiMap<String, String>([
        ("מענטש", "Person"),
        ("נאָמען", "name"),
        ("עלטער", "age"),
        ("באַשרײַב", "describe"),
    ])
    return Lexicon(
        keywords: SwiftKeywords.keywordsMap,
        bibliotek: bibliotek,
        identifiers: identifiers
    )
}

/// Full transpilation: scan → translate → BiDi annotate.
private func transpile(
    _ source: String,
    lexicon: Lexicon,
    target: TargetMode
) -> String {
    Transpiler.transpile(source, lexicon: lexicon, target: target)
}

// MARK: - B → C → B round-trip tests

@Suite("Round-trip: B → C → B")
struct RoundTripBToCToBTests {

    @Test("Simple let keyword: B→C→B produces identical output")
    func simpleLetRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeB = "לאָז א = 1"

        let modeC = transpile(modeB, lexicon: lexicon, target: .modeC)
        let backToB = transpile(modeC, lexicon: lexicon, target: .modeB)

        // The semantic content must be identical (modulo BiDi markers applied fresh)
        // We compare the stripped (no BiDi) versions
        let annotator = BidiAnnotator()
        var sc1 = Scanner(source: modeB)
        let stripped1 = annotator.annotate(sc1.scan(), target: .modeC)
        var sc2 = Scanner(source: backToB)
        let stripped2 = annotator.annotate(sc2.scan(), target: .modeC)

        #expect(stripped1 == stripped2)
    }

    @Test("Struct definition: B→C→B produces identical output")
    func structDefinitionRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeB = "סטרוקטור מענטש { לאָז נאָמען: סטרינג }"

        let modeC = transpile(modeB, lexicon: lexicon, target: .modeC)
        let backToB = transpile(modeC, lexicon: lexicon, target: .modeB)

        let annotator = BidiAnnotator()
        var sc1 = Scanner(source: modeB)
        let stripped1 = annotator.annotate(sc1.scan(), target: .modeC)
        var sc2 = Scanner(source: backToB)
        let stripped2 = annotator.annotate(sc2.scan(), target: .modeC)

        #expect(stripped1 == stripped2)
    }

    @Test("Function definition: B→C→B")
    func functionDefinitionRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeB = "פֿונקציע חשב() -> צאָל { צוריק 42 }"

        let modeC = transpile(modeB, lexicon: lexicon, target: .modeC)
        let backToB = transpile(modeC, lexicon: lexicon, target: .modeB)

        let annotator = BidiAnnotator()
        var sc1 = Scanner(source: modeB)
        let stripped1 = annotator.annotate(sc1.scan(), target: .modeC)
        var sc2 = Scanner(source: backToB)
        let stripped2 = annotator.annotate(sc2.scan(), target: .modeC)

        #expect(stripped1 == stripped2)
    }

    @Test("B→C: keywords become English, Yiddish identifiers preserved")
    func bToCKeywordsAndIdentifiers() {
        let lexicon = makeTestLexicon()
        let modeB = "לאָז מענטש: סטרינג = \"יענקל\""

        let modeC = transpile(modeB, lexicon: lexicon, target: .modeC)

        // Mode C: English keywords, Yiddish identifiers, no BiDi
        #expect(modeC.contains("let"))
        #expect(modeC.contains("מענטש"))
        #expect(modeC.contains("סטרינג"))
        // No Yiddish keywords
        #expect(!modeC.contains("לאָז"))
        // No BiDi markers
        #expect(!modeC.contains("\u{2066}"))
        #expect(!modeC.contains("\u{2067}"))
    }

    @Test("B→C: slash in division operator flipped back")
    func bToCSlashFlippedBack() {
        let lexicon = makeTestLexicon()
        // Mode B: division uses backslash
        let modeB = "לאָז תּוצאָה = 10 \\ 2"

        let modeC = transpile(modeB, lexicon: lexicon, target: .modeC)

        // Mode C: division uses forward slash
        #expect(modeC.contains("/"))
    }
}

// MARK: - A → B → A round-trip tests

@Suite("Round-trip: A → B → A")
struct RoundTripAToBToATests {

    @Test("Simple English snippet: A→B→A produces identical output")
    func simpleEnglishRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeA = "let x = 1"

        let modeB = transpile(modeA, lexicon: lexicon, target: .modeB)
        let backToA = transpile(modeB, lexicon: lexicon, target: .modeA)

        #expect(backToA == modeA)
    }

    @Test("Struct: A→B→A round-trip")
    func structRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeA = "struct Person { let name: String }"

        let modeB = transpile(modeA, lexicon: lexicon, target: .modeB)
        let backToA = transpile(modeB, lexicon: lexicon, target: .modeA)

        #expect(backToA == modeA)
    }

    @Test("Function: A→B→A round-trip")
    func functionRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeA = "func calculate() -> Int { return 42 }"

        let modeB = transpile(modeA, lexicon: lexicon, target: .modeB)
        let backToA = transpile(modeB, lexicon: lexicon, target: .modeA)

        #expect(backToA == modeA)
    }

    @Test("String literal content preserved through A→B→A")
    func stringLiteralPreservedRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeA = "let x = \"hello world\""

        let modeB = transpile(modeA, lexicon: lexicon, target: .modeB)
        let backToA = transpile(modeB, lexicon: lexicon, target: .modeA)

        #expect(backToA == modeA)
        #expect(backToA.contains("\"hello world\""))
    }

    @Test("Comment content preserved through A→B→A")
    func commentPreservedRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeA = "// a comment\nlet x = 1"

        let modeB = transpile(modeA, lexicon: lexicon, target: .modeB)
        let backToA = transpile(modeB, lexicon: lexicon, target: .modeA)

        #expect(backToA == modeA)
        #expect(backToA.contains("// a comment"))
    }

    @Test("Unknown identifiers preserved through A→B→A")
    func unknownIdentifiersPreservedRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeA = "let mysteryVar = 42"

        let modeB = transpile(modeA, lexicon: lexicon, target: .modeB)
        let backToA = transpile(modeB, lexicon: lexicon, target: .modeA)

        #expect(backToA == modeA)
        #expect(backToA.contains("mysteryVar"))
    }

    @Test("Division operator: A→B→A slash round-trip")
    func divisionSlashRoundTrip() {
        let lexicon = makeTestLexicon()
        let modeA = "let x = 10 / 2"

        let modeB = transpile(modeA, lexicon: lexicon, target: .modeB)
        let backToA = transpile(modeB, lexicon: lexicon, target: .modeA)

        #expect(backToA == modeA)
    }
}

// MARK: - C → A round-trip tests

@Suite("Round-trip: C → A")
struct RoundTripCToATests {

    @Test("Mode C (English keywords, Yiddish identifiers) → Mode A")
    func modeCToModeA() {
        let lexicon = makeTestLexicon()
        // Mode C: English keywords, Yiddish identifiers
        let modeC = "let מענטש: סטרינג = \"יענקל\""

        let modeA = transpile(modeC, lexicon: lexicon, target: .modeA)

        #expect(modeA.contains("let"))
        #expect(modeA.contains("Person"))
        #expect(modeA.contains("String"))
        #expect(!modeA.contains("מענטש"))
        #expect(!modeA.contains("סטרינג"))
    }
}

// MARK: - Comprehensive round-trip tests using design doc examples

@Suite("Round-trip: Design Doc Examples")
struct RoundTripDesignDocTests {

    /// Tests from the design doc Mode B ↔ Mode C example
    @Test("Division: Mode B backslash → Mode C forward slash")
    func divisionModeBModeC() {
        let lexicon = makeTestLexicon()

        // Mode C: standard division
        let modeC = "let תּוצאָה = א / ב"
        let modeB = transpile(modeC, lexicon: lexicon, target: .modeB)
        // Mode B: division uses backslash
        #expect(modeB.contains("\\"))

        let backToC = transpile(modeB, lexicon: lexicon, target: .modeC)
        // Semantic content preserved
        #expect(backToC.contains("/"))
        #expect(backToC.contains("תּוצאָה"))
    }

    @Test("All Mode B keywords translate to Mode C English keywords")
    func allKeywordsModeBToC() {
        let lexicon = makeTestLexicon()
        let pairs = SwiftKeywords.yiddishToEnglish

        for (yiddish, english) in pairs {
            let modeB = "\(yiddish) א"
            let modeC = transpile(modeB, lexicon: lexicon, target: .modeC)
            #expect(
                modeC.contains(english),
                "Expected '\(english)' in Mode C output for '\(yiddish)'"
            )
        }
    }

    @Test("All Mode C English keywords translate back to Mode B Yiddish")
    func allKeywordsModeCToB() {
        let lexicon = makeTestLexicon()
        let pairs = SwiftKeywords.yiddishToEnglish

        for (yiddish, english) in pairs {
            let modeC = "\(english) א"
            let modeB = transpile(modeC, lexicon: lexicon, target: .modeB)
            #expect(
                modeB.contains(yiddish),
                "Expected '\(yiddish)' in Mode B output for '\(english)'"
            )
        }
    }
}
