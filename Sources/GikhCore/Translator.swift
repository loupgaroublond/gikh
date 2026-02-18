/// Converts a token stream from one mode to another by swapping keywords
/// and (in `.full` mode) identifiers using the active `Lexicon`.
///
/// The Translator is stateless with respect to the source — it operates on
/// an already-scanned `[Token]` array and returns a new array with text
/// values replaced where appropriate.  All opaque tokens (string literals,
/// comments, whitespace, numbers, operators, punctuation) pass through
/// unchanged.
public struct Translator {
    public let lexicon: Lexicon
    public let direction: Direction
    public let mode: TranslationMode

    public init(lexicon: Lexicon, direction: Direction, mode: TranslationMode) {
        self.lexicon = lexicon
        self.direction = direction
        self.mode = mode
    }

    // MARK: - Public entry point

    /// Translate a token stream, returning a new token stream.
    ///
    /// Only `.keyword` and `.identifier` tokens are candidates for
    /// replacement. All other token kinds pass through with their original
    /// text intact.
    public func translate(_ tokens: [Token]) -> [Token] {
        tokens.map { token in
            switch token {
            case .keyword(let word, let range):
                let translated = translateKeyword(word)
                return .keyword(translated, range)

            case .identifier(let word, let range):
                guard mode == .full else { return token }
                let translated = translateIdentifier(word)
                return .identifier(translated, range)

            default:
                return token
            }
        }
    }

    // MARK: - Keyword translation

    /// Translate a single keyword according to `direction`.
    ///
    /// The `lexicon.keywords` BiMap stores Yiddish → English pairs.
    /// - `toEnglish`: look up the Yiddish word → get English (toValue)
    /// - `toYiddish`: look up the English word → get Yiddish (toKey)
    ///
    /// If the word is not found in the map it is returned unchanged.
    private func translateKeyword(_ word: String) -> String {
        switch direction {
        case .toEnglish:
            // Yiddish keyword → English: BiMap Yiddish→English, so use toValue
            return lexicon.keywords.toValue(word) ?? word
        case .toYiddish:
            // English keyword → Yiddish: look up English as a value → get Yiddish key
            return lexicon.keywords.toKey(word) ?? word
        }
    }

    // MARK: - Identifier translation

    /// Translate a single identifier.
    ///
    /// Lookup priority: `bibliotek` → `identifiers`.
    /// (Keywords are not searched here — they are already handled above.)
    /// Any identifier not found in any tier is returned unchanged (passthrough).
    private func translateIdentifier(_ word: String) -> String {
        let maps = [lexicon.bibliotek, lexicon.identifiers]

        for map in maps {
            switch direction {
            case .toEnglish:
                // Yiddish identifier → English: BiMap stores Yiddish→English
                if let v = map.toValue(word) { return v }
            case .toYiddish:
                // English identifier → Yiddish: look up English as value → get Yiddish
                if let k = map.toKey(word) { return k }
            }
        }

        return word
    }
}
