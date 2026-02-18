import Foundation

public typealias פֿײַל_גריף = FileHandle

extension FileHandle {
    @_transparent public static var סטאַנדאַרט_אויסגאַב: FileHandle { FileHandle.standardOutput }
    @_transparent public static var סטאַנדאַרט_פֿעלער: FileHandle { FileHandle.standardError }
    @_transparent public static var סטאַנדאַרט_אײַנגאַב: FileHandle { FileHandle.standardInput }

    @_transparent public func לייענען(ביז_סוף: Bool = true) throws -> Data {
        try readToEnd() ?? Data()
    }

    @_transparent public func לייענען(לענג: Int) throws -> Data? {
        try read(upToCount: לענג)
    }

    @_transparent public func שרײַבן(_ דאַטן: Data) throws {
        try write(contentsOf: דאַטן)
    }

    @_transparent public func באַוועגן_צו(אָפּזאַץ: UInt64) throws {
        try seek(toOffset: אָפּזאַץ)
    }

    @_transparent public func שליסן() throws {
        try close()
    }
}
