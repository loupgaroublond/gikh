/// Tokenises Swift / Gikh source code into a lossless stream of `Token` values.
///
/// The scanner is the first stage of the transpiler pipeline. Its contract:
/// - Every character in the source appears in exactly one token.
/// - Joining `token.text` for all tokens reproduces the original source verbatim.
/// - String literal *content* and comments are opaque: their text is captured
///   as-is and never examined further.
/// - String interpolation delimiters (`\(` and the matching `)`) are emitted
///   as `.interpolationDelimiter` tokens so the BiDi annotator can flip the
///   backslash in Mode B without touching string content.
/// - The expression inside an interpolation is scanned normally.
public struct Scanner {
    let source: String
    var position: String.Index

    public init(source: String) {
        self.source = source
        self.position = source.startIndex
    }

    // MARK: - Public entry point

    public mutating func scan() -> [Token] {
        position = source.startIndex
        var tokens: [Token] = []

        while position < source.endIndex {
            if scanStringLiteral(&tokens) { continue }
            if scanComment(&tokens) { continue }
            if scanWhitespace(&tokens) { continue }
            if scanNumber(&tokens) { continue }
            if scanOperator(&tokens) { continue }
            if scanPunctuation(&tokens) { continue }
            if scanWord(&tokens) { continue }

            // Fallthrough: emit unknown token for unrecognised character.
            let start = position
            advance()
            tokens.append(.unknown(String(source[start..<position]), start..<position))
        }

        return tokens
    }

    // MARK: - Peek / advance helpers

    private func peek(_ offset: Int = 0) -> Character? {
        let idx = source.index(position, offsetBy: offset, limitedBy: source.endIndex) ?? source.endIndex
        guard idx < source.endIndex else { return nil }
        return source[idx]
    }

    private func peek(ahead n: Int) -> Character? { peek(n) }

    private mutating func advance() {
        guard position < source.endIndex else { return }
        position = source.index(after: position)
    }

    /// Consume while predicate holds; return the consumed substring.
    private mutating func consume(while predicate: (Character) -> Bool) -> Substring {
        let start = position
        while let c = peek(), predicate(c) {
            advance()
        }
        return source[start..<position]
    }

    // MARK: - Whitespace (gikh-u1s)

    /// Scans one or more whitespace characters into a single `.whitespace` token.
    private mutating func scanWhitespace(_ tokens: inout [Token]) -> Bool {
        guard let c = peek(), c.isWhitespace else { return false }
        let start = position
        let text = consume(while: { $0.isWhitespace })
        tokens.append(.whitespace(String(text), start..<position))
        return true
    }

    // MARK: - Comments (gikh-u1s)

    private mutating func scanComment(_ tokens: inout [Token]) -> Bool {
        guard peek() == "/" else { return false }

        if peek(1) == "/" {
            return scanLineComment(&tokens)
        } else if peek(1) == "*" {
            return scanBlockComment(&tokens)
        }
        return false
    }

    private mutating func scanLineComment(_ tokens: inout [Token]) -> Bool {
        let start = position
        // consume "//"
        advance(); advance()
        // consume until newline (newline NOT included in comment token)
        _ = consume(while: { $0 != "\n" })
        tokens.append(.comment(String(source[start..<position]), start..<position))
        return true
    }

    private mutating func scanBlockComment(_ tokens: inout [Token]) -> Bool {
        let start = position
        // consume "/*"
        advance(); advance()
        // consume until "*/"
        while position < source.endIndex {
            if peek() == "*", peek(1) == "/" {
                advance(); advance()  // consume "*/"
                break
            }
            advance()
        }
        tokens.append(.comment(String(source[start..<position]), start..<position))
        return true
    }

    // MARK: - String Literals (gikh-g17)

    private mutating func scanStringLiteral(_ tokens: inout [Token]) -> Bool {
        guard let c = peek() else { return false }

        // Determine raw-string hash prefix count
        if c == "#" {
            return scanRawStringLiteral(&tokens)
        }

        if c == "\"" {
            if peek(1) == "\"", peek(2) == "\"" {
                return scanMultilineStringLiteral(&tokens, hashCount: 0)
            } else {
                return scanSingleLineStringLiteral(&tokens, hashCount: 0)
            }
        }

        return false
    }

