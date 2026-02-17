// Scanner.swift
// GikhCore — Lexer for the Gikh Yiddish-Swift transpiler.

// MARK: - Keyword Sets

/// All Swift reserved keywords.
public let SwiftKeywords: Set<String> = [
    // Declaration keywords
    "associatedtype", "class", "deinit", "enum", "extension",
    "fileprivate", "func", "import", "init", "inout", "internal",
    "let", "open", "operator", "private", "precedencegroup",
    "protocol", "public", "rethrows", "static", "struct",
    "subscript", "typealias", "var",
    // Statement keywords
    "break", "case", "catch", "continue", "default", "defer",
    "do", "else", "fallthrough", "for", "guard", "if", "in",
    "repeat", "return", "switch", "throw", "try", "where", "while",
    // Expression keywords
    "as", "Any", "false", "is", "nil", "self", "Self", "super",
    "throws", "true",
    // Concurrency keywords
    "async", "await",
    // Type keywords
    "some", "any",
    // Macro keyword
    "macro",
    // Ownership keywords
    "consuming", "borrowing", "noncopyable",
]

/// All Yiddish keyword translations.
public let YiddishKeywords: Set<String> = [
    "פֿונקציע",          // func
    "לאָז",              // let
    "באַשטימען",          // var
    "צוריק",             // return
    "אויב",              // if
    "אַנדערש",            // else
    "פֿאַר",              // for
    "אין",               // in
    "בשעת",              // while
    "סטרוקטור",          // struct
    "קלאַס",             // class
    "פּראָטאָקאָל",        // protocol
    "היטער",             // guard
    "וועקסל",            // switch
    "פֿאַל",              // case
    "ברעכן",             // break
    "ממשיכן",            // continue
    "טאָן",              // do
    "כאַפּן",             // catch
    "וואַרפֿן",           // throw
    "וואַרפֿט",           // throws
    "אַסינכראָן",         // async
    "וואַרטן",            // await
    "סטאַטיש",           // static
    "פּריוואַט",          // private
    "עפֿנטלעך",          // public
    "אינערלעך",          // internal
    "פֿאַרלענגערונג",      // extension
    "אימפּאָרט",          // import
    "ענום",              // enum
    "טיפּ_כּינוי",        // typealias
    "אויפֿרוף",          // subscript
    "באַזונדער",          // deinit
    "אָפּן",              // open
    "פּראָטאָקאָל_טיפּ",   // associatedtype
    "ניט_קאָפּירבאַר",     // noncopyable
    "פּראָבירן",          // try
    "אַלץ",              // as
    "יעדער",             // Any
    "פֿאַלש",             // false
    "אמת",               // true
    "גאָרנישט",           // nil
    "זיך",               // self
    "זיך_טיפּ",           // Self
    "העכער",             // super
    "עטלעכע",            // some
    "ווידער",            // repeat
    "וואו",              // where
    "אַראָפּפֿאַלן",       // fallthrough
    "אָפּלייגן",          // defer
    "פֿעליק",             // default
]

// MARK: - Scanner

/// A lexer that tokenizes Swift and Gikh source code into a flat array of `Token` values.
///
/// The scanner processes the entire source string left-to-right, producing one token per
/// lexical element. String literal contents (including interpolations) are opaque — the
/// entire literal is returned as a single `.stringLiteral` token.
public struct Scanner {
    public let source: String
    private var position: String.Index

    public init(source: String) {
        self.source = source
        self.position = source.startIndex
    }

    // MARK: - Public API

    /// Scan the entire source, returning all tokens in order.
    public mutating func scan() -> [Token] {
        var tokens: [Token] = []
        while position < source.endIndex {
            let token = scanNextToken()
            tokens.append(token)
        }
        return tokens
    }

    // MARK: - Character Helpers

    /// Returns the current character without advancing, or `nil` at end-of-input.
    private func peek() -> Character? {
        guard position < source.endIndex else { return nil }
        return source[position]
    }

    /// Returns the character at the given offset from `position`, or `nil` if out of bounds.
    private func peek(offset: Int) -> Character? {
        var idx = position
        for _ in 0..<offset {
            guard idx < source.endIndex else { return nil }
            idx = source.index(after: idx)
        }
        guard idx < source.endIndex else { return nil }
        return source[idx]
    }

    /// Advances position by one character.
    @discardableResult
    private mutating func advance() -> Character? {
        guard position < source.endIndex else { return nil }
        let ch = source[position]
        position = source.index(after: position)
        return ch
    }

