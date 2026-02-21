@_exported import Foundation

public typealias אַדרעס = URL

extension URL {
    @_transparent public init?(סטרינג: String) { self.init(string: סטרינג) }
    @_transparent public var וועג_סטרינג: String { absoluteString }
    @_transparent public var לעצטע_קאָמפּאָנענטע: String { lastPathComponent }
    @_transparent public var ספֿח: String { pathExtension }
    @_transparent public var איז_טעקע: Bool { hasDirectoryPath }
    @_transparent public func צוגעלייגט_קאָמפּאָנענטע(_ קאָמפּאָנענטע: String) -> URL { appendingPathComponent(קאָמפּאָנענטע) }
    @_transparent public func צוגעלייגט_ספֿח(_ ספֿח: String) -> URL { appendingPathExtension(ספֿח) }
    @_transparent public var אָן_לעצטע_קאָמפּאָנענטע: URL { deletingLastPathComponent() }
    @_transparent public var אָן_ספֿח: URL { deletingPathExtension() }
    @_transparent public var וועג: String { path }

    @_alwaysEmitIntoClient
    public init(טעקע_וועג: String) {
        self.init(fileURLWithPath: טעקע_וועג)
    }
}
