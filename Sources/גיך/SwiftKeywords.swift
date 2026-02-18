/// All Swift keywords and Yiddish keyword equivalents compiled into the binary.
enum SwiftKeywords {
    /// English Swift keywords (Mode A / Mode C).
    static let english: Set<String> = [
        // Declarations
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
        "func", "import", "init", "inout", "internal", "let", "open", "operator",
        "precedencegroup", "private", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var",
        // Statements
        "break", "case", "catch", "continue", "default", "defer", "do", "else",
        "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
        "switch", "where", "while",
        // Expressions/types
        "Any", "as", "await", "false", "is", "nil", "rethrows", "self", "Self",
        "super", "throw", "throws", "true", "try",
        // Contextual keywords (used as keywords only in certain positions)
        "associativity", "convenience", "didSet", "dynamic", "final", "get",
        "indirect", "lazy", "left", "mutating", "none", "nonmutating", "optional",
        "override", "postfix", "precedence", "prefix", "required", "right", "set",
        "some", "unowned", "weak", "willSet",
        // Async
        "async", "actor",
        // Attributes (without @)
        "available", "discardableResult", "dynamicCallable", "dynamicMemberLookup",
        "escaping", "frozen", "GKInspectable", "IBAction", "IBDesignable",
        "IBInspectable", "IBOutlet", "IBSegueAction", "inlinable", "main",
        "nonobjc", "NSApplicationMain", "NSCopying", "NSManaged", "objc",
        "objcMembers", "propertyWrapper", "requires_stored_property_inits",
        "resultBuilder", "Sendable", "testable", "UIApplicationMain", "unknown",
        "usableFromInline", "warn_unhandled_result",
    ]

    /// Yiddish keyword equivalents (Mode B).
    /// Maps Yiddish keyword → English keyword.
    static let yiddishToEnglish: [String: String] = [
        "פֿונקציע": "func",
        "לאָז": "let",
        "באַשטימען": "var",
        "צוריק": "return",
        "אויב": "if",
        "אַנדערש": "else",
        "פֿאַר": "for",
        "אין": "in",
        "בשעת": "while",
        "סטרוקטור": "struct",
        "קלאַס": "class",
        "פּראָטאָקאָל": "protocol",
        "היטער": "guard",
        "וועקסל": "switch",
        "פֿאַל": "case",
        "ברעכן": "break",
        "ממשיכן": "continue",
        "טאָן": "do",
        "כאַפּן": "catch",
        "וואַרפֿן": "throw",
        "וואַרפֿט": "throws",
        "אַסינכראָן": "async",
        "וואַרטן": "await",
        "סטאַטיש": "static",
        "פּריוואַט": "private",
        "עפֿנטלעך": "public",
        "אינערלעך": "internal",
        "פֿאַרלענגערונג": "extension",
        "אימפּאָרט": "import",
    ]

    /// The union of all keywords (English + Yiddish) — used by Scanner.
    static let all: Set<String> = {
        var s = english
        for k in yiddishToEnglish.keys { s.insert(k) }
        return s
    }()

    /// A BiMap from Yiddish keyword → English keyword.
    /// Used by Lexicon and Translator.
    static let keywordsMap: BiMap<String, String> = {
        BiMap(Array(yiddishToEnglish))
    }()
}