    /// Reads zero or more leading `#` signs. Returns the count and advances.
    private mutating func countAndAdvanceHashes() -> Int {
        var count = 0
        while peek() == "#" {
            advance()
            count += 1
        }
        return count
    }

    private mutating func scanRawStringLiteral(_ tokens: inout [Token]) -> Bool {
        let start = position
        let hashCount = countAndAdvanceHashes()

        guard peek() == "\"" else {
            // Not a string — back up and let operator scanner handle the #
            position = start
            return false
        }

        if peek(1) == "\"", peek(2) == "\"" {
            // Raw multi-line
            return scanMultilineStringLiteral(&tokens, hashCount: hashCount, literalStart: start)
        } else {
            return scanSingleLineStringLiteral(&tokens, hashCount: hashCount, literalStart: start)
        }
    }

    private mutating func scanSingleLineStringLiteral(
        _ tokens: inout [Token],
        hashCount: Int,
        literalStart: String.Index? = nil
    ) -> Bool {
        let start = literalStart ?? position
        // consume opening "
        advance()

        // For single-line strings with interpolation, we need to emit separate tokens
        // for the interpolation delimiters. Only do this when hashCount == 0.
        if hashCount == 0 {
            return scanSingleLineStringWithInterpolation(&tokens, start: start)
        }

        // Raw string: no interpolation, scan until closing "#...# sequence
        let closingSequence = "\"" + String(repeating: "#", count: hashCount)
        while position < source.endIndex {
            if matchesClosingRawSequence(closingSequence) {
                advancePast(closingSequence)
                break
            }
            advance()
        }
        tokens.append(.stringLiteral(String(source[start..<position]), start..<position))
        return true
    }

    /// Checks if the current position matches the closing sequence without advancing.
    private func matchesClosingRawSequence(_ sequence: String) -> Bool {
        var idx = position
        for ch in sequence {
            guard idx < source.endIndex, source[idx] == ch else { return false }
            idx = source.index(after: idx)
        }
        return true
    }

    /// Advance past a known sequence (assumes it matches).
    private mutating func advancePast(_ sequence: String) {
        for _ in sequence { advance() }
    }

    /// Scans a single-line string literal (hashCount == 0) emitting
    /// interpolation delimiters as separate tokens.
    private mutating func scanSingleLineStringWithInterpolation(
        _ tokens: inout [Token],
        start: String.Index
    ) -> Bool {
        // Segments: collect characters into a "current literal fragment"
        // and emit interpolation delimiters + expressions inline.
        var fragmentStart = start  // includes the opening quote already consumed

        while position < source.endIndex {
            let c = peek()!

            if c == "\"" {
                // Closing quote — emit final fragment including this quote
                advance()
                let fragText = String(source[fragmentStart..<position])
                if !fragText.isEmpty {
                    tokens.append(.stringLiteral(fragText, fragmentStart..<position))
                }
                return true
            }

            if c == "\\" && peek(1) == "(" {
                // Start of interpolation: emit string fragment so far (including \()
                // Wait — we need to emit the fragment UP TO (not including) the \(,
                // then emit \( as interpolationDelimiter, then scan expression,
                // then emit ) as interpolationDelimiter, then continue string.
                let fragEnd = position
                let fragText = String(source[fragmentStart..<fragEnd])
                if !fragText.isEmpty {
                    tokens.append(.stringLiteral(fragText, fragmentStart..<fragEnd))
                }
                // Emit \( as interpolationDelimiter
                let delimStart = position
                advance(); advance()  // consume \ and (
                tokens.append(.interpolationDelimiter(String(source[delimStart..<position]), delimStart..<position))

                // Scan the interpolated expression (respecting nested parens)
                scanInterpolatedExpression(&tokens)

                // After scanInterpolatedExpression, position is past the closing )
                // that matched the \( — that ) was already emitted as interpolationDelimiter.
                // Resume collecting the string fragment.
                fragmentStart = position
                continue
            }

            if c == "\\" {
                // Other escape sequence: consume backslash + next char
                advance()
                if peek() != nil { advance() }
                continue
            }

            if c == "\n" {
                // Unterminated string literal — emit what we have and stop
                let fragText = String(source[fragmentStart..<position])
                if !fragText.isEmpty {
                    tokens.append(.stringLiteral(fragText, fragmentStart..<position))
                }
                return true
            }

            advance()
        }

        // EOF while in string
        let fragText = String(source[fragmentStart..<position])
        if !fragText.isEmpty {
            tokens.append(.stringLiteral(fragText, fragmentStart..<position))
        }
        return true
    }

