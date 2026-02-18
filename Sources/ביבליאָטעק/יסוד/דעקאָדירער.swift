import Foundation

public typealias דאַטן = Data

extension Data {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public init(אינהאַלט וועג: URL) throws { try self.init(contentsOf: וועג) }
    @_transparent public func שרײַבן_צו(וועג: URL) throws { try write(to: וועג) }
    @_transparent public func סטרינג(קאָדירונג: String.Encoding = .utf8) -> String? { String(data: self, encoding: קאָדירונג) }
}

extension String {
    @_transparent public func דאַטן(קאָדירונג: String.Encoding = .utf8) -> Data? { data(using: קאָדירונג) }
}

public typealias יאיסאן_דעקאָדירער = JSONDecoder

extension JSONDecoder {
    @_transparent public func דעקאָדירן<T: Decodable>(_ טיפּ: T.Type, פֿון דאַטן: Data) throws -> T {
        try decode(טיפּ, from: דאַטן)
    }
}

public typealias יאיסאן_קאָדירער = JSONEncoder

extension JSONEncoder {
    @_transparent public func קאָדירן<T: Encodable>(_ ווערט: T) throws -> Data {
        try encode(ווערט)
    }
}
