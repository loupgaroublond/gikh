// ScannerTests.swift
// GikhCore — Tests for the Scanner (lexer).

import XCTest
@testable import GikhCore

final class ScannerTests: XCTestCase {

    // MARK: - Helpers

    /// Scan source into tokens.
    private func scan(_ source: String) -> [Token] {
        var scanner = Scanner(source: source)
        return scanner.scan()
    }

    /// Assert a single token was produced with the expected type and text.
    private func assertSingleToken(
        _ source: String,
        isType check: (Token) -> Bool,
        hasText expectedText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let tokens = scan(source)
        XCTAssertEqual(tokens.count, 1, "Expected 1 token, got \(tokens.count): \(tokens)", file: file, line: line)
        guard let token = tokens.first else { return }
        XCTAssertTrue(check(token), "Token type mismatch: \(token)", file: file, line: line)
        XCTAssertEqual(token.text, expectedText, file: file, line: line)
    }

    private func isIdentifier(_ token: Token) -> Bool {
        if case .identifier = token { return true }
        return false
    }

    private func isKeyword(_ token: Token) -> Bool {
        if case .keyword = token { return true }
        return false
    }

    private func isNumberLiteral(_ token: Token) -> Bool {
        if case .numberLiteral = token { return true }
        return false
    }

    private func isStringLiteral(_ token: Token) -> Bool {
        if case .stringLiteral = token { return true }
        return false
    }

    private func isComment(_ token: Token) -> Bool {
        if case .comment = token { return true }
        return false
    }

    private func isWhitespace(_ token: Token) -> Bool {
        if case .whitespace = token { return true }
        return false
    }

    private func isPunctuation(_ token: Token) -> Bool {
        if case .punctuation = token { return true }
        return false
    }

    private func isOperator(_ token: Token) -> Bool {
        if case .operatorToken = token { return true }
        return false
    }

    // MARK: - Identifiers

    func testSimpleIdentifier() {
        assertSingleToken("hello", isType: isIdentifier, hasText: "hello")
    }

    func testIdentifierWithUnderscore() {
        assertSingleToken("_foo", isType: isIdentifier, hasText: "_foo")
    }

    func testIdentifierWithNumbers() {
        assertSingleToken("x42", isType: isIdentifier, hasText: "x42")
    }

    // MARK: - Swift Keywords

    func testSwiftKeyword_func() {
        assertSingleToken("func", isType: isKeyword, hasText: "func")
    }

    func testSwiftKeyword_let() {
        assertSingleToken("let", isType: isKeyword, hasText: "let")
    }

    func testSwiftKeyword_var() {
        assertSingleToken("var", isType: isKeyword, hasText: "var")
    }

    func testSwiftKeyword_return() {
        assertSingleToken("return", isType: isKeyword, hasText: "return")
    }

    func testSwiftKeyword_if() {
        assertSingleToken("if", isType: isKeyword, hasText: "if")
    }

    func testSwiftKeyword_struct() {
        assertSingleToken("struct", isType: isKeyword, hasText: "struct")
    }

    // MARK: - Yiddish Keywords

    func testYiddishKeyword_func() {
        assertSingleToken("פֿונקציע", isType: isKeyword, hasText: "פֿונקציע")
    }

    func testYiddishKeyword_let() {
        assertSingleToken("לאָז", isType: isKeyword, hasText: "לאָז")
    }

    func testYiddishKeyword_var() {
        assertSingleToken("באַשטימען", isType: isKeyword, hasText: "באַשטימען")
    }

    func testYiddishKeyword_return() {
        assertSingleToken("צוריק", isType: isKeyword, hasText: "צוריק")
    }

    func testYiddishKeyword_if() {
        assertSingleToken("אויב", isType: isKeyword, hasText: "אויב")
    }

    // MARK: - Number Literals

    func testNumberLiteral_integer() {
        assertSingleToken("42", isType: isNumberLiteral, hasText: "42")
    }

    func testNumberLiteral_hex() {
        assertSingleToken("0xFF", isType: isNumberLiteral, hasText: "0xFF")
    }

    func testNumberLiteral_hexUppercase() {
        assertSingleToken("0XAB", isType: isNumberLiteral, hasText: "0XAB")
    }

