import Foundation

public typealias דאַטום = Date

extension Date {
    @_transparent public static var איצט: Date { Date() }
    @_transparent public var צײַט_שטעמפּל: TimeInterval { timeIntervalSince1970 }
    @_transparent public func צײַט_זינט(_ אַנדערן: Date) -> TimeInterval { timeIntervalSince(אַנדערן) }
    @_transparent public func צוגעלייגט_שעות(_ שעות: Double) -> Date { addingTimeInterval(שעות * 3600) }
    @_transparent public func צוגעלייגט_טעג(_ טעג: Double) -> Date { addingTimeInterval(טעג * 86400) }
    @_transparent public func איז_פֿריִער_ווי(_ אַנדערן: Date) -> Bool { self < אַנדערן }
    @_transparent public func איז_שפּעטער_ווי(_ אַנדערן: Date) -> Bool { self > אַנדערן }
}

public typealias צײַט_קוושה = TimeInterval
