// stdlib String wrappers
import Foundation

public typealias סטרינג = String

extension String {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ element: Character) { append(element) }
    @_transparent public func מכיל(_ other: String) -> Bool { contains(other) }
    @_transparent public var אויבערשטער: Character? { first }
    @_transparent public var אונטערשטער: Character? { last }
    @_transparent public func האַט_פּרעפֿיקס(_ prefix: String) -> Bool { hasPrefix(prefix) }
    @_transparent public func האַט_סופֿיקס(_ suffix: String) -> Bool { hasSuffix(suffix) }
    @_transparent public var קליינע_אותיות: String { lowercased() }
    @_transparent public var גרויסע_אותיות: String { uppercased() }
    @_transparent public var באַשניטן: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
