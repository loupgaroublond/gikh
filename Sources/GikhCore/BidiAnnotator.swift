// BidiAnnotator.swift
// GikhCore — BiDi control character annotation for transpiled output.

import Foundation

/// Inserts Unicode BiDi control characters around tokens so that mixed
/// Hebrew/Latin text renders correctly in both RTL and LTR contexts.
///
/// Mode B output is right-to-left dominant: Yiddish tokens get RLI isolates,
/// embedded English (operators, LTR identifiers) gets LRI isolates.
/// Modes A and C are left-to-right: all BiDi markers are stripped.
public struct BidiAnnotator {

    // MARK: - Unicode BiDi Control Characters

    /// Left-to-Right Isolate — starts an LTR-embedded span.
    public static let lri = "\u{2066}"
    /// Right-to-Left Isolate — starts an RTL-embedded span.
    public static let rli = "\u{2067}"
    /// First Strong Isolate — direction determined by first strong character.
    public static let fsi = "\u{2068}"
    /// Pop Directional Isolate — closes LRI, RLI, or FSI.
    public static let pdi = "\u{2069}"
    /// Right-to-Left Mark — invisible RTL anchor.
    public static let rlm = "\u{200F}"
    /// Left-to-Right Mark — invisible LTR anchor.
    public static let lrm = "\u{200E}"

    /// The full set of BiDi control characters to strip in LTR output,
    /// including both isolate-based (Unicode 6.3) and legacy embedding-based markers.
    private static let bidiControls: Set<Character> = [
        "\u{2066}", // LRI
        "\u{2067}", // RLI
        "\u{2068}", // FSI
        "\u{2069}", // PDI
        "\u{200E}", // LRM
        "\u{200F}", // RLM
        "\u{202A}", // LRE  (legacy)
        "\u{202B}", // RLE  (legacy)
        "\u{202C}", // PDF  (legacy)
        "\u{202D}", // LRO  (legacy)
        "\u{202E}", // RLO  (legacy)
    ]

    public init() {}

    // MARK: - Public API

    /// Annotate the token stream with BiDi control characters appropriate
    /// for the given target mode.
    public func annotate(_ tokens: [Token], target: TargetMode) -> String {
        switch target {
        case .modeB:
            return emitModeB(tokens)
        case .modeA, .modeC:
            return emitLTR(tokens)
        }
    }

    // MARK: - Mode B (RTL Yiddish Output)

    /// Produces RTL-dominant output for Mode B. Yiddish text is wrapped in
    /// RTL isolates, embedded LTR content (English identifiers, operators)
    /// in LTR isolates, and strings in first-strong isolates.
    private func emitModeB(_ tokens: [Token]) -> String {
        var result = ""
        result.reserveCapacity(tokens.count * 8)

        for token in tokens {
            let text = token.text

            switch token {
            case .keyword, .identifier:
                if text.containsRTL {
                    result += Self.rli + text + Self.pdi
                } else {
                    result += Self.lri + text + Self.pdi
                }

            case .stringLiteral:
                result += Self.fsi + text + Self.pdi

            case .punctuation:
                result += text
                // Anchor direction after opening delimiters so nested
                // content starts in the correct LTR context.
                if let last = text.last, "([{".contains(last) {
                    result += Self.lrm
                }

            case .operatorToken:
                result += Self.lri + flipSlashes(text) + Self.pdi

            case .whitespace, .comment, .numberLiteral, .unknown:
                result += text
            }
        }

        return result
    }

    // MARK: - LTR Output (Mode A / Mode C)

    /// Produces LTR output for Modes A and C. All BiDi control characters
    /// are stripped and operator slashes are flipped back from any Mode B
    /// encoding.
    private func emitLTR(_ tokens: [Token]) -> String {
        var result = ""
        result.reserveCapacity(tokens.count * 4)

        for token in tokens {
            switch token {
            case .operatorToken:
                result += flipSlashes(token.text)
            default:
                result += token.text
            }
        }

        return String(result.filter { !Self.bidiControls.contains($0) })
    }

    // MARK: - Helpers

    /// Swap forward slashes and backslashes. All other characters pass through.
    private func flipSlashes(_ text: String) -> String {
        var output = ""
        output.reserveCapacity(text.count)
        for ch in text {
            switch ch {
            case "/":  output.append("\\")
            case "\\": output.append("/")
            default:   output.append(ch)
            }
        }
        return output
    }
}

// MARK: - String RTL Detection

extension String {

    /// `true` if the string contains at least one character in the Hebrew
    /// Unicode block (U+0590..U+05FF) or Hebrew Presentation Forms
    /// (U+FB1D..U+FB4F).
    var containsRTL: Bool {
        self.unicodeScalars.contains { scalar in
            (0x0590...0x05FF).contains(scalar.value) ||
            (0xFB1D...0xFB4F).contains(scalar.value)
        }
    }
}
