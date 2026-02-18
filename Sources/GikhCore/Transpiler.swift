// Transpiler.swift
// GikhCore — High-level transpilation logic coordinating Scanner, Translator, and BidiAnnotator.

/// Orchestrates the transpilation pipeline: scan → translate → annotate → emit.
///
/// Used by both the CLI and the build plugin to convert between Mode A (English .swift),
/// Mode B (Yiddish .gikh), and Mode C (hybrid for compilation).
public enum Transpiler {

    /// Transpile source from one mode to another.
    ///
    /// The pipeline runs four stages:
    /// 1. **Scan** — tokenize the source into keywords, identifiers, literals, etc.
    /// 2. **Determine translation** — pick the `Direction` and `TranslationMode` for this conversion.
    /// 3. **Translate** — map keywords and (optionally) identifiers via the `Lexicon`.
    /// 4. **Annotate** — insert or strip BiDi control characters for the target mode.
    ///
    /// - Parameters:
    ///   - source: The raw source text to transpile.
    ///   - sourceMode: The mode the input is currently in.
    ///   - targetMode: The mode to produce.
    ///   - lexicon: The merged dictionary stack for translation lookups.
    /// - Returns: The transpiled source text.
    public static func transpile(
        source: String,
        from sourceMode: TargetMode,
        to targetMode: TargetMode,
        lexicon: Lexicon
    ) -> String {
        // 1. Scan source into tokens
        var scanner = Scanner(source: source)
        let tokens = scanner.scan()

        // 2. Determine direction and translation scope
        let (direction, translationMode) = determineTranslation(from: sourceMode, to: targetMode)

        // 3. Translate tokens
        let translator = Translator(lexicon: lexicon, direction: direction, mode: translationMode)
        let translated = translator.translate(tokens)

        // 4. Annotate with BiDi controls and emit
        let annotator = BidiAnnotator()
        return annotator.annotate(translated, target: targetMode)
    }

    /// Determine the translation direction and scope for a given source → target conversion.
    ///
    /// The mapping follows the design doc's two-workflow model:
    /// - **Compiler workflow** (B↔C): keywords only, identifiers pass through.
    /// - **Developer workflow** (A↔B, A↔C): full translation across all dictionary tiers.
    public static func determineTranslation(
        from source: TargetMode, to target: TargetMode
    ) -> (Direction, TranslationMode) {
        switch (source, target) {
        case (.modeB, .modeC):
            // Compiler workflow: Yiddish → hybrid. Translate keywords + bibliotek.
            // Uses .full mode because Lexicon.forCompilation() has empty identifiers,
            // so only keywords and bibliotek symbols are translated — user identifiers
            // pass through unchanged, which is exactly what Mode C requires.
            return (.toEnglish, .full)
        case (.modeC, .modeB):
            // Reverse compiler workflow: hybrid → Yiddish. Keywords + bibliotek.
            return (.toYiddish, .full)
        case (.modeB, .modeA):
            // Developer workflow: Yiddish → English. Full translation.
            return (.toEnglish, .full)
        case (.modeA, .modeB):
            // Developer workflow: English → Yiddish. Full translation.
            return (.toYiddish, .full)
        case (.modeC, .modeA):
            // Hybrid → English. Translate remaining identifiers.
            return (.toEnglish, .full)
        case (.modeA, .modeC):
            // English → hybrid. Translate identifiers to Yiddish, keep keywords English.
            // This is effectively A→B then B→C, but we use full here since
            // identifiers need translation while keywords stay English.
            return (.toYiddish, .full)
        default:
            // Same mode — no-op pass-through (direction is arbitrary, nothing matches).
            return (.toEnglish, .keywordsOnly)
        }
    }

    /// Detect the mode of a file by its extension.
    ///
    /// - `.gikh` → Mode B (Yiddish source of truth)
    /// - `.swift` → Mode C (hybrid for compilation) by default;
    ///   the caller may override after inspecting content.
    public static func detectMode(path: String) -> TargetMode {
        if path.hasSuffix(".gikh") {
            return .modeB
        } else {
            return .modeC
        }
    }
}
