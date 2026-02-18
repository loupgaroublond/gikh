import Foundation

public typealias סטרינג = String

extension String {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ עלעמענט: Character) { append(עלעמענט) }
    @_transparent public func מיט_פּרעפֿיקס(_ פּרעפֿיקס: סטרינג) -> Bool { hasPrefix(פּרעפֿיקס) }
    @_transparent public func מיט_סופֿיקס(_ סופֿיקס: סטרינג) -> Bool { hasSuffix(סופֿיקס) }
}
