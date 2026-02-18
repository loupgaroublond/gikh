/// Adds or removes Unicode BiDi control characters and flips slashes for
/// Mode B (RTL) output, and strips them for Mode A / Mode C (LTR) output.
///
/// Mode B rules:
///  - RTL tokens (Yiddish keywords, identifiers) → `RLI…PDI`
///  - LTR tokens (English keywords, identifiers, operators) → `LRI…PDI`
///  - String literals → `FSI…PDI`
///  - Interpolation delimiters (`\(` / `/(`) → slash flipped + `LRI…PDI`
///  - Opening brackets `(`, `{`, `[` → append `LRM` after
///  - Operators → slash-flipped content wrapped in `LRI…PDI`
///  - Whitespace, numbers, comments, unknown → verbatim
///
/// Mode A / Mode C rules:
///  - Strip all Unicode BiDi control characters
///  - Flip slashes back in operator tokens (if they were flipped for Mode B)
///  - All other tokens pass through verbatim
struct BidiAnnotator {
    // MARK: - BiDi control characters
    static let lri = "\u{2066}"   // Left-to-Right Isolate
    static let rli = "\u{2067}"   // Right-to-Left Isolate
    static let fsi = "\u{2068}"   // First Strong Isolate
    static let pdi = "\u{2069}"   // Pop Directional Isolate
    static let rlm = "\u{200F}"   // Right-to-Left Mark
    static let lrm = "\u{200E}"   // Left-to-Right Mark

    /// The set of all BiDi control character scalars to strip in LTR mode.
    private static let bidiScalars: Set<Unicode.Scalar> = [
        "\u{200E}", "\u{200F}",   // LRM, RLM
        "\u{2066}", "\u{2067}", "\u{2068}", "\u{2069}",  // LRI, RLI, FSI, PDI
        "\u{202A}", "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}",  // LRE, RLE, PDF, LRO, RLO
    ]

    // MARK: - Public entry point

    /// Annotate a token stream for the given target mode.
    func annotate(_ tokens: [Token], target: TargetMode) -> String {
        switch target {
        case .modeB:
            return emitModeB(tokens)
        case .modeA, .modeC:
            return emitLTR(tokens)
        }
    }

    // MARK: - Mode B: RTL emission

    private func emitModeB(_ tokens: [Token]) -> String {
        var output = ""

        for token in tokens {
            switch token {
            case .keyword(let word, _), .identifier(let word, _):
                if word.containsRTL {
                    output += "\(Self.rli)\(word)\(Self.pdi)"
                } else {
                    output += "\(Self.lri)\(word)\(Self.pdi)"
                }

            case .stringLiteral(let s, _):
                output += "\(Self.fsi)\(s)\(Self.pdi)"

            case .interpolationDelimiter(let delim, _):
                // Flip the slash: \( → /( or ) stays as )
                let flipped = flipSlashes(delim)
                output += "\(Self.lri)\(flipped)\(Self.pdi)"

            case .operatorToken(let op, _):
                let flipped = flipSlashes(op)
                output += "\(Self.lri)\(flipped)\(Self.pdi)"

            case .punctuation(let p, _):
                output += p
                if "({[".contains(p) {
                    output += Self.lrm
                }

            case .whitespace(let ws, _),
                 .comment(let ws, _),
                 .numberLiteral(let ws, _),
                 .unknown(let ws, _):
                output += ws
            }
        }

        return output
    }

    // MARK: - Mode A / Mode C: LTR emission

    private func emitLTR(_ tokens: [Token]) -> String {
        var output = ""

        for token in tokens {
            switch token {
            case .operatorToken(let op, _):
                // Flip backslashes back to forward slashes.
                // Mode B uses `\` for division (where Mode C/A uses `/`).
                // Forward slashes in LTR source are already correct and untouched.
                let flipped = flipBackslashToSlash(op)
                output += stripBidi(flipped)

            case .interpolationDelimiter(let delim, _):
                // Mode B uses `/( ` for interpolation (where Mode C/A uses `\(`).
                // Forward-slash-open-paren → backslash-open-paren for LTR.
                let fixed = fixInterpolationDelimiterLTR(delim)
                output += stripBidi(fixed)

            default:
                // Strip BiDi markers from all other tokens
                output += stripBidi(token.text)
            }
        }

        return output
    }

    /// Convert a Mode B interpolation delimiter to LTR form:
    /// `/(` → `\(`, `)` → `)`.
    private func fixInterpolationDelimiterLTR(_ delim: String) -> String {
        if delim == "/(" {
            return "\\("
        }
        return delim
    }

    // MARK: - Helpers

    /// Swap `/` ↔ `\` in the given string.
    /// Used for Mode B emission: converts LTR slashes to their RTL equivalents.
    private func flipSlashes(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)
        for char in text {
            switch char {
            case "/":  result.append("\\")
            case "\\": result.append("/")
            default:   result.append(char)
            }
        }
        return result
    }

    /// Flip `\` → `/` only (Mode B → Mode A/C direction).
    /// A backslash in a code token came from Mode B (where `/` was flipped to `\`).
    /// Forward slashes in LTR tokens are already correct and must not be touched.
    private func flipBackslashToSlash(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)
        for char in text {
            if char == "\\" {
                result.append("/")
            } else {
                result.append(char)
            }
        }
        return result
    }

    /// Remove all Unicode BiDi control characters from `text`.
    private func stripBidi(_ text: String) -> String {
        let filtered = text.unicodeScalars.filter { !Self.bidiScalars.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
}

// MARK: - Unicode helpers

extension String {
    /// Returns true if the string contains at least one RTL (right-to-left) character.
    /// This is used to decide whether to wrap in RLI or LRI in Mode B output.
    var containsRTL: Bool {
        unicodeScalars.contains { scalar in
            // Hebrew block: U+0590–U+05FF
            // Yiddish uses Hebrew Unicode block
            (0x0590...0x05FF).contains(scalar.value)
            // Arabic: U+0600–U+06FF (less likely but included for completeness)
            || (0x0600...0x06FF).contains(scalar.value)
            // Additional Hebrew extended: U+FB1D–U+FB4F
            || (0xFB1D...0xFB4F).contains(scalar.value)
        }
    }
}
