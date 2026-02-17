import Foundation

public typealias קאָדירבאַר = Codable
public typealias דעקאָדירער = JSONDecoder
public typealias קאָדירער = JSONEncoder

extension JSONDecoder {
    @_transparent public func דעקאָדירן<T: Decodable>(_ type: T.Type, פֿון data: Data) throws -> T {
        try decode(type, from: data)
    }
}

extension JSONEncoder {
    @_transparent public func קאָדירן<T: Encodable>(_ value: T) throws -> Data {
        try encode(value)
    }
}
