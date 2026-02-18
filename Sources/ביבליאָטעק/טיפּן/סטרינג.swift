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
}