    /// Advances position by `n` characters.
    private mutating func advance(by n: Int) {
        for _ in 0..<n {
            guard position < source.endIndex else { break }
            position = source.index(after: position)
        }
    }

    /// Returns the substring from `start` to the current position.
    private func text(from start: String.Index) -> String {
        String(source[start..<position])
    }

    // MARK: - Token Dispatch

    private mutating func scanNextToken() -> Token {
        let start = position
        guard let ch = peek() else {
            // Should not happen — caller checks position < endIndex.
            advance()
            return .unknown(text(from: start), start..<position)
        }

        // Whitespace
        if ch.isWhitespace || ch.isNewline {
            return scanWhitespace(from: start)
        }

        // Comments and division operator
        if ch == "/" {
            if let next = peek(offset: 1) {
                if next == "/" {
                    return scanSingleLineComment(from: start)
                }
                if next == "*" {
                    return scanMultiLineComment(from: start)
                }
            }
            // Fall through — "/" is an operator character
        }

        // String literals (possibly raw)
        if ch == "\"" {
            return scanStringLiteral(from: start, poundCount: 0)
        }

        // Raw string literals: # followed by more #'s then "
        if ch == "#" {
            let poundCount = countPoundsAtPosition()
            if let afterPounds = peek(offset: poundCount), afterPounds == "\"" {
                return scanRawStringLiteral(from: start, poundCount: poundCount)
            }
            // Standalone # is punctuation
        }

        // Number literals
        if ch.isNumber || (ch == "." && peek(offset: 1)?.isNumber == true) {
            // Only start a number with "." if there's a digit after it;
            // but Swift doesn't actually allow bare ".5" — a leading dot is
            // the member-access operator. So only start with a digit.
            if ch.isNumber {
                return scanNumberLiteral(from: start)
            }
        }

        // Backtick-escaped identifier
        if ch == "`" {
            return scanBacktickIdentifier(from: start)
        }

        // Words (identifiers / keywords): letter, underscore, or Unicode letter
        if isWordStart(ch) {
            return scanWord(from: start)
        }

        // Backslash — operator (keypath)
        if ch == "\\" {
            advance()
            return .operatorToken(text(from: start), start..<position)
        }

        // Punctuation: single-character tokens
        if isPunctuation(ch) {
            advance()
            return .punctuation(text(from: start), start..<position)
        }

        // Operators: sequences of operator characters
        if isOperatorCharacter(ch) {
            return scanOperator(from: start)
        }

        // Unknown character
        advance()
        return .unknown(text(from: start), start..<position)
    }

    // MARK: - Whitespace

    private mutating func scanWhitespace(from start: String.Index) -> Token {
        while let ch = peek(), ch.isWhitespace || ch.isNewline {
            advance()
        }
        return .whitespace(text(from: start), start..<position)
    }

    // MARK: - Comments

    private mutating func scanSingleLineComment(from start: String.Index) -> Token {
        // Consume "//"
        advance(by: 2)
        // Consume until end of line (newline is NOT included in the comment token)
        while let ch = peek(), ch != "\n" && ch != "\r" {
            advance()
        }
        return .comment(text(from: start), start..<position)
    }

    private mutating func scanMultiLineComment(from start: String.Index) -> Token {
        // Consume "/*"
        advance(by: 2)
        var depth = 1
        while depth > 0, position < source.endIndex {
            let ch = peek()!
            if ch == "/" && peek(offset: 1) == "*" {
                advance(by: 2)
                depth += 1
            } else if ch == "*" && peek(offset: 1) == "/" {
                advance(by: 2)
                depth -= 1
            } else {
                advance()
            }
        }
        return .comment(text(from: start), start..<position)
    }

    // MARK: - String Literals

    /// Count consecutive '#' characters starting at the current position.
    private func countPoundsAtPosition() -> Int {
        var count = 0
        var idx = position
        while idx < source.endIndex && source[idx] == "#" {
            count += 1
            idx = source.index(after: idx)
        }
        return count
    }

    /// Scan a raw string literal: `#"..."#`, `##"..."##`, etc.
    private mutating func scanRawStringLiteral(from start: String.Index, poundCount: Int) -> Token {
        // Consume the leading '#'s
        advance(by: poundCount)
        // Now position is at the opening '"'
        return scanStringLiteral(from: start, poundCount: poundCount)
    }