    /// Scans an interpolated expression, handling nested parentheses.
    /// Emits all tokens in the expression normally. Emits the final `)` as
    /// `.interpolationDelimiter` and consumes it.
    private mutating func scanInterpolatedExpression(_ tokens: inout [Token]) {
        var depth = 1

        while position < source.endIndex, depth > 0 {
            if scanStringLiteral(&tokens) { continue }
            if scanComment(&tokens) { continue }
            if scanWhitespace(&tokens) { continue }
            if scanNumber(&tokens) { continue }

            let c = peek()!

            if c == "(" {
                let start = position
                advance()
                depth += 1
                tokens.append(.punctuation("(", start..<position))
                continue
            }

            if c == ")" {
                depth -= 1
                let start = position
                advance()
                if depth == 0 {
                    tokens.append(.interpolationDelimiter(")", start..<position))
                } else {
                    tokens.append(.punctuation(")", start..<position))
                }
                continue
            }

            if scanOperator(&tokens) { continue }
            if scanPunctuation(&tokens) { continue }
            if scanWord(&tokens) { continue }

            let start = position
            advance()
            tokens.append(.unknown(String(source[start..<position]), start..<position))
        }
    }

    private mutating func scanMultilineStringLiteral(
        _ tokens: inout [Token],
        hashCount: Int,
        literalStart: String.Index? = nil
    ) -> Bool {
        let start = literalStart ?? position
        // Consume opening """
        advance(); advance(); advance()

        // For hash == 0 with potential interpolation, we still scan the whole thing
        // as an opaque block for multiline (the design doc treats multiline as opaque
        // for simplicity in this phase — interpolation inside multiline is preserved verbatim).
        // This is a conservative choice; interpolation in multiline can be added later.
        // Closing sequence: """ followed by the same number of # as the opening.
        let closing = "\"\"\"" + String(repeating: "#", count: hashCount)

        while position < source.endIndex {
            if matchesClosingRawSequence(closing) {
                advancePast(closing)
                break
            }
            advance()
        }

        tokens.append(.stringLiteral(String(source[start..<position]), start..<position))
        return true
    }

    // MARK: - Numbers (gikh-ate)

    private mutating func scanNumber(_ tokens: inout [Token]) -> Bool {
        guard let c = peek() else { return false }

        if c.isNumber {
            return scanNumericLiteral(&tokens)
        }

        // Negative sign is part of the operator, not the number.
        return false
    }

    private mutating func scanNumericLiteral(_ tokens: inout [Token]) -> Bool {
        let start = position

        if peek() == "0" {
            if peek(1) == "x" || peek(1) == "X" {
                advance(); advance()  // consume 0x
                _ = consume(while: { $0.isHexDigit || $0 == "_" })
                // Optional float exponent: p+N or p-N
                if peek() == "p" || peek() == "P" {
                    advance()
                    if peek() == "+" || peek() == "-" { advance() }
                    _ = consume(while: { $0.isNumber || $0 == "_" })
                }
                tokens.append(.numberLiteral(String(source[start..<position]), start..<position))
                return true
            }

            if peek(1) == "b" || peek(1) == "B" {
                advance(); advance()  // consume 0b
                _ = consume(while: { $0 == "0" || $0 == "1" || $0 == "_" })
                tokens.append(.numberLiteral(String(source[start..<position]), start..<position))
                return true
            }

            if peek(1) == "o" || peek(1) == "O" {
                advance(); advance()  // consume 0o
                _ = consume(while: { $0 >= "0" && $0 <= "7" || $0 == "_" })
                tokens.append(.numberLiteral(String(source[start..<position]), start..<position))
                return true
            }
        }

        // Decimal integer or float
        _ = consume(while: { $0.isNumber || $0 == "_" })

        // Optional fractional part
        if peek() == ".", let next = peek(1), next.isNumber {
            advance()  // consume .
            _ = consume(while: { $0.isNumber || $0 == "_" })
        }

        // Optional exponent
        if peek() == "e" || peek() == "E" {
            advance()
            if peek() == "+" || peek() == "-" { advance() }
            _ = consume(while: { $0.isNumber || $0 == "_" })
        }

        tokens.append(.numberLiteral(String(source[start..<position]), start..<position))
        return true
    }

