public typealias טאָפּל = Double

extension Double {
    @_transparent public var אַבסאָלוט: Double { Swift.abs(self) }
    @_transparent public var קאַטעגאָריע: Int { Int(self) }
    @_transparent public static var אומענדלעך: Double { Double.infinity }
    @_transparent public static var ניט_א_צאָל: Double { Double.nan }
    @_transparent public func אָפּרונדן() -> Double { rounded() }
    @_transparent public func מין_מיט(_ אַנדערן: Double) -> Double { Swift.min(self, אַנדערן) }
    @_transparent public func מאַקס_מיט(_ אַנדערן: Double) -> Double { Swift.max(self, אַנדערן) }
}