    func testNumberLiteral_float() {
        assertSingleToken("3.14", isType: isNumberLiteral, hasText: "3.14")
    }

    func testNumberLiteral_exponent() {
        assertSingleToken("1e10", isType: isNumberLiteral, hasText: "1e10")
    }

    func testNumberLiteral_floatWithExponent() {
        assertSingleToken("2.5E-3", isType: isNumberLiteral, hasText: "2.5E-3")
    }

    func testNumberLiteral_octal() {
        assertSingleToken("0o77", isType: isNumberLiteral, hasText: "0o77")
    }

    func testNumberLiteral_binary() {
        assertSingleToken("0b1010", isType: isNumberLiteral, hasText: "0b1010")
    }

    func testNumberLiteral_underscoreSeparated() {
        assertSingleToken("1_000_000", isType: isNumberLiteral, hasText: "1_000_000")
    }

    // MARK: - String Literals

    func testStringLiteral_simple() {
        assertSingleToken("\"hello\"", isType: isStringLiteral, hasText: "\"hello\"")
    }

    func testStringLiteral_empty() {
        assertSingleToken("\"\"", isType: isStringLiteral, hasText: "\"\"")
    }

    func testStringLiteral_withEscape() {
        assertSingleToken("\"he\\nllo\"", isType: isStringLiteral, hasText: "\"he\\nllo\"")
    }

