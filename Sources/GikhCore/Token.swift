// Token.swift
// GikhCore — Core token type for the Gikh scanner.

/// A lexical token produced by the scanner.
///
/// Each case carries the matched text and its range within the source string.
/// Equatable conformance compares only the case discriminant and text,
/// ignoring the range — two tokens with the same kind and text are equal
/// regardless of where they appeared in the source.
public enum Token: Equatable {
    case keyword(String, Range<String.Index>)
    case identifier(String, Range<String.Index>)
    case stringLiteral(String, Range<String.Index>)
    case comment(String, Range<String.Index>)
    case whitespace(String, Range<String.Index>)
    case punctuation(String, Range<String.Index>)
    case operatorToken(String, Range<String.Index>)
    case numberLiteral(String, Range<String.Index>)
    case unknown(String, Range<String.Index>)

    /// The matched text for this token.
    public var text: String {
        switch self {
        case .keyword(let t, _),
             .identifier(let t, _),
             .stringLiteral(let t, _),
             .comment(let t, _),
             .whitespace(let t, _),
             .punctuation(let t, _),
             .operatorToken(let t, _),
             .numberLiteral(let t, _),
             .unknown(let t, _):
            return t
        }
    }

    /// The range of this token within the original source string.
    public var range: Range<String.Index> {
        switch self {
        case .keyword(_, let r),
             .identifier(_, let r),
             .stringLiteral(_, let r),
             .comment(_, let r),
             .whitespace(_, let r),
             .punctuation(_, let r),
             .operatorToken(_, let r),
             .numberLiteral(_, let r),
             .unknown(_, let r):
            return r
        }
    }

    // MARK: - Equatable

    /// Two tokens are equal when they share the same case and text.
    /// Range is intentionally excluded — position is metadata, not identity.
    public static func == (lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.keyword(let a, _), .keyword(let b, _)),
             (.identifier(let a, _), .identifier(let b, _)),
             (.stringLiteral(let a, _), .stringLiteral(let b, _)),
             (.comment(let a, _), .comment(let b, _)),
             (.whitespace(let a, _), .whitespace(let b, _)),
             (.punctuation(let a, _), .punctuation(let b, _)),
             (.operatorToken(let a, _), .operatorToken(let b, _)),
             (.numberLiteral(let a, _), .numberLiteral(let b, _)),
             (.unknown(let a, _), .unknown(let b, _)):
            return a == b
        default:
            return false
        }
    }
}
