public typealias מאַסיוו = Array
public typealias ווערטערבוך = Dictionary
public typealias סעט = Set
public typealias אָפּציע = Optional
public typealias רעזולטאַט = Result
public typealias טווח = Range
public typealias טווח_פֿון = ClosedRange
public typealias זיכבאַשטימט = Identifiable
public typealias האַשבאַר = Hashable

extension Array {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ newElement: Element) { append(newElement) }
    @_transparent public func פֿילטער(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] { try filter(isIncluded) }
    @_transparent public func מאַפּע<T>(_ transform: (Element) throws -> T) rethrows -> [T] { try map(transform) }
    @_transparent public func רעדוצירן<T>(_ initialResult: T, _ nextPartialResult: (T, Element) throws -> T) rethrows -> T { try reduce(initialResult, nextPartialResult) }
    @_transparent public func סאָרטירט(דורך areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> [Element] { try sorted(by: areInIncreasingOrder) }
    @_transparent public var ערשטער: Element? { first }
    @_transparent public var לעצטער: Element? { last }
    @_transparent public mutating func אַוועקנעמען(בײַ index: Int) -> Element { remove(at: index) }
    @_transparent public func פֿאָריעדער(_ body: (Element) throws -> Void) rethrows { try forEach(body) }
    @_transparent public func פֿלאַך_מאַפּע<T>(_ transform: (Element) throws -> [T]) rethrows -> [T] { try flatMap(transform) }
    @_transparent public func קאָמפּאַקט_מאַפּע<T>(_ transform: (Element) throws -> T?) rethrows -> [T] { try compactMap(transform) }
}

extension Dictionary {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public var שליסלען: Dictionary<Key, Value>.Keys { keys }
    @_transparent public var ווערטן: Dictionary<Key, Value>.Values { values }
}

extension Set {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func אײַנפֿירן(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) { insert(newMember) }
    @_transparent public func מכיל(_ member: Element) -> Bool { contains(member) }
}

extension Optional {
    @_transparent public var איז_גאָרנישט: Bool { self == nil }
}
