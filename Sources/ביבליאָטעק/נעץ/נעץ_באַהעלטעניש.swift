import Foundation

public typealias נעץ_באַהעלטעניש = URLCache

extension URLCache {
    @_transparent public static var שותּפֿותּ: URLCache { URLCache.shared }

    @_transparent public var זכּרון_קאַפּאַציטעט: Int {
        get { memoryCapacity }
        set { memoryCapacity = newValue }
    }

    @_transparent public var פּלאַטע_קאַפּאַציטעט: Int {
        get { diskCapacity }
        set { diskCapacity = newValue }
    }

    @_transparent public var בונוצטע_זכּרון: Int { currentMemoryUsage }
    @_transparent public var בונוצטע_פּלאַטע: Int { currentDiskUsage }

    @_transparent public func אויסמעקן_אַלץ() { removeAllCachedResponses() }
}

public typealias נעץ_באַהעלטעניש_ענטפֿער = CachedURLResponse

extension CachedURLResponse {
    @_transparent public var ענטפֿער: URLResponse { response }
    @_transparent public var דאַטן: Data { data }
}
