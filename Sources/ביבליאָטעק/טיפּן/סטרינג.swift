import Foundation

public typealias סטרינג = String

extension String {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ עלעמענט: Character) { append(עלעמענט) }
    @_transparent public func מיט_פּרעפֿיקס(_ פּרעפֿיקס: סטרינג) -> Bool { hasPrefix(פּרעפֿיקס) }
    @_transparent public func מיט_סופֿיקס(_ סופֿיקס: סטרינג) -> Bool { hasSuffix(סופֿיקס) }
    @_transparent public func קליין_אותיות() -> סטרינג { lowercased() }
    @_transparent public func גרויסע_אותיות() -> סטרינג { uppercased() }
    @_transparent public func כּולל(_ אונטערסטרינג: סטרינג) -> Bool { contains(אונטערסטרינג) }
    @_transparent public func צעטיילן(טרענער: Character) -> [סטרינג] { split(separator: טרענער).map(String.init) }
    @_transparent public func אויסשנײַדן(רוי: סטרינג, מיט: סטרינג) -> סטרינג { replacingOccurrences(of: רוי, with: מיט) }
    @_transparent public func אָפּשנײַדן() -> סטרינג { trimmingCharacters(in: .whitespaces) }
    @_transparent public var איז_ניט_ליידיק: Bool { !isEmpty }

    // Split by String separator
    @_alwaysEmitIntoClient
    public func קאָמפּאָנענטן(טרענער: String) -> [String] {
        self.components(separatedBy: טרענער)
    }

    // Split by CharacterSet separator
    @_alwaysEmitIntoClient
    public func קאָמפּאָנענטן(צייכן_סעט: CharacterSet) -> [String] {
        self.components(separatedBy: צייכן_סעט)
    }

    // Prefix N characters
    @_alwaysEmitIntoClient
    public func ערשטע(_ צאָל: Int) -> Substring {
        self.prefix(צאָל)
    }

    // Suffix N characters
    @_alwaysEmitIntoClient
    public func לעצטע(_ צאָל: Int) -> Substring {
        self.suffix(צאָל)
    }

    // NSString bridging methods
    @_alwaysEmitIntoClient
    public var נס_לענג: Int { (self as NSString).length }

    @_alwaysEmitIntoClient
    public func צייכן(אין אינדעקס: Int) -> unichar {
        (self as NSString).character(at: אינדעקס)
    }

    @_alwaysEmitIntoClient
    public func אונטערסטרינג(אָרט: Int, לענג: Int) -> String {
        (self as NSString).substring(with: NSRange(location: אָרט, length: לענג))
    }
}

// MARK: - String format init
extension String {
    @_alwaysEmitIntoClient
    public init(פֿאָרמאַט: String, _ אַרגומענטן: CVarArg...) {
        self = String(format: פֿאָרמאַט, arguments: אַרגומענטן)
    }
}

// MARK: - CharacterSet Yiddish values
extension CharacterSet {
    @_transparent public static var ווײַסע_רוימען_און_נײַע_שורות: CharacterSet { .whitespacesAndNewlines }
    @_transparent public static var ווײַסע_רוימען: CharacterSet { .whitespaces }
}
