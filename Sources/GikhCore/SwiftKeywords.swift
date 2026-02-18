/// All Swift keywords and Yiddish keyword equivalents compiled into the binary.
public enum SwiftKeywords {
    /// English Swift keywords (Mode A / Mode C).
    public static let english: Set<String> = [
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
        "indirect", "infix", "lazy", "left", "mutating", "none", "nonmutating", "optional",
        "override", "postfix", "precedence", "prefix", "required", "right", "set",
        "some", "any", "unowned", "weak", "willSet",
        // Async/concurrency
        "async", "actor", "nonisolated", "isolated", "consuming", "borrowing", "sending",
        // Macros
        "macro",
        // Attributes (without @)
        "available", "discardableResult", "dynamicCallable", "dynamicMemberLookup",
        "escaping", "frozen", "GKInspectable", "IBAction", "IBDesignable",
        "IBInspectable", "IBOutlet", "IBSegueAction", "inlinable", "main",
        "nonobjc", "NSApplicationMain", "NSCopying", "NSManaged", "objc",
        "objcMembers", "propertyWrapper", "requires_stored_property_inits",
        "resultBuilder", "Sendable", "testable", "UIApplicationMain", "unknown",
        "usableFromInline", "warn_unhandled_result", "MainActor",
        // Types
        "Type",
    ]

    /// Yiddish keyword equivalents (Mode B).
    /// Maps Yiddish keyword → English keyword.
    public static let yiddishToEnglish: [String: String] = [
        // Declarations
        "פֿונקציע": "func",
        "לאָז": "let",
        "באַשטימען": "var",
        "סטרוקטור": "struct",
        "קלאַס": "class",
        "פּראָטאָקאָל": "protocol",
        "ענום": "enum",
        "פֿאַרלענגערונג": "extension",
        "אימפּאָרט": "import",
        "פּראָטאָקאָל_טיפּ": "associatedtype",
        "אָנהייב": "init",
        "אָפּרוים": "deinit",
        "אינאױס": "inout",
        "אָפּעראַטאָר": "operator",
        "פֿאָרגאַנג_גרופּע": "precedencegroup",
        "אונטערשריפֿט": "subscript",
        "טיפּ_נאָמען": "typealias",
        "עפֿנטלעך": "public",
        "פּריוואַט": "private",
        "אינערלעך": "internal",
        "פֿאַרשלאָסן_פּריוואַט": "fileprivate",
        "עפֿן": "open",
        "סטאַטיש": "static",
        "ווידערוואַרפֿן": "rethrows",
        // Statements
        "צוריק": "return",
        "אויב": "if",
        "אַנדערש": "else",
        "פֿאַר": "for",
        "אין": "in",
        "בשעת": "while",
        "וועקסל": "switch",
        "פֿאַל": "case",
        "ברעכן": "break",
        "ממשיכן": "continue",
        "פֿאָלגן": "fallthrough",
        "פֿאַרזיכערן": "guard",
        "אָפּשטעלן": "defer",
        "טאָן": "do",
        "כאַפּן": "catch",
        "וואַרפֿן": "throw",
        "פּרובירן": "try",
        "ווו": "where",
        "חזרן": "repeat",
        "פֿאָרשטיין": "default",
        // Expressions and Types
        "וואָס_נאָר": "Any",
        "ווי": "as",
        "פֿאַלש": "false",
        "איז": "is",
        "גאָרנישט": "nil",
        "זיך": "self",
        "זיך_טיפּ": "Self",
        "עלטערן": "super",
        "וואַרפֿט": "throws",
        "אמת": "true",
        "אַסינכראָן": "async",
        "וואַרטן": "await",
        // Contextual Keywords
        "פֿאַראיינציקייט": "associativity",
        "באַקוועם": "convenience",
        "דינאַמיש": "dynamic",
        "נאָך_שטעלן": "didSet",
        "סופֿיק": "final",
        "נעמען": "get",
        "אינפֿיקס": "infix",
        "אומגעריכט": "indirect",
        "פּויזנדיק": "lazy",
        "לינקס": "left",
        "ענדערן": "mutating",
        "קיינעם": "none",
        "ניט_ענדערן": "nonmutating",
        "אָפּציאָנעל": "optional",
        "איבערשרײַבן": "override",
        "נאָכשטיין": "postfix",
        "פֿאָרגאַנג": "precedence",
        "פֿאָרשטיין_וואָרט": "prefix",
        "פֿאַרלאַנגט": "required",
        "רעכטס": "right",
        "שטעלן": "set",
        "עטלעכע": "some",
        "עפּעס": "any",
        "טיפּ": "Type",
        "אומבאַזעסן": "unowned",
        "שוואַך": "weak",
        "פֿאַר_שטעלן": "willSet",
        "אַקטיאָר": "actor",
        "ניט_איזאָלירט": "nonisolated",
        "איזאָלירט": "isolated",
        "פֿאַרנוצן": "consuming",
        "אויסלייען": "borrowing",
        "שיקן": "sending",
        "מאַקראָ": "macro",
        // Attributes (without @)
        "דערלויבט": "available",
        "אָפּוואַרפֿבאַר": "discardableResult",
        "דינאַמיש_אָנרוף": "dynamicCallable",
        "דינאַמיש_מיטגליד": "dynamicMemberLookup",
        "אַנטלויפֿנדיק": "escaping",
        "פֿאַרפֿרוירן": "frozen",
        "אַרײַנשרײַבן": "inlinable",
        "הויפּט": "main",
        "ניט_אָביעקט": "nonobjc",
        "אָביעקט": "objc",
        "אָביעקט_מיטגלידער": "objcMembers",
        "פּראָפּערטי_אײַנוויקלער": "propertyWrapper",
        "רעזולטאַט_בויער": "resultBuilder",
        "שיקבאַר": "Sendable",
        "פּרובירבאַר": "testable",
        "באַניצבאַר_פֿון_אינעם": "usableFromInline",
        "הויפּט_אַקטיאָר": "MainActor",
    ]

    /// The union of all keywords (English + Yiddish) — used by Scanner.
    public static let all: Set<String> = {
        var s = english
        for k in yiddishToEnglish.keys { s.insert(k) }
        return s
    }()

    /// A BiMap from Yiddish keyword → English keyword.
    /// Used by Lexicon and Translator.
    public static let keywordsMap: BiMap<String, String> = {
        BiMap(Array(yiddishToEnglish))
    }()
}
