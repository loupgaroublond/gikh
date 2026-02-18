import Foundation

extension Data {
    @_transparent public init(אינהאַלט_פֿון אַדרעס: URL) throws {
        try self.init(contentsOf: אַדרעס)
    }

    @_transparent public func אָפּהיטן(אין אַדרעס: URL) throws {
        try write(to: אַדרעס)
    }

    @_transparent public func אָפּהיטן(אין אַדרעס: URL, זיכער: Bool) throws {
        let אָפּציעס: Data.WritingOptions = זיכער ? .atomic : []
        try write(to: אַדרעס, options: אָפּציעס)
    }
}

extension String {
    @_transparent public init(טעקסט_פֿון אַדרעס: URL, קאָדירונג: String.Encoding = .utf8) throws {
        try self.init(contentsOf: אַדרעס, encoding: קאָדירונג)
    }

    @_transparent public func אָפּהיטן(אין אַדרעס: URL, קאָדירונג: String.Encoding = .utf8) throws {
        try write(to: אַדרעס, atomically: true, encoding: קאָדירונג)
    }
}
