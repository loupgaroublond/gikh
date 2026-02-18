import Testing
@testable import GikhCore

// MARK: - Helpers

private let lri = "\u{2066}"   // Left-to-Right Isolate
private let rli = "\u{2067}"   // Right-to-Left Isolate
private let fsi = "\u{2068}"   // First Strong Isolate
private let pdi = "\u{2069}"   // Pop Directional Isolate
private let lrm = "\u{200E}"   // Left-to-Right Mark
private let rlm = "\u{200F}"   // Right-to-Left Mark

/// Helper: scan source into tokens, then annotate.
private func annotate(_ source: String, target: TargetMode) -> String {
    var scanner = Scanner(source: source)
    let tokens = scanner.scan()
    let annotator = BidiAnnotator()
    return annotator.annotate(tokens, target: target)
}

// MARK: - Mode B: RTL emission tests

@Suite("BidiAnnotator — Mode B (RTL) Emission")
struct BidiAnnotatorModeBTests {

    @Test("RTL keyword gets RLI...PDI isolate")
    func rtlKeywordGetsRLIIsolate() {
        // Yiddish keywords contain RTL characters
        let result = annotate("לאָז", target: .modeB)
        #expect(result.contains(rli))
        #expect(result.contains(pdi))
        #expect(result.contains("לאָז"))
    }

    @Test("LTR keyword gets LRI...PDI isolate in Mode B")
    func ltrKeywordGetsLRIIsolate() {
        // English keyword in Mode B (could be used when converting C→B partially)
        // "let" is ASCII = LTR
        let result = annotate("let", target: .modeB)
        #expect(result.contains(lri))
        #expect(result.contains(pdi))
    }

    @Test("String literal gets FSI...PDI isolate")
    func stringLiteralGetsFSIIsolate() {
        let result = annotate("\"hello\"", target: .modeB)
        #expect(result.contains(fsi))
        #expect(result.contains(pdi))
    }

    @Test("Opening bracket followed by LRM")
    func openBracketFollowedByLRM() {
        let result = annotate("(", target: .modeB)
        #expect(result.contains("("))
        #expect(result.contains(lrm))
    }

    @Test("Opening brace followed by LRM")
    func openBraceFollowedByLRM() {
        let result = annotate("{", target: .modeB)
        #expect(result.contains("{"))
        #expect(result.contains(lrm))
    }

    @Test("Opening square bracket followed by LRM")
    func openSquareBracketFollowedByLRM() {
        let result = annotate("[", target: .modeB)
        #expect(result.contains("["))
        #expect(result.contains(lrm))
    }

    @Test("Operator gets LRI...PDI isolate in Mode B")
    func operatorGetsLRIIsolate() {
        let result = annotate("+", target: .modeB)
        #expect(result.contains(lri))
        #expect(result.contains(pdi))
        #expect(result.contains("+"))
    }

    @Test("Whitespace passes through without annotation")
    func whitespacePassesThrough() {
        let result = annotate(" ", target: .modeB)
        #expect(result == " ")
    }

    @Test("Newline passes through without annotation")
    func newlinePassesThrough() {
        let result = annotate("\n", target: .modeB)
        #expect(result == "\n")
    }

    @Test("Number literal passes through without annotation in Mode B")
    func numberPassesThrough() {
        let result = annotate("42", target: .modeB)
        #expect(result == "42")
    }
}

// MARK: - Slash flipping tests

@Suite("BidiAnnotator — Slash Flipping")
struct BidiAnnotatorSlashTests {

    @Test("Division / becomes \\ in Mode B operator")
    func divisionFlippedInModeB() {
        let result = annotate("a / b", target: .modeB)
        // The / in the operator token should be flipped to \
        #expect(result.contains("\\"))
        // Original / should not appear as operator (it's inside LRI/PDI wrapping)
        // Check: the operator content within isolate should have backslash
        // We check the whole output doesn't contain unescaped / outside strings
        // Actually we just verify the backslash is present from slash flip
        let _ = result  // The assertion above is sufficient
    }

    @Test("Keypath \\ becomes / in Mode B operator")
    func keypathBackslashFlippedInModeB() {
        // A bare backslash operator (e.g. keypath prefix) should become /
        let result = annotate("\\Person.name", target: .modeB)
        #expect(result.contains("/"))
    }

    @Test("String literal slashes are NOT flipped in Mode B")
    func stringSlashNotFlipped() {
        // The text inside a string literal must never be touched
        let result = annotate("\"path/to/file\"", target: .modeB)
        #expect(result.contains("/"))
        // The content "path/to/file" should be preserved verbatim inside FSI...PDI
        #expect(result.contains("path/to/file"))
    }

    @Test("Comment slashes are NOT flipped in Mode B")
    func commentSlashNotFlipped() {
        let result = annotate("// a/b comment", target: .modeB)
        #expect(result.contains("// a/b comment"))
    }

    @Test("Interpolation delimiter \\( becomes /( in Mode B")
    func interpolationDelimiterFlipped() {
        // Scanner emits \( as interpolationDelimiter — annotator should flip it
        let result = annotate("\"prefix \\(value) suffix\"", target: .modeB)
        // In Mode B the \( should become /(
        #expect(result.contains("/("))
    }

    @Test("Closing ) of interpolation is preserved")
    func interpolationClosingPreserved() {
        let result = annotate("\"\\(x)\"", target: .modeB)
        // There should still be a ) closing the interpolation
        #expect(result.contains(")"))
    }

