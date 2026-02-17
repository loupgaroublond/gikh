import Foundation

public typealias אַדרעס = URL

extension URL {
    @_transparent public var וועג: String { path() }
    @_transparent public var לעצטער_באַשטאַנדטייל: String { lastPathComponent }
    @_transparent public var פֿאַרלענגערונג: String { pathExtension }
}
