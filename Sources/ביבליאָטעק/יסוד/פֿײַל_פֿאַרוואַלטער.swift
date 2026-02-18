import Foundation

extension FileManager {
    @_transparent public static var שותּפֿותּ: FileManager { FileManager.default }
    @_transparent public func עקסיסטירט(אין וועג: String) -> Bool { fileExists(atPath: וועג) }
    @_transparent public func אָפּמעקן(אין וועג: URL) throws { try removeItem(at: וועג) }
    @_transparent public func קאָפּירן(פֿון מקור: URL, צו ציל: URL) throws { try copyItem(at: מקור, to: ציל) }
    @_transparent public func אַריבערוואַרפֿן(פֿון מקור: URL, צו ציל: URL) throws { try moveItem(at: מקור, to: ציל) }
    @_transparent public func מאַכן_טעקע(אין וועג: URL, מיט_צווישן_מדרגות: Bool = true) throws {
        try createDirectory(at: וועג, withIntermediateDirectories: מיט_צווישן_מדרגות)
    }
    @_transparent public func אינהאַלט(פֿון טעקע: URL) throws -> [URL] {
        try contentsOfDirectory(at: טעקע, includingPropertiesForKeys: nil)
    }
    @_transparent public func אַרבעטס_טעקע() -> URL { URL(fileURLWithPath: currentDirectoryPath) }
}

public typealias פֿײַל_פֿאַרוואַלטער = FileManager