    @Test("Mode B output has backslash where Mode C has forward slash (round-trip)")
    func divisionRoundTripBToC() {
        // Mode B: division operator is \, Mode C: /
        // Annotate "a / b" to Mode B → should flip / to \
        // Then annotate that Mode B output back to Mode C → should flip \ back to /
        let source = "a / b"
        var sc = Scanner(source: source)
        let toks = sc.scan()
        let ann = BidiAnnotator()
        let modeB = ann.annotate(toks, target: .modeB)
        // Mode B output should have backslash operator
        #expect(modeB.contains("\\"))

        // Now annotate the Mode B output → Mode C
        var sc2 = Scanner(source: modeB)
        let toks2 = sc2.scan()
        let modeC = ann.annotate(toks2, target: .modeC)
        // Mode C should have forward slash back
        #expect(modeC.contains("/"))
    }
}

// MARK: - LTR stripping tests

@Suite("BidiAnnotator — LTR Stripping (Mode A/C)")
struct BidiAnnotatorLTRTests {

    @Test("BiDi markers are stripped in Mode A output")
    func bidiMarkersStrippedInModeA() {
        // Feed a string that contains BiDi markers into annotator targeting Mode A
        // We'll construct tokens manually or scan a BiDi-annotated string.
        // Simplest: annotate to Mode B first, then annotate again targeting Mode A.
        let source = "לאָז א = 1"

        var scanner = Scanner(source: source)
        let tokens = scanner.scan()
        let annotator = BidiAnnotator()

        let modeB = annotator.annotate(tokens, target: .modeB)
        // Now scan the Mode B output (it contains BiDi markers) and re-annotate
        var scanner2 = Scanner(source: modeB)
        let tokens2 = scanner2.scan()
        let modeA = annotator.annotate(tokens2, target: .modeA)

        // Mode A output should contain no BiDi markers
        #expect(!modeA.contains(lri))
        #expect(!modeA.contains(rli))
        #expect(!modeA.contains(fsi))
        #expect(!modeA.contains(pdi))
        #expect(!modeA.contains(lrm))
        #expect(!modeA.contains(rlm))
    }

    @Test("Mode C output strips BiDi markers")
    func bidiMarkersStrippedInModeC() {
        let source = "לאָז א = 1"

        var scanner = Scanner(source: source)
        let tokens = scanner.scan()
        let annotator = BidiAnnotator()
        let result = annotator.annotate(tokens, target: .modeC)

        #expect(!result.contains(lri))
        #expect(!result.contains(rli))
        #expect(!result.contains(fsi))
        #expect(!result.contains(pdi))
    }

    @Test("Plain source through Mode A returns same text")
    func plainSourceModaA() {
        let source = "let x = 42"
        let result = annotate(source, target: .modeA)
        #expect(result == source)
    }

    @Test("Plain source through Mode C returns same text")
    func plainSourceModeC() {
        let source = "let מענטש = 1"
        let result = annotate(source, target: .modeC)
        #expect(result == source)
    }

    @Test("LTR source through Mode A output is unchanged")
    func plainLTRSourceUnchangedInModeA() {
        // Plain LTR source (Mode C / Mode A) fed into LTR annotator should be verbatim
        let result = annotate("let x = a / b", target: .modeA)
        #expect(result == "let x = a / b")
    }

    @Test("Mode B → scan → Mode C produces no BiDi, same semantic content")
    func modeBToModeC() {
        // Annotate Yiddish tokens to Mode B, then re-annotate to Mode C
        let source = "לאָז א = 1"
        var sc = Scanner(source: source)
        let toks = sc.scan()
        let ann = BidiAnnotator()

        let modeB = ann.annotate(toks, target: .modeB)
        var sc2 = Scanner(source: modeB)
        let toks2 = sc2.scan()
        let modeC = ann.annotate(toks2, target: .modeC)

        #expect(!modeC.contains(rli))
        #expect(!modeC.contains(lri))
        #expect(modeC.contains("לאָז"))
        #expect(modeC.contains("א"))
    }
}

// MARK: - Round-trip BiDi tests

@Suite("BidiAnnotator — Round-trip")
struct BidiAnnotatorRoundTripTests {

    @Test("RTL identifier round-trip through Mode B annotation and LTR stripping")
    func rtlIdentifierRoundTrip() {
        let source = "לאָז מענטש = 1"
        var sc = Scanner(source: source)
        let toks = sc.scan()
        let ann = BidiAnnotator()

        // Annotate to Mode B (adds BiDi markers)
        let modeB = ann.annotate(toks, target: .modeB)

        // The identifier text must still be present
        #expect(modeB.contains("לאָז"))
        #expect(modeB.contains("מענטש"))

        // Strip back to Mode A/C (removes BiDi markers)
        var sc2 = Scanner(source: modeB)
        let toks2 = sc2.scan()
        let stripped = ann.annotate(toks2, target: .modeC)

        // After stripping, we should get back essentially the same content
        #expect(stripped.contains("לאָז"))
        #expect(stripped.contains("מענטש"))
        #expect(!stripped.contains(rli))
        #expect(!stripped.contains(pdi))
    }

    @Test("Number literal unchanged through Mode B and back")
    func numberLiteralRoundTrip() {
        let source = "42"
        var sc = Scanner(source: source)
        let toks = sc.scan()
        let ann = BidiAnnotator()
        let modeB = ann.annotate(toks, target: .modeB)
        var sc2 = Scanner(source: modeB)
        let toks2 = sc2.scan()
        let back = ann.annotate(toks2, target: .modeC)
        #expect(back == source)
    }
}
