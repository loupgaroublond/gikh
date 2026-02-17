// Keywords.swift
// GikhCore — The compiled-in keyword dictionary mapping Yiddish ↔ English Swift keywords.

/// The complete bijective mapping between Yiddish and English Swift keywords.
///
/// This dictionary is compiled directly into the transpiler binary. It is a closed,
/// finite set that only changes when Swift adds new keywords.
///
/// The Yiddish keyword is the key; the English Swift keyword is the value.
public struct Keywords {

    /// Yiddish ↔ English keyword mappings, compiled into the binary.
    public static let dictionary = BiMap<String, String>([
        // MARK: - Control Flow

        ("פֿונקציע",       "func"),
        ("לאָז",           "let"),
        ("באַשטימען",       "var"),
        ("צוריק",          "return"),
        ("אויב",           "if"),
        ("אַנדערש",         "else"),
        ("פֿאַר",           "for"),
        ("אין",            "in"),
        ("בשעת",           "while"),
        ("היטער",          "guard"),
        ("וועקסל",          "switch"),
        ("פֿאַל",           "case"),
        ("ברעכן",          "break"),
        ("ממשיכן",         "continue"),
        ("טאָן",           "do"),
        ("כאַפּן",          "catch"),
        ("וואַרפֿן",        "throw"),
        ("וואַרפֿט",        "throws"),
        ("פּרובירן",        "try"),
        ("ווידער",          "repeat"),
        ("אָפּלייגן",       "defer"),
        ("פֿעליק",         "default"),
        ("אַראָפּפֿאַלן",    "fallthrough"),
        ("וואו",           "where"),

        // MARK: - Types

        ("סטרוקטור",       "struct"),
        ("קלאַס",          "class"),
        ("ענום",           "enum"),
        ("פּראָטאָקאָל",     "protocol"),
        ("פֿאַרלענגערונג",   "extension"),
        ("טיפּ_כּינוי",     "typealias"),
        ("אויפֿרוף",       "subscript"),
        ("באַזונדער",       "deinit"),
        ("אָנהייב",        "init"),
        ("פּראָטאָקאָל_טיפּ", "associatedtype"),

        // MARK: - Access Control

        ("פּריוואַט",       "private"),
        ("עפֿנטלעך",       "public"),
        ("אינערלעך",       "internal"),
        ("אָפּן",          "open"),
        ("טייל_פּריוואַט",   "fileprivate"),

        // MARK: - Modifiers

        ("סטאַטיש",        "static"),
        ("אַסינכראָן",      "async"),
        ("וואַרטן",         "await"),
        ("עטלעכע",         "some"),
        ("אימפּאָרט",       "import"),
        ("אָפּעראַטאָר",     "operator"),

        // MARK: - Boolean / Nil

        ("אמת",           "true"),
        ("פֿאַלש",         "false"),
        ("גאָרנישט",       "nil"),

        // MARK: - Self / Super

        ("זיך",           "self"),
        ("זיך_טיפּ",       "Self"),
        ("העכער",          "super"),

        // MARK: - Other Keywords

        ("אַלץ",           "as"),
        ("יעדער",          "Any"),
        ("אַרײַן_אַרויס",   "inout"),
        ("ניט_קאָפּירבאַר",  "noncopyable"),
        ("ווידער_וואַרפֿן",  "rethrows"),
        ("פּרעצעדענץ_גרופּע", "precedencegroup"),
        ("מאַקראָ",         "macro"),
    ])

    // MARK: - Token Classification Sets

    /// All English Swift keywords present in the dictionary.
    /// Used by the Scanner to classify tokens when transpiling Yiddish → English.
    public static let swiftKeywords: Set<String> = Set(dictionary.values)

    /// All Yiddish keywords present in the dictionary.
    /// Used by the Scanner to classify tokens when transpiling English → Yiddish.
    public static let yiddishKeywords: Set<String> = Set(dictionary.keys)
}
