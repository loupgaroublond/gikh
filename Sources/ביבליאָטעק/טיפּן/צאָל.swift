public typealias צאָל = Int

extension Int {
    @_transparent public var אַבסאָלוט: Int { abs(self) }
    @_transparent public var איז_גלײַך: Bool { self % 2 == 0 }
    @_transparent public var איז_אומגלײַך: Bool { self % 2 != 0 }
    @_transparent public func מין_מיט(_ אַנדערן: Int) -> Int { Swift.min(self, אַנדערן) }
    @_transparent public func מאַקס_מיט(_ אַנדערן: Int) -> Int { Swift.max(self, אַנדערן) }
}
