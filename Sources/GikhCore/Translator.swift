/// Token translator for the Gikh transpiler.
///
/// Translates keywords and identifiers between English and Yiddish
/// using dictionary lookups from a `Lexicon`. Tokens that don't match
/// any dictionary entry pass through unchanged.
public struct Translator {
    public let lexicon: Lexicon
    public let direction: Direction
    public let mode: TranslationMode

    public init(lexicon: Lexicon, direction: Direction, mode: TranslationMode) {
        self.lexicon = lexicon
        self.direction = direction
        self.mode = mode
    }

    /// Translates an array of tokens according to the configured direction and mode.
    ///
    /// - Keywords are always translated (both `.keywordsOnly` and `.full` modes).
    /// - Identifiers are only translated in `.full` mode.
    /// - All other token types (string literals, comments, whitespace,
    ///   punctuation, operators, number literals) pass through untouched.
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

    // MARK: - Private

    /// Translates a single keyword between English and Yiddish.
    ///
    /// In the keywords `BiMap`, Yiddish is the key and English is the value.
    /// - `.toEnglish`: Yiddish → English via `toValue`
    /// - `.toYiddish`: English → Yiddish via `toKey`
    ///
    /// Returns the word unchanged if no mapping exists.
    private func translateKeyword(_ word: String) -> String {
        switch direction {
        case .toEnglish:
            return lexicon.keywords.toValue(word) ?? word
        case .toYiddish:
            return lexicon.keywords.toKey(word) ?? word
        }
    }

    /// Translates a single identifier between English and Yiddish.
    ///
    /// Checks the ביבליאָטעק dictionary first, then the project identifiers
    /// dictionary. This priority order ensures framework symbols take
    /// precedence over project-local names.
    ///
    /// Returns the word unchanged if no mapping exists in either dictionary.
    private func translateIdentifier(_ word: String) -> String {
        switch direction {
        case .toEnglish:
            if let found = lexicon.bibliotek.toValue(word) { return found }
            if let found = lexicon.identifiers.toValue(word) { return found }
            return word

        case .toYiddish:
            if let found = lexicon.bibliotek.toKey(word) { return found }
            if let found = lexicon.identifiers.toKey(word) { return found }
            return word
        }
    }
}
