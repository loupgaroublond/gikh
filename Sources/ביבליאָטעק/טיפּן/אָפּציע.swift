public typealias אָפּציע = Optional

extension Optional {
    @_transparent public var איז_נישט: Bool { self == nil }
    @_transparent public var איז_דאָ: Bool { self != nil }

    @_transparent public func אָדער(_ פֿאָרשלאַג: @autoclosure () throws -> Wrapped) rethrows -> Wrapped {
        try self ?? פֿאָרשלאַג()
    }
}
