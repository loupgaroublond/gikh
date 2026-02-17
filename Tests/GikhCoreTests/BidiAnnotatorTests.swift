// BidiAnnotatorTests.swift
// GikhCore — Tests for BiDi control character annotation.

import XCTest
@testable import GikhCore

final class BidiAnnotatorTests: XCTestCase {

    // MARK: - Constants

    private let lri = BidiAnnotator.lri   // \u{2066}
    private let rli = BidiAnnotator.rli   // \u{2067}
    private let fsi = BidiAnnotator.fsi   // \u{2068}
    private let pdi = BidiAnnotator.pdi   // \u{2069}
    private let lrm = BidiAnnotator.lrm   // \u{200E}

    private let annotator = BidiAnnotator()

    private var dummyRange: Range<String.Index> {
        let s = ""
        return s.startIndex..<s.startIndex
    }

    // MARK: - Mode B: RTL Tokens Wrapped in RLI...PDI

    func testModeB_RTLKeywordWrappedInRLI() {
        let tokens = [Token.keyword("פֿונקציע", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "\(rli)פֿונקציע\(pdi)")
    }

    func testModeB_RTLIdentifierWrappedInRLI() {
        let tokens = [Token.identifier("שלום", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "\(rli)שלום\(pdi)")
    }

    // MARK: - Mode B: LTR Identifiers Wrapped in LRI...PDI

    func testModeB_LTRIdentifierWrappedInLRI() {
        let tokens = [Token.identifier("hello", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "\(lri)hello\(pdi)")
    }

    func testModeB_LTRKeywordWrappedInLRI() {
        let tokens = [Token.keyword("func", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "\(lri)func\(pdi)")
    }

    // MARK: - Mode B: Operator Slashes Flipped

    func testModeB_operatorSlashesFlipped() {
        let tokens = [Token.operatorToken("/", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        // "/" becomes "\" wrapped in LRI...PDI
        XCTAssertEqual(result, "\(lri)\\\(pdi)")
    }

    func testModeB_operatorBackslashFlipped() {
        let tokens = [Token.operatorToken("\\", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        // "\" becomes "/" wrapped in LRI...PDI
        XCTAssertEqual(result, "\(lri)/\(pdi)")
    }

    func testModeB_operatorNoSlashes_unchanged() {
        let tokens = [Token.operatorToken("==", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "\(lri)==\(pdi)")
    }

    // MARK: - Mode B: Strings Wrapped in FSI...PDI

    func testModeB_stringWrappedInFSI() {
        let tokens = [Token.stringLiteral("\"hello\"", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "\(fsi)\"hello\"\(pdi)")
    }

    // MARK: - Mode B: LRM After Opening Brackets

    func testModeB_LRMAfterOpenParen() {
        let tokens = [Token.punctuation("(", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "(\(lrm)")
    }

    func testModeB_LRMAfterOpenBracket() {
        let tokens = [Token.punctuation("[", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "[\(lrm)")
    }

    func testModeB_LRMAfterOpenBrace() {
        let tokens = [Token.punctuation("{", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "{\(lrm)")
    }

    func testModeB_noLRMAfterClosingBracket() {
        let tokens = [Token.punctuation(")", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, ")")
    }

    func testModeB_noLRMAfterClosingBrace() {
        let tokens = [Token.punctuation("}", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "}")
    }

    // MARK: - Mode B: Whitespace, Comments, Numbers Pass Through

    func testModeB_whitespacePassesThrough() {
        let tokens = [Token.whitespace("  ", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "  ")
    }

    func testModeB_commentPassesThrough() {
        let tokens = [Token.comment("// comment", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "// comment")
    }

    func testModeB_numberPassesThrough() {
        let tokens = [Token.numberLiteral("42", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeB)

        XCTAssertEqual(result, "42")
    }

    // MARK: - Mode A: Strips All BiDi Characters

    func testModeA_stripsAllBiDi() {
        // Tokens that produce BiDi in mode B should have them stripped in mode A
        let tokens = [
            Token.keyword("func", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.identifier("hello", dummyRange),
        ]
        let result = annotator.annotate(tokens, target: .modeA)

        // Mode A: plain LTR output, no BiDi characters
        XCTAssertEqual(result, "func hello")
        XCTAssertFalse(result.contains(lri))
        XCTAssertFalse(result.contains(rli))
        XCTAssertFalse(result.contains(pdi))
        XCTAssertFalse(result.contains(lrm))
    }

    func testModeC_stripsAllBiDi() {
        let tokens = [
            Token.keyword("func", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.identifier("hello", dummyRange),
        ]
        let result = annotator.annotate(tokens, target: .modeC)

        XCTAssertEqual(result, "func hello")
        XCTAssertFalse(result.contains(lri))
        XCTAssertFalse(result.contains(rli))
    }

    // MARK: - Mode A/C: Flips Operator Slashes Back

    func testModeA_flipsOperatorSlashesBack() {
        // If tokens come from Mode B parsing, operator "/" was flipped to "\"
        // Mode A should flip them back
        let tokens = [Token.operatorToken("\\", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeA)

        XCTAssertEqual(result, "/")
    }

    func testModeC_flipsOperatorSlashesBack() {
        let tokens = [Token.operatorToken("\\", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeC)

        XCTAssertEqual(result, "/")
    }

    func testModeA_nonSlashOperatorsUnchanged() {
        let tokens = [Token.operatorToken("==", dummyRange)]
        let result = annotator.annotate(tokens, target: .modeA)

        XCTAssertEqual(result, "==")
    }

    // MARK: - containsRTL Helper

    func testContainsRTL_trueForHebrew() {
        XCTAssertTrue("שלום".containsRTL)
    }

    func testContainsRTL_trueForYiddish() {
        XCTAssertTrue("פֿונקציע".containsRTL)
    }

    func testContainsRTL_falseForLatin() {
        XCTAssertFalse("hello".containsRTL)
    }

    func testContainsRTL_falseForEmpty() {
        XCTAssertFalse("".containsRTL)
    }

    func testContainsRTL_falseForNumbers() {
        XCTAssertFalse("12345".containsRTL)
    }

    func testContainsRTL_trueForMixed() {
        XCTAssertTrue("hello שלום".containsRTL)
    }

    // MARK: - Complex Mode B Output

    func testModeB_complexExpression() {
        let tokens = [
            Token.keyword("פֿונקציע", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.identifier("שלום", dummyRange),
            Token.punctuation("(", dummyRange),
            Token.punctuation(")", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.punctuation("{", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.keyword("צוריק", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.numberLiteral("42", dummyRange),
            Token.whitespace(" ", dummyRange),
            Token.punctuation("}", dummyRange),
        ]
        let result = annotator.annotate(tokens, target: .modeB)

        // Verify structure: RTL keywords/identifiers in RLI, brackets with LRM
        XCTAssertTrue(result.contains("\(rli)פֿונקציע\(pdi)"))
        XCTAssertTrue(result.contains("\(rli)שלום\(pdi)"))
        XCTAssertTrue(result.contains("(\(lrm)"))
        XCTAssertTrue(result.contains("\(rli)צוריק\(pdi)"))
        XCTAssertTrue(result.contains("42"))
    }
}
