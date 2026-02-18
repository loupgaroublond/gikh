import Foundation

public typealias נעץ_ענטפֿער = URLResponse

extension URLResponse {
    @_transparent public var אַדרעס: URL? { url }
    @_transparent public var מיים_טיפּ: String? { mimeType }
    @_transparent public var אינהאַלט_לענג: Int64 { expectedContentLength }
    @_transparent public var קאָדירונג: String? { textEncodingName }
}

public typealias העטעּ_ענטפֿער = HTTPURLResponse

extension HTTPURLResponse {
    @_transparent public var סטאַטוס_קאָד: Int { statusCode }
    @_transparent public var כּותרות: [AnyHashable: Any] { allHeaderFields }

    @_transparent public func כּותרת_פֿאַר(_ שליסל: String) -> String? {
        value(forHTTPHeaderField: שליסל)
    }

    @_transparent public var איז_הצלחה: Bool { (200...299).contains(statusCode) }
}
