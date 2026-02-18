import Foundation

extension FileManager {
    @_transparent public func לייענען_דאַטן(פֿון וועג: URL) throws -> Data {
        try Data(contentsOf: וועג)
    }

    @_transparent public func שרײַבן_דאַטן(_ דאַטן: Data, אין וועג: URL) throws {
        try דאַטן.write(to: וועג)
    }

    @_transparent public func לייענען_טעקסט(פֿון וועג: URL, קאָדירונג: String.Encoding = .utf8) throws -> String {
        try String(contentsOf: וועג, encoding: קאָדירונג)
    }

    @_transparent public func שרײַבן_טעקסט(_ טעקסט: String, אין וועג: URL, קאָדירונג: String.Encoding = .utf8) throws {
        try טעקסט.write(to: וועג, atomically: true, encoding: קאָדירונג)
    }

    @_transparent public func עקסיסטירט_פֿײַל(אין וועג: String) -> Bool {
        var איז_טעקע: ObjCBool = false
        let עקסיסטירט = fileExists(atPath: וועג, isDirectory: &איז_טעקע)
        return עקסיסטירט && !איז_טעקע.boolValue
    }

    @_transparent public func עקסיסטירט_טעקע(אין וועג: String) -> Bool {
        var איז_טעקע: ObjCBool = false
        let עקסיסטירט = fileExists(atPath: וועג, isDirectory: &איז_טעקע)
        return עקסיסטירט && איז_טעקע.boolValue
    }

    @_transparent public var טעמפּ_טעקע: URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    @_transparent public var היים_טעקע: URL {
        homeDirectoryForCurrentUser
    }
}
