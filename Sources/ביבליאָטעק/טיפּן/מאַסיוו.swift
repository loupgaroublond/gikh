public typealias מאַסיוו = Array

extension Array {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ נײַ_עלעמענט: Element) { append(נײַ_עלעמענט) }
    @_transparent public func פֿילטער(_ איז_אַרײַנגענומען: (Element) throws -> Bool) rethrows -> [Element] { try filter(איז_אַרײַנגענומען) }
    @_transparent public func מאַפּע<T>(_ איבערמאַכן: (Element) throws -> T) rethrows -> [T] { try map(איבערמאַכן) }
    @_transparent public func רעדוצירן<T>(_ אָנהייב_ווערט: T, _ קאָמבינירן: (T, Element) throws -> T) rethrows -> T { try reduce(אָנהייב_ווערט, קאָמבינירן) }
    @_transparent public func סאָרטירט(דורך זענען_אין_סדר: (Element, Element) throws -> Bool) rethrows -> [Element] { try sorted(by: זענען_אין_סדר) }
    @_transparent public var ערשטן: Element? { first }
    @_transparent public var לעצטן: Element? { last }
    @_transparent public func כּולל(ווו האַלט_צו: (Element) throws -> Bool) rethrows -> Bool { try contains(where: האַלט_צו) }
    @_transparent public func ערשטן_ווו(_ האַלט_צו: (Element) throws -> Bool) rethrows -> Element? { try first(where: האַלט_צו) }
    @_transparent public mutating func אָנהענגען(פֿון אַנדערן: [Element]) { append(contentsOf: אַנדערן) }
    @_transparent public func פֿלאַך_מאַפּע<T>(_ איבערמאַכן: (Element) throws -> [T]) rethrows -> [T] { try flatMap(איבערמאַכן) }
    @_transparent public func יעדן(_ טוען: (Element) throws -> Void) rethrows { try forEach(טוען) }
    @_transparent public mutating func אויסמעקן_לעצטן() -> Element { removeLast() }
    @_transparent public func צוגעפּאָרט() -> EnumeratedSequence<[Element]> { enumerated() }
}
