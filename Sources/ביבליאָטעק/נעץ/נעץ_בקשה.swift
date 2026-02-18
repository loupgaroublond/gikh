import Foundation

public typealias נעץ_בקשה = URLRequest

extension URLRequest {
    @_transparent public init(אַדרעס: URL) { self.init(url: אַדרעס) }

    @_transparent public var אַדרעס: URL? {
        get { url }
        set { url = newValue }
    }

    @_transparent public var מעטאָד: String? {
        get { httpMethod }
        set { httpMethod = newValue }
    }

    @_transparent public var גוף: Data? {
        get { httpBody }
        set { httpBody = newValue }
    }

    @_transparent public var כּותרות: [String: String]? {
        get { allHTTPHeaderFields }
        set { allHTTPHeaderFields = newValue }
    }

    @_transparent public mutating func שטעלן_כּותרת(ווערט: String, פֿאַר שליסל: String) {
        setValue(ווערט, forHTTPHeaderField: שליסל)
    }

    @_transparent public mutating func צולייגן_כּותרת(ווערט: String, פֿאַר שליסל: String) {
        addValue(ווערט, forHTTPHeaderField: שליסל)
    }
}