    /// Scan a string literal starting at the opening `"`.
    /// `poundCount` is 0 for normal strings, >0 for raw strings.
    private mutating func scanStringLiteral(from start: String.Index, poundCount: Int) -> Token {
        // Check for multi-line (""")
        let isMultiLine: Bool
        if peek() == "\"" && peek(offset: 1) == "\"" && peek(offset: 2) == "\"" {
            isMultiLine = true
            advance(by: 3) // Consume """
        } else {
            isMultiLine = false
            advance() // Consume opening "
        }

        scanStringBody(poundCount: poundCount, isMultiLine: isMultiLine)

        return .stringLiteral(text(from: start), start..<position)
    }

    /// Consume the body of a string literal until the matching closing delimiter.
    private mutating func scanStringBody(poundCount: Int, isMultiLine: Bool) {
        while position < source.endIndex {
            let ch = source[position]

            // Check for escape sequence: \###( for interpolation, or \###<other> for escape
            if ch == "\\" {
                if matchesPoundSequence(after: position, count: poundCount) {
                    let afterPounds = advancedIndex(from: position, by: 1 + poundCount)
                    if afterPounds < source.endIndex && source[afterPounds] == "(" {
                        // String interpolation: \###(
                        // Advance past \ + #'s + (
                        advance(by: 1 + poundCount + 1)
                        scanInterpolation()
                        continue
                    }
                }
                // Regular escape character or raw string escape — just consume \ and next char
                advance()
                if position < source.endIndex {
                    advance()
                }
                continue
            }

            // Check for closing delimiter
            if ch == "\"" {
                if isMultiLine {
                    // Need three quotes followed by poundCount '#'s
                    if peek(offset: 1) == "\"" && peek(offset: 2) == "\"" {
                        if matchesClosingPounds(after: position, quoteCount: 3, poundCount: poundCount) {
                            advance(by: 3 + poundCount)
                            return
                        }
                    }
                    // Not the closing delimiter — it's just a quote inside the multi-line string
                    advance()
                    continue
                } else {
                    // Single-line: one quote followed by poundCount '#'s
                    if matchesClosingPounds(after: position, quoteCount: 1, poundCount: poundCount) {
                        advance(by: 1 + poundCount)
                        return
                    }
                    // For raw strings, a lone " without matching #'s is just content
                    advance()
                    continue
                }
            }

            // For single-line non-raw strings, an unescaped newline ends the literal (error recovery)
            if !isMultiLine && poundCount == 0 && (ch == "\n" || ch == "\r") {
                return
            }

            advance()
        }
        // Unterminated string — return what we have
    }

    /// Scan a string interpolation body after the opening `(`.
    /// Handles nested parentheses and nested string literals.
    private mutating func scanInterpolation() {
        var depth = 1
        while depth > 0 && position < source.endIndex {
            let ch = source[position]

            if ch == "(" {
                depth += 1
                advance()
            } else if ch == ")" {
                depth -= 1
                advance()
                if depth == 0 {
                    return
                }
            } else if ch == "\"" {
                // Nested string literal inside interpolation — we discard the returned
                // token because we only need the side effect of advancing position.
                let nestedStart = position
                _ = scanStringLiteral(from: nestedStart, poundCount: 0)
            } else if ch == "/" {
                // Comments inside interpolations
                if peek(offset: 1) == "/" {
                    let commentStart = position
                    _ = scanSingleLineComment(from: commentStart)
                } else if peek(offset: 1) == "*" {
                    let commentStart = position
                    _ = scanMultiLineComment(from: commentStart)
                } else {
                    advance()
                }
            } else {
                advance()
            }
        }
    }

    /// Check if after `idx`, there are exactly `count` '#' characters.
    /// Used to verify escape sequences like `\#(` in raw strings.
    private func matchesPoundSequence(after idx: String.Index, count: Int) -> Bool {
        if count == 0 { return true }
        var current = source.index(after: idx)
        for _ in 0..<count {
            guard current < source.endIndex, source[current] == "#" else { return false }
            current = source.index(after: current)
        }
        return true
    }

    /// Check if after `quoteCount` quotes starting at `idx`, there are `poundCount` '#' chars.
    private func matchesClosingPounds(after idx: String.Index, quoteCount: Int, poundCount: Int) -> Bool {
        if poundCount == 0 { return true }
        var current = idx
        for _ in 0..<quoteCount {
            guard current < source.endIndex else { return false }
            current = source.index(after: current)
        }
        for _ in 0..<poundCount {
            guard current < source.endIndex, source[current] == "#" else { return false }
            current = source.index(after: current)
        }
        return true
    }

    /// Advance an index by `n` positions, clamped to `endIndex`.
    private func advancedIndex(from idx: String.Index, by n: Int) -> String.Index {
        var current = idx
        for _ in 0..<n {
            guard current < source.endIndex else { return source.endIndex }
            current = source.index(after: current)
        }
        return current
    }

