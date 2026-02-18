public typealias ווערטערבוך = Dictionary

extension Dictionary {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public var שליסלען: Keys { keys }
    @_transparent public var ווערטן: Values { values }
    @_transparent public mutating func דערהײַנטיקן(_ ווערט: Value, פֿאַר שליסל: Key) { self[שליסל] = ווערט }
    @_transparent public mutating func אויסמעקן(שליסל: Key) { removeValue(forKey: שליסל) }
    @_transparent public func כּולל_שליסל(_ שליסל: Key) -> Bool { self[שליסל] != nil }
    @_transparent public func מאַפּע_ווערטן<T>(_ איבערמאַכן: (Value) throws -> T) rethrows -> [Key: T] { try mapValues(איבערמאַכן) }
    @_transparent public func פֿילטער(_ האַלט_צו: ((key: Key, value: Value)) throws -> Bool) rethrows -> [Key: Value] { try filter(האַלט_צו) }
}
