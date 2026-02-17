import Foundation

public typealias טעקע_פֿאַרוואַלטער = FileManager

extension FileManager {
    @_transparent public static var פֿעליק: FileManager { .default }
    @_transparent public func טעקע_עקזיסטירט(בײַ path: String) -> Bool { fileExists(atPath: path) }
    @_transparent public func אינהאַלט_פֿון(מאַפּע path: String) throws -> [String] { try contentsOfDirectory(atPath: path) }
}
