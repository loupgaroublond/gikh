/// The core transpilation pipeline: scan → translate → BiDi annotate.
/// This is the shared logic used by the CLI, build plugin, and tests.
public enum Transpiler {

    /// Transpile a source string to the given target mode.
    ///
    /// - Parameters:
    ///   - source: The input source string (any mode).
    ///   - lexicon: The active dictionary set.
    ///   - target: The desired output mode.
    /// - Returns: The transpiled source string.
    public static func transpile(
        _ source: String,
        lexicon: Lexicon,
        target: TargetMode
    ) -> String {
        var scanner = Scanner(source: source)
        let tokens = scanner.scan()
        let annotator = BidiAnnotator()

        switch target {
        case .modeB:
            // Target Mode B: swap English → Yiddish (full mode), then annotate RTL
            let translator = Translator(
                lexicon: lexicon,
                direction: .toYiddish,
                mode: .full
            )
            let translated = translator.translate(tokens)
            return annotator.annotate(translated, target: .modeB)

        case .modeA:
            // Target Mode A: swap Yiddish → English (full mode), strip BiDi
            let translator = Translator(
                lexicon: lexicon,
                direction: .toEnglish,
                mode: .full
            )
            let translated = translator.translate(tokens)
            return annotator.annotate(translated, target: .modeA)

        case .modeC:
            // Target Mode C: swap Yiddish → English (keywords + bibliotek identifiers)
            // Bibliotek identifiers must be translated so that protocol method names,
            // parameter labels, and other framework-required names resolve correctly.
            // Type aliases and wrapper names also translate back to their English
            // originals, which is safe because the English APIs exist via @_exported import.
            let translator = Translator(
                lexicon: lexicon,
                direction: .toEnglish,
                mode: .compilation
            )
            let translated = translator.translate(tokens)
            return annotator.annotate(translated, target: .modeC)
        }
    }
}
