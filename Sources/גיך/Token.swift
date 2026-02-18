/// A lexical token produced by the Scanner.
///
/// Each case carries the raw source text and the range it occupies in the
/// original string so the token stream can be reconstructed losslessly.
enum Token {
    /// A Swift keyword or Yiddish keyword equivalent (translatable).
    case keyword(String, Range<String.Index>)

    /// An identifier — either English or Yiddish (translatable when in the
    /// active dictionary).
    case identifier(String, Range<String.Index>)

    /// A string literal, including its delimiters.  Content is opaque —
    /// never modified during transpilation.
    case stringLiteral(String, Range<String.Index>)

    /// A `//` line comment or `/* */` block comment.  Content is opaque.
    case comment(String, Range<String.Index>)

    /// Horizontal/vertical whitespace including newlines.  Preserved verbatim.
    case whitespace(String, Range<String.Index>)

    /// A single punctuation character (parenthesis, brace, bracket, comma,
    /// colon, semicolon, period, …).  Preserved verbatim.
    case punctuation(String, Range<String.Index>)

    /// An operator sequence.  In Mode B the `/` and `\` characters within
    /// operators are flipped; all other content is preserved verbatim.
    case operatorToken(String, Range<String.Index>)

    /// An integer or floating-point literal.  Preserved verbatim.
    case numberLiteral(String, Range<String.Index>)

    /// The opening `\(` (Mode C) / `/(` (Mode B) interpolation delimiter, or
    /// the matching closing `)`.  The backslash/forward-slash is flipped during
    /// mode conversion like any other slash in code, but the delimiter is kept
    /// as a distinct token so the scanner can correctly track interpolation
    /// nesting depth without treating the interior as opaque string content.
    case interpolationDelimiter(String, Range<String.Index>)

    /// Any character that didn't match another rule.  Preserved verbatim.
    case unknown(String, Range<String.Index>)

    /// The raw source text of the token.
    var text: String {
        switch self {
        case .keyword(let s, _),
             .identifier(let s, _),
             .stringLiteral(let s, _),
             .comment(let s, _),
             .whitespace(let s, _),
             .punctuation(let s, _),
             .operatorToken(let s, _),
             .numberLiteral(let s, _),
             .interpolationDelimiter(let s, _),
             .unknown(let s, _):
            return s
        }
    }

    /// The source range of the token.
    var range: Range<String.Index> {
        switch self {
        case .keyword(_, let r),
             .identifier(_, let r),
             .stringLiteral(_, let r),
             .comment(_, let r),
             .whitespace(_, let r),
             .punctuation(_, let r),
             .operatorToken(_, let r),
             .numberLiteral(_, let r),
             .interpolationDelimiter(_, let r),
             .unknown(_, let r):
            return r
        }
    }
}

// MARK: - Equatable

extension Token: Equatable {
    static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.text == rhs.text && lhs.range == rhs.range
    }
}

// MARK: - CustomDebugStringConvertible

extension Token: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .keyword(let s, _):            return ".keyword(\(s.debugDescription))"
        case .identifier(let s, _):         return ".identifier(\(s.debugDescription))"
        case .stringLiteral(let s, _):      return ".stringLiteral(\(s.debugDescription))"
        case .comment(let s, _):            return ".comment(\(s.debugDescription))"
        case .whitespace(let s, _):         return ".whitespace(\(s.debugDescription))"
        case .punctuation(let s, _):        return ".punctuation(\(s.debugDescription))"
        case .operatorToken(let s, _):      return ".operatorToken(\(s.debugDescription))"
        case .numberLiteral(let s, _):      return ".numberLiteral(\(s.debugDescription))"
        case .interpolationDelimiter(let s, _): return ".interpolationDelimiter(\(s.debugDescription))"
        case .unknown(let s, _):            return ".unknown(\(s.debugDescription))"
        }
    }
}

// MARK: - Direction

/// Which direction the transpiler is converting.
enum Direction {
    /// Yiddish (Mode B) → English (Mode A or Mode C).
    case toEnglish
    /// English (Mode A or Mode C) → Yiddish (Mode B).
    case toYiddish
}

// MARK: - TargetMode

/// The target representation after transpilation.
enum TargetMode {
    /// Mode A — full English: English keywords, English identifiers, no BiDi.
    case modeA
    /// Mode B — full Yiddish (.gikh): Yiddish keywords, Yiddish identifiers,
    ///   RTL BiDi markers, slashes flipped.
    case modeB
    /// Mode C — hybrid (compilation): English keywords, Yiddish identifiers,
    ///   no BiDi, slashes in LTR orientation.
    case modeC
}

// MARK: - TranslationMode

/// Which dictionaries are active during translation.
enum TranslationMode {
    /// Keywords only (B ↔ C compiler workflow).
    case keywordsOnly
    /// All dictionaries (A ↔ B developer workflow).
    case full
}
