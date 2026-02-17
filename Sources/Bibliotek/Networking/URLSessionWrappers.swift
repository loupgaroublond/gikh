import Foundation

public typealias נעץ_זיצונג = URLSession
public typealias נעץ_בקשה = URLRequest

extension URLSession {
    @_transparent public func דאַטן(פֿון url: URL) async throws -> (Data, URLResponse) {
        try await data(from: url)
    }
}