    // MARK: - Number Literals

    private mutating func scanNumberLiteral(from start: String.Index) -> Token {
        let first = source[position]
        advance()

        // Check for 0x, 0o, 0b prefixes
        if first == "0", let prefix = peek() {
            switch prefix {
            case "x", "X":
                advance()
                consumeDigits(isHex: true)
                // Hex float: optional . and p exponent
                if peek() == "." && peek(offset: 1)?.isHexDigit == true {
                    advance() // consume "."
                    consumeDigits(isHex: true)
                }
                if let p = peek(), p == "p" || p == "P" {
                    advance()
                    if let sign = peek(), sign == "+" || sign == "-" {
                        advance()
                    }
                    consumeDigits(isHex: false)
                }
                return .numberLiteral(text(from: start), start..<position)

            case "o", "O":
                advance()
                consumeOctalDigits()
                return .numberLiteral(text(from: start), start..<position)

            case "b", "B":
                advance()
                consumeBinaryDigits()
                return .numberLiteral(text(from: start), start..<position)

            default:
                break
            }
        }

        // Decimal integer or float
        consumeDigits(isHex: false)

        // Fractional part: "." followed by a digit (not ".." range or ".identifier")
        if peek() == "." && peek(offset: 1)?.isNumber == true {
            advance() // consume "."
            consumeDigits(isHex: false)
        }

        // Exponent
        if let e = peek(), e == "e" || e == "E" {
            advance()
            if let sign = peek(), sign == "+" || sign == "-" {
                advance()
            }
            consumeDigits(isHex: false)
        }

        return .numberLiteral(text(from: start), start..<position)
    }

    private mutating func consumeDigits(isHex: Bool) {
        while let ch = peek() {
            if ch == "_" {
                advance()
                continue
            }
            if isHex {
                guard ch.isHexDigit else { break }
            } else {
                guard ch.isNumber else { break }
            }
            advance()
        }
    }

    private mutating func consumeOctalDigits() {
        while let ch = peek() {
            if ch == "_" { advance(); continue }
            guard ch >= "0" && ch <= "7" else { break }
            advance()
        }
    }

    private mutating func consumeBinaryDigits() {
        while let ch = peek() {
            if ch == "_" { advance(); continue }
            guard ch == "0" || ch == "1" else { break }
            advance()
        }
    }

    // MARK: - Words (Identifiers and Keywords)

    private func isWordStart(_ ch: Character) -> Bool {
        if ch == "_" { return true }
        if ch.isLetter { return true }
        // Unicode letters include Hebrew/Yiddish characters, which .isLetter covers.
        return false
    }

    private func isWordContinue(_ ch: Character) -> Bool {
        if ch == "_" { return true }
        if ch.isLetter { return true }
        if ch.isNumber { return true }
        // Unicode combining marks and other continuing characters are covered by
        // Character.isLetter for base letters. Combining marks (category M) on
        // their own are not valid identifiers in Swift, so we don't need to
        // special-case them here.
        return false
    }

    private mutating func scanWord(from start: String.Index) -> Token {
        advance() // consume first character
        while let ch = peek(), isWordContinue(ch) {
            advance()
        }
        let word = text(from: start)
        if SwiftKeywords.contains(word) || YiddishKeywords.contains(word) {
            return .keyword(word, start..<position)
        }
        return .identifier(word, start..<position)
    }

    // MARK: - Backtick Identifiers

    private mutating func scanBacktickIdentifier(from start: String.Index) -> Token {
        advance() // consume opening backtick
        while let ch = peek(), ch != "`" {
            // Backtick identifiers cannot span lines in Swift
            if ch == "\n" || ch == "\r" {
                break
            }
            advance()
        }
        if peek() == "`" {
            advance() // consume closing backtick
        }
        return .identifier(text(from: start), start..<position)
    }

    // MARK: - Operators

    private func isOperatorCharacter(_ ch: Character) -> Bool {
        switch ch {
        case "+", "-", "*", "/", "%", "=", "<", ">", "!", "&", "|", "^", "~", "?":
            return true
        default:
            return false
        }
    }

    private mutating func scanOperator(from start: String.Index) -> Token {
        while let ch = peek(), isOperatorCharacter(ch) {
            advance()
        }
        return .operatorToken(text(from: start), start..<position)
    }

    // MARK: - Punctuation

    private func isPunctuation(_ ch: Character) -> Bool {
        switch ch {
        case "(", ")", "[", "]", "{", "}", ",", ";", ":", ".", "@", "#":
            return true
        default:
            return false
        }
    }
}