    func testStringLiteral_withInterpolation() {
        let source = "\"hello \\(name)\""
        let tokens = scan(source)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isStringLiteral(tokens[0]))
        XCTAssertEqual(tokens[0].text, source)
    }

    func testStringLiteral_multiLine() {
        let source = "\"\"\"\nhello\nworld\n\"\"\""
        let tokens = scan(source)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isStringLiteral(tokens[0]))
        XCTAssertEqual(tokens[0].text, source)
    }

    func testStringLiteral_raw() {
        let source = "#\"hello\"#"
        let tokens = scan(source)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isStringLiteral(tokens[0]))
        XCTAssertEqual(tokens[0].text, source)
    }

    func testStringLiteral_rawWithDoubleHash() {
        let source = "##\"hello\"##"
        let tokens = scan(source)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isStringLiteral(tokens[0]))
        XCTAssertEqual(tokens[0].text, source)
    }

    func testStringLiteral_rawWithInterpolation() {
        let source = "#\"value: \\#(x)\"#"
        let tokens = scan(source)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isStringLiteral(tokens[0]))
        XCTAssertEqual(tokens[0].text, source)
    }

    // MARK: - Comments

    func testSingleLineComment() {
        let source = "// this is a comment"
        assertSingleToken(source, isType: isComment, hasText: source)
    }

    func testSingleLineComment_empty() {
        assertSingleToken("//", isType: isComment, hasText: "//")
    }

    func testMultiLineComment() {
        let source = "/* comment */"
        assertSingleToken(source, isType: isComment, hasText: source)
    }

    func testMultiLineComment_multipleLines() {
        let source = "/* line1\nline2\nline3 */"
        assertSingleToken(source, isType: isComment, hasText: source)
    }

    func testNestedMultiLineComment() {
        let source = "/* outer /* inner */ still outer */"
        assertSingleToken(source, isType: isComment, hasText: source)
    }

    func testNestedMultiLineComment_deeplyNested() {
        let source = "/* /* /* deep */ */ */"
        assertSingleToken(source, isType: isComment, hasText: source)
    }

    // MARK: - Whitespace

    func testWhitespace_spaces() {
        let source = "   "
        assertSingleToken(source, isType: isWhitespace, hasText: source)
    }

    func testWhitespace_newlines() {
        let source = "\n\n"
        assertSingleToken(source, isType: isWhitespace, hasText: source)
    }

    func testWhitespace_mixed() {
        let source = " \n\t"
        assertSingleToken(source, isType: isWhitespace, hasText: source)
    }

    // MARK: - Punctuation

    func testPunctuation_parentheses() {
        let tokens = scan("()")
        XCTAssertEqual(tokens.count, 2)
        XCTAssertTrue(isPunctuation(tokens[0]))
        XCTAssertEqual(tokens[0].text, "(")
        XCTAssertTrue(isPunctuation(tokens[1]))
        XCTAssertEqual(tokens[1].text, ")")
    }

    func testPunctuation_brackets() {
        let tokens = scan("[]")
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(tokens[0].text, "[")
        XCTAssertEqual(tokens[1].text, "]")
    }

    func testPunctuation_braces() {
        let tokens = scan("{}")
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(tokens[0].text, "{")
        XCTAssertEqual(tokens[1].text, "}")
    }

    func testPunctuation_allBrackets() {
        let tokens = scan("({[]})")
        XCTAssertEqual(tokens.count, 6)
        XCTAssertEqual(tokens.map(\.text), ["(", "{", "[", "]", "}", ")"])
        for token in tokens {
            XCTAssertTrue(isPunctuation(token))
        }
    }

    func testPunctuation_comma() {
        assertSingleToken(",", isType: isPunctuation, hasText: ",")
    }

    func testPunctuation_semicolon() {
        assertSingleToken(";", isType: isPunctuation, hasText: ";")
    }

    func testPunctuation_colon() {
        assertSingleToken(":", isType: isPunctuation, hasText: ":")
    }

    func testPunctuation_dot() {
        assertSingleToken(".", isType: isPunctuation, hasText: ".")
    }

    func testPunctuation_at() {
        assertSingleToken("@", isType: isPunctuation, hasText: "@")
    }

    func testPunctuation_hash() {
        // Standalone # without following " is punctuation
        assertSingleToken("#", isType: isPunctuation, hasText: "#")
    }

    // MARK: - Operators

    func testOperator_plus() {
        assertSingleToken("+", isType: isOperator, hasText: "+")
    }

    func testOperator_minus() {
        assertSingleToken("-", isType: isOperator, hasText: "-")
    }

    func testOperator_compound() {
        assertSingleToken("+-", isType: isOperator, hasText: "+-")
    }

    func testOperator_equals() {
        assertSingleToken("==", isType: isOperator, hasText: "==")
    }

    func testOperator_arrow() {
        assertSingleToken("->", isType: isOperator, hasText: "->")
    }

    func testOperator_forwardSlash() {
        // Standalone "/" (not followed by / or *) is an operator
        let tokens = scan("/")
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isOperator(tokens[0]))
        XCTAssertEqual(tokens[0].text, "/")
    }

    // MARK: - Backslash (Keypath)

    func testBackslash_keypathOperator() {
        let tokens = scan("\\")
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isOperator(tokens[0]))
        XCTAssertEqual(tokens[0].text, "\\")
    }

    // MARK: - Backtick Identifiers

    func testBacktickIdentifier() {
        assertSingleToken("`class`", isType: isIdentifier, hasText: "`class`")
    }

    func testBacktickIdentifier_regularWord() {
        assertSingleToken("`myVar`", isType: isIdentifier, hasText: "`myVar`")
    }

    // MARK: - Mixed Code

    func testMixedEnglish_funcDeclaration() {
        let source = "func hello() { return 42 }"
        let tokens = scan(source)

        // Filter out whitespace for easier assertion
        let meaningful = tokens.filter { !isWhitespace($0) }

        XCTAssertEqual(meaningful.count, 8)
        XCTAssertEqual(meaningful[0], Token.keyword("func", meaningful[0].range))
        XCTAssertEqual(meaningful[1], Token.identifier("hello", meaningful[1].range))
        XCTAssertEqual(meaningful[2].text, "(")
        XCTAssertEqual(meaningful[3].text, ")")
        XCTAssertEqual(meaningful[4].text, "{")
        XCTAssertEqual(meaningful[5], Token.keyword("return", meaningful[5].range))
        XCTAssertEqual(meaningful[6], Token.numberLiteral("42", meaningful[6].range))
        XCTAssertEqual(meaningful[7].text, "}")
    }

    func testMixedEnglish_fullFunction() {
        let source = "func hello() { return 42 }"
        let tokens = scan(source)
        let meaningful = tokens.filter { !isWhitespace($0) }

        XCTAssertTrue(isKeyword(meaningful[0]))
        XCTAssertEqual(meaningful[0].text, "func")
        XCTAssertTrue(isIdentifier(meaningful[1]))
        XCTAssertEqual(meaningful[1].text, "hello")
        XCTAssertTrue(isKeyword(meaningful[5]))
        XCTAssertEqual(meaningful[5].text, "return")
    }

    func testMixedYiddish_funcDeclaration() {
        let source = "פֿונקציע שלום() { צוריק 42 }"
        let tokens = scan(source)
        let meaningful = tokens.filter { !isWhitespace($0) }

        XCTAssertTrue(isKeyword(meaningful[0]))
        XCTAssertEqual(meaningful[0].text, "פֿונקציע")
        XCTAssertTrue(isIdentifier(meaningful[1]))
        XCTAssertEqual(meaningful[1].text, "שלום")
        XCTAssertTrue(isPunctuation(meaningful[2]))
        XCTAssertEqual(meaningful[2].text, "(")
        XCTAssertTrue(isPunctuation(meaningful[3]))
        XCTAssertEqual(meaningful[3].text, ")")
        XCTAssertTrue(isPunctuation(meaningful[4]))
        XCTAssertEqual(meaningful[4].text, "{")
        XCTAssertTrue(isKeyword(meaningful[5]))
        XCTAssertEqual(meaningful[5].text, "צוריק")
        XCTAssertTrue(isNumberLiteral(meaningful[6]))
        XCTAssertEqual(meaningful[6].text, "42")
    }

    // MARK: - Empty Input

    func testEmptyInput() {
        let tokens = scan("")
        XCTAssertTrue(tokens.isEmpty)
    }

    // MARK: - Preservation

    func testPreservesAllText() {
        let sources = [
            "func hello() { return 42 }",
            "פֿונקציע שלום() { צוריק 42 }",
            "let x = \"hello \\(name)\" // comment",
            "/* multi\nline */ struct Foo {}",
            "0xFF + 3.14 - 0b1010",
            "",
        ]

        for source in sources {
            let tokens = scan(source)
            let reconstructed = tokens.map(\.text).joined()
            XCTAssertEqual(
                reconstructed, source,
                "Token texts should concatenate to original source"
            )
        }
    }

    func testPreservesAllText_complexExample() {
        let source = """
        import Foundation

        // A greeting function
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }

        let result = greet("World")
        /* end */
        """

        let tokens = scan(source)
        let reconstructed = tokens.map(\.text).joined()
        XCTAssertEqual(reconstructed, source)
    }

    // MARK: - Edge Cases

    func testCommentFollowedByNewline() {
        let source = "// comment\nlet x = 1"
        let tokens = scan(source)

        XCTAssertTrue(isComment(tokens[0]))
        XCTAssertEqual(tokens[0].text, "// comment")
        // The newline should be captured as whitespace
        XCTAssertTrue(isWhitespace(tokens[1]))
    }

    func testMultipleTokenTypes_comprehensive() {
        let source = "@main struct App: Protocol {}"
        let tokens = scan(source)
        let meaningful = tokens.filter { !isWhitespace($0) }

        XCTAssertTrue(isPunctuation(meaningful[0]))
        XCTAssertEqual(meaningful[0].text, "@")
        XCTAssertTrue(isIdentifier(meaningful[1]))
        XCTAssertEqual(meaningful[1].text, "main")
        XCTAssertTrue(isKeyword(meaningful[2]))
        XCTAssertEqual(meaningful[2].text, "struct")
    }

    func testStringWithNestedInterpolation() {
        let source = "\"a \\(b + c) d\""
        let tokens = scan(source)
        XCTAssertEqual(tokens.count, 1)
        XCTAssertTrue(isStringLiteral(tokens[0]))
        XCTAssertEqual(tokens[0].text, source)
    }

    func testConsecutiveComments() {
        let source = "// first\n// second"
        let tokens = scan(source)
        let comments = tokens.filter { isComment($0) }
        XCTAssertEqual(comments.count, 2)
        XCTAssertEqual(comments[0].text, "// first")
        XCTAssertEqual(comments[1].text, "// second")
    }
}
