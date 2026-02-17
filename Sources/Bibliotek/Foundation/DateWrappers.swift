import Foundation

public typealias דאַטום = Date
public typealias דאַטום_פֿאָרמאַטירער = DateFormatter
public typealias קאַלענדאַר = Calendar
public typealias דאַטום_קאָמפּאָנענטן = DateComponents

extension Date {
    @_transparent public static var איצט: Date { Date.now }
    @_transparent public var באַשרײַבונג: String { description }
}

extension DateFormatter {
    @_transparent public var דאַטום_פֿאָרמאַט: String {
        get { dateFormat }
        set { dateFormat = newValue }
    }
}