    // MARK: - Operators (gikh-ate)

    // Characters that can form operator sequences in Swift.
    private static let operatorChars: Set<Character> = [
        "/", "=", "-", "+", "!", "*", "%", "<", ">", "&", "|", "^", "~", "?",
        "\\",
    ]

    private mutating func scanOperator(_ tokens: inout [Token]) -> Bool {
        guard let c = peek(), Self.operatorChars.contains(c) else { return false }

        // Avoid scanning `//` or `/*` as operators — they are comments.
        if c == "/" && (peek(1) == "/" || peek(1) == "*") { return false }

        // Avoid scanning `\(` as a plain operator — it's an interpolation delimiter
        // but it gets handled by the string literal scanner, not here.
        // However, a bare `\` not followed by `(` is an operator.

        let start = position

        // For the backslash specifically: it's either part of `\(` (handled in
        // string scanner) or a bare operator (e.g. keypath prefix in Mode B).
        // Here we're outside strings, so just consume it as-is.
        if c == "\\" {
            advance()
            tokens.append(.operatorToken("\\", start..<position))
            return true
        }

        // Greedy: consume as many operator characters as possible.
        // But avoid consuming `*/` when scanning after a comment.
        _ = consume(while: { Self.operatorChars.contains($0) && $0 != "\\" })

        let text = String(source[start..<position])
        tokens.append(.operatorToken(text, start..<position))
        return true
    }

    // MARK: - Punctuation (gikh-oiy)

    private static let punctuationChars: Set<Character> = [
        "(", ")", "{", "}", "[", "]", ",", ":", ";", ".", "@", "#",
    ]

    private mutating func scanPunctuation(_ tokens: inout [Token]) -> Bool {
        guard let c = peek(), Self.punctuationChars.contains(c) else { return false }

        // `#` followed by `"` is a raw string — don't eat it as punctuation.
        if c == "#", peek(1) == "\"" { return false }
        // `#` followed by more `#` then `"` is also raw string.
        if c == "#" {
            var i = 1
            while peek(i) == "#" { i += 1 }
            if peek(i) == "\"" { return false }
        }

        let start = position
        advance()
        tokens.append(.punctuation(String(c), start..<position))
        return true
    }

    // MARK: - Words: keywords and identifiers (gikh-n2e)

    private mutating func scanWord(_ tokens: inout [Token]) -> Bool {
        guard let first = peek(), first.isSwiftIdentifierStart else { return false }

        let start = position
        advance()
        _ = consume(while: { $0.isSwiftIdentifierContinue })

        let word = String(source[start..<position])
        let range = start..<position

        if SwiftKeywords.all.contains(word) {
            tokens.append(.keyword(word, range))
        } else {
            tokens.append(.identifier(word, range))
        }
        return true
    }
}

// MARK: - Unicode helpers

public extension Character {
    /// True if this character can start a Swift identifier.
    /// Includes `$` (for anonymous closure params), `_`, ASCII letters, and
    /// any Unicode letter/combining mark/connector punctuation.
    var isSwiftIdentifierStart: Bool {
        if self == "_" || self == "$" { return true }
        if self.isLetter { return true }  // covers Hebrew/Yiddish Unicode
        return false
    }

    /// True if this character can continue a Swift identifier.
    var isSwiftIdentifierContinue: Bool {
        if isSwiftIdentifierStart { return true }
        if isNumber { return true }
        // Unicode combining marks, connector punctuation (e.g. U+05F3 GERESH)
        // We rely on Swift's isLetter covering most Hebrew combining chars.
        if self == "'" || self == "׳" || self == "׳" { return true }
        return false
    }

    var isHexDigit: Bool {
        isNumber || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}
