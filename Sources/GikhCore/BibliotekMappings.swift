// BibliotekMappings.swift
// GikhCore — Compiled-in dictionary of ביבליאָטעק (framework wrapper) mappings.
//
// These mappings are derived from the Bibliotek source files. The Yiddish name
// is the key; the English Swift/framework name is the value.
//
// Only 1:1 token-level mappings are included here. Custom convenience wrappers
// (e.g. ברייט → frame(width:)) that expand to multi-token expressions are omitted
// since the transpiler works at the single-token level.

public struct BibliotekMappings {

    /// Yiddish ↔ English framework symbol mappings, compiled into the binary.
    public static let dictionary = BiMap<String, String>([

        // MARK: - Module Names

        ("יסוד",                  "Foundation"),
        ("סוויפֿטיוּאַי",          "SwiftUI"),
        ("טשאַרטס",               "Charts"),
        ("סוויפֿטדאַטאַ",          "SwiftData"),

        // MARK: - Stdlib Types (from NumericWrappers, StringWrappers, CollectionWrappers)

        ("סטרינג",               "String"),
        ("צאָל",                  "Int"),
        ("טאָפּל",                "Double"),
        ("פֿלאָוט",               "Float"),
        ("באָאָל",                "Bool"),
        ("תּו",                  "Character"),
        ("באַיט",                "UInt8"),
        ("מאַסיוו",              "Array"),
        ("ווערטערבוך",           "Dictionary"),
        ("סעט",                  "Set"),
        ("אָפּציע",              "Optional"),
        ("רעזולטאַט",            "Result"),
        ("טווח",                 "Range"),
        ("טווח_פֿון",            "ClosedRange"),

        // MARK: - Foundation Types (from DateWrappers, CodableWrappers, URLWrappers, FileManagerWrappers)

        ("אידענטיפֿיקאַטאָר",     "UUID"),
        ("דאַטום",               "Date"),
        ("דאַטום_פֿאָרמאַטירער",   "DateFormatter"),
        ("קאַלענדאַר",            "Calendar"),
        ("דאַטום_קאָמפּאָנענטן",   "DateComponents"),
        ("קאָדירבאַר",            "Codable"),
        ("דעקאָדירער",            "JSONDecoder"),
        ("קאָדירער",              "JSONEncoder"),
        ("אַדרעס",               "URL"),
        ("טעקע_פֿאַרוואַלטער",    "FileManager"),

        // MARK: - Networking Types (from URLSessionWrappers)

        ("נעץ_זיצונג",          "URLSession"),
        ("נעץ_בקשה",            "URLRequest"),

        // MARK: - SwiftUI Views (from ViewWrappers)

        ("בליק",                 "View"),
        ("טעקסט",                "Text"),
        ("קנעפּל",               "Button"),
        ("בילד",                 "Image"),
        ("רשימה",                "List"),
        ("נאַוויגאַציע_שטאַפּל",  "NavigationStack"),
        ("שטאַפּל_ה",            "HStack"),
        ("שטאַפּל_וו",           "VStack"),
        ("שטאַפּל_צ",            "ZStack"),
        ("בלעטל",                "ScrollView"),
        ("פּלאַצהאַלטער",         "Spacer"),
        ("טיילער",               "Divider"),
        ("טעקסט_פֿעלד",          "TextField"),
        ("פֿאָרם",                "Form"),
        ("אָפּטיילונג",           "Section"),
        ("קייקל",                "Circle"),
        ("פֿירקאַנט",             "Rectangle"),
        ("אויסוואַל",            "Picker"),
        ("שאַלטער",              "Toggle"),
        ("שיבער",                "Slider"),
        ("פּראָגרעס_בליק",        "ProgressView"),
        ("פֿאַר_יעדן",            "ForEach"),

        // MARK: - SwiftUI App Lifecycle (new — not yet in Bibliotek wrappers)

        ("אַפּ",                  "App"),
        ("סצענע",                "Scene"),
        ("פֿענצטער_גרופּע",       "WindowGroup"),
        ("פֿאַרב",                "Color"),

        // MARK: - SwiftUI State Management (from StateWrappers)

        ("צושטאַנד",             "State"),
        ("בינדונג",              "Binding"),
        ("סביבה_אָביעקט",        "EnvironmentObject"),
        ("סביבה",                "Environment"),
        ("באָאָבאַכטבאַר",         "Observable"),
        ("פּובליצירט",            "Published"),

        // MARK: - CoreGraphics Types (from CGWrappers)

        ("צג_צאָל",              "CGFloat"),
        ("צג_פּונקט",            "CGPoint"),
        ("צג_גרייס",            "CGSize"),
        ("צג_פֿירקאַנט",         "CGRect"),

        // MARK: - Charts Types (from ChartWrappers)

        ("טשאַרט",               "Chart"),
        ("באַלקן_צייכן",         "BarMark"),
        ("ליניע_צייכן",          "LineMark"),
        ("פּונקט_צייכן",          "PointMark"),
        ("פֿלאַך_צייכן",          "AreaMark"),
        ("כּלל_צייכן",           "RuleMark"),

        // MARK: - SwiftData Types (from SwiftDataWrappers)

        ("מאָדעל_באַהעלטער",     "ModelContainer"),
        ("מאָדעל_קאָנטעקסט",     "ModelContext"),
        ("הערונטערלאָד_באַשרײַבונג", "FetchDescriptor"),
        ("סאָרטיר_באַשרײַבונג",   "SortDescriptor"),

        // MARK: - SwiftData Macros (new — not yet in Bibliotek wrappers)

        ("מאָדעל",               "Model"),
        ("אָנפֿרעג",             "Query"),

        // MARK: - Protocols (new — not yet in Bibliotek wrappers)

        ("זיכבאַשטימט",          "Identifiable"),
        ("האַשבאַר",              "Hashable"),

        // MARK: - Global Functions (from PrintWrapper)

        ("דרוק",                 "print"),

        // MARK: - Collection / String Methods (from StringWrappers, CollectionWrappers)

        ("צאָל_פֿון",            "count"),
        ("איז_ליידיק",          "isEmpty"),
        ("צולייגן",              "append"),
        ("מכיל",                 "contains"),
        ("האַט_פּרעפֿיקס",        "hasPrefix"),
        ("האַט_סופֿיקס",         "hasSuffix"),
        ("קליינע_אותיות",        "lowercased"),
        ("גרויסע_אותיות",        "uppercased"),
        ("באַשרײַבונג",          "description"),
        ("פֿילטער",              "filter"),
        ("מאַפּע",               "map"),
        ("רעדוצירן",             "reduce"),
        ("סאָרטירט",             "sorted"),
        ("ערשטער",               "first"),
        ("לעצטער",               "last"),
        ("אַוועקנעמען",          "remove"),
        ("פֿאָריעדער",            "forEach"),
        ("פֿלאַך_מאַפּע",         "flatMap"),
        ("קאָמפּאַקט_מאַפּע",      "compactMap"),
        ("שליסלען",              "keys"),
        ("ווערטן",               "values"),
        ("אײַנפֿירן",            "insert"),

        // MARK: - Foundation Properties / Methods

        ("איצט",                 "now"),
        ("דאַטום_פֿאָרמאַט",      "dateFormat"),
        ("דעקאָדירן",             "decode"),
        ("קאָדירן",               "encode"),
        ("וועג",                  "path"),
        ("לעצטער_באַשטאַנדטייל",  "lastPathComponent"),
        ("טעקע_עקזיסטירט",       "fileExists"),
        ("דאַטן",                 "data"),

        // MARK: - SwiftUI Modifiers (from ModifierWrappers — 1:1 mappings only)

        ("פּאַדינג",              "padding"),
        ("אונטערלייג",           "background"),
        ("פֿאָרגרונט_פֿאַרב",     "foregroundStyle"),
        ("שריפֿט",               "font"),
        ("בלעטל_טיטל",          "navigationTitle"),
        ("ראַם",                  "border"),
        ("פֿאַרב_שאָטן",          "shadow"),
        ("אָפּגעשניטן",           "clipShape"),
        ("דורכזיכטיקייט",        "opacity"),

        // MARK: - Font Styles (SwiftUI Font static properties)

        ("טיטל",                  "title"),
        ("גרויסער_טיטל",         "largeTitle"),
        ("שלאַגצײַל",             "headline"),
        ("כאָטש",                 "subheadline"),
        ("פֿוסנאָט",              "footnote"),
        ("כיתוב",                "caption"),

        // MARK: - Common SwiftUI Parameter Labels & Properties

        ("מרחק",                  "spacing"),
        ("מלל",                   "text"),
        ("ווערט",                 "value"),

        // MARK: - Common Framework Identifiers

        ("ראשי",                  "main"),
        ("גוף",                   "body"),
        ("מזהה",                  "id"),
        ("אומקערן",               "toggle"),
        ("סאָרטירונג",            "sort"),
        ("מאָדעל_אײַנשטעלן",     "modelContainer"),
        ("מאָדעל_סביבה",         "modelContext"),

        // MARK: - Color Names (from ColorWrappers)

        ("רויט",                  "red"),
        ("בלוי",                  "blue"),
        ("גרין",                  "green"),
        ("ווײַס",                 "white"),
        ("שוואַרץ",               "black"),
        ("גרוי",                  "gray"),
        ("געל",                   "yellow"),
        ("אָראַנזש",              "orange"),
        ("לילאַ",                 "purple"),
        ("ראָזע",                 "pink"),
        ("ציאַן",                 "cyan"),
        ("מינט",                  "mint"),
        ("ברוין",                 "brown"),
        ("אינדיגאָ",              "indigo"),

        // MARK: - Parameter Labels (unambiguous framework vocabulary)

        ("דורך",                  "by"),
    ])
}
