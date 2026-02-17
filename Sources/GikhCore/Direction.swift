// Direction.swift
// GikhCore — Transpilation direction, target mode, and translation scope.

/// The direction of transpilation.
public enum Direction {
    /// Translate Yiddish identifiers and keywords to English.
    case toEnglish
    /// Translate English identifiers and keywords to Yiddish.
    case toYiddish
}

/// The output mode, corresponding to the three representations of a Gikh program.
public enum TargetMode {
    /// Mode A — fully English `.swift` source. All identifiers and keywords in English.
    case modeA
    /// Mode B — fully Yiddish `.gikh` source. The canonical source of truth.
    case modeB
    /// Mode C — hybrid for compilation. Keywords translated, SDK symbols wrapped via ביבליאָטעק.
    case modeC
}

/// The scope of translation to apply during transpilation.
public enum TranslationMode {
    /// Keywords only — used for B <-> C conversion (the compiler workflow).
    case keywordsOnly
    /// Full translation — all dictionary tiers. Used for A <-> B and A <-> C (the developer workflow).
    case full
}
