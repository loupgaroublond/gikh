public typealias פֿלאָוט = Float

extension Float {
    @_transparent public var אַבסאָלוט: Float { Swift.abs(self) }
    @_transparent public var קאַטעגאָריע: Int { Int(self) }
    @_transparent public func אָפּרונדן() -> Float { rounded() }
    @_transparent public func מין_מיט(_ אַנדערן: Float) -> Float { Swift.min(self, אַנדערן) }
    @_transparent public func מאַקס_מיט(_ אַנדערן: Float) -> Float { Swift.max(self, אַנדערן) }
}
