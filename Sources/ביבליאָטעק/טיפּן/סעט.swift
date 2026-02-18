public typealias סעט = Set

extension Set {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func אַרײַנלייגן(_ עלעמענט: Element) { insert(עלעמענט) }
    @_transparent public mutating func אויסמעקן(_ עלעמענט: Element) { remove(עלעמענט) }
    @_transparent public func כּולל(_ עלעמענט: Element) -> Bool { contains(עלעמענט) }
    @_transparent public func פֿאַראייניקונג(_ אַנדערן: Set<Element>) -> Set<Element> { union(אַנדערן) }
    @_transparent public func דורכשנאַפּ(_ אַנדערן: Set<Element>) -> Set<Element> { intersection(אַנדערן) }
    @_transparent public func אויסשלוס(_ אַנדערן: Set<Element>) -> Set<Element> { subtracting(אַנדערן) }
    @_transparent public func איז_אונטערגרופּע(_ אַנדערן: Set<Element>) -> Bool { isSubset(of: אַנדערן) }
    @_transparent public func איז_אָבערגרופּע(_ אַנדערן: Set<Element>) -> Bool { isSuperset(of: אַנדערן) }
}
