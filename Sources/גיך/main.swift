import Foundation

// גיך CLI — Phase 1 stub
// Usage: gikh compile <file.gikh|directory> [-o output]
// Passes .gikh content through unchanged to swiftc, linking ביבליאָטעק.

struct GikhCLI {
    enum CLIError: Error, CustomStringConvertible {
        case noInput
        case unknownCommand(String)
        case fileNotFound(String)
        case compilationFailed(Int32)
        case noBibliotekModule

        var description: String {
            switch self {
            case .noInput:
                return "Usage: gikh compile <file.gikh|directory> [-o output]"
            case .unknownCommand(let cmd):
                return "Unknown command: \(cmd). Available: compile"
            case .fileNotFound(let path):
                return "File not found: \(path)"
            case .compilationFailed(let code):
                return "Compilation failed with exit code \(code)"
            case .noBibliotekModule:
                return "Cannot find ביבליאָטעק module. Run 'swift build' first."
            }
        }
    }

    static func main() throws {
        let args = Array(CommandLine.arguments.dropFirst())

        guard let command = args.first else {
            throw CLIError.noInput
        }

        switch command {
        case "compile":
            try compile(args: Array(args.dropFirst()))
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    static func compile(args: [String]) throws {
        var inputPaths: [String] = []
        var outputPath = "a.out"
        var i = 0

        while i < args.count {
            if args[i] == "-o", i + 1 < args.count {
                outputPath = args[i + 1]
                i += 2
            } else {
                inputPaths.append(args[i])
                i += 1
            }
        }

        guard !inputPaths.isEmpty else {
            throw CLIError.noInput
        }

        let gikhFiles = try collectGikhFiles(from: inputPaths)

        guard !gikhFiles.isEmpty else {
            throw CLIError.noInput
        }

        let (modulePath, objectFiles) = try findBibliotek()

        // Read all .gikh file contents and concatenate
        var combinedSource = "import ביבליאָטעק\n"
        for file in gikhFiles {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            // Strip any existing "import ביבליאָטעק" to avoid duplicates
            let stripped = content.replacingOccurrences(
                of: "import ביבליאָטעק\n", with: ""
            )
            combinedSource += stripped
        }

        // Compile via stdin — no intermediate .swift files on disk
        try invokeSwiftc(
            source: combinedSource,
            modulePath: modulePath,
            objectFiles: objectFiles,
            outputPath: outputPath
        )
    }

    static func collectGikhFiles(from paths: [String]) throws -> [String] {
        let fm = FileManager.default
        var files: [String] = []

        for path in paths {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: path, isDirectory: &isDir) else {
                throw CLIError.fileNotFound(path)
            }
            if isDir.boolValue {
                if let enumerator = fm.enumerator(atPath: path) {
                    while let file = enumerator.nextObject() as? String {
                        if file.hasSuffix(".gikh") {
                            files.append((path as NSString).appendingPathComponent(file))
                        }
                    }
                }
            } else {
                files.append(path)
            }
        }

        return files
    }

    static func findBibliotek() throws -> (modulePath: String, objectFiles: [String]) {
        // Look for ביבליאָטעק build artifacts relative to the executable or in
        // common SwiftPM build paths.
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let buildDir = executableURL.deletingLastPathComponent()

        let modulesDir = buildDir.appendingPathComponent("Modules")
        let moduleFile = modulesDir.appendingPathComponent("ביבליאָטעק.swiftmodule")

        if FileManager.default.fileExists(atPath: moduleFile.path) {
            let objDir = buildDir.appendingPathComponent("ביבליאָטעק.build")
            let objectFiles = try FileManager.default
                .contentsOfDirectory(atPath: objDir.path)
                .filter { $0.hasSuffix(".o") }
                .map { objDir.appendingPathComponent($0).path }
            return (modulesDir.path, objectFiles)
        }

        throw CLIError.noBibliotekModule
    }

    static func invokeSwiftc(
        source: String,
        modulePath: String,
        objectFiles: [String],
        outputPath: String
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        var arguments = ["swiftc", "-", "-I", modulePath]
        arguments += objectFiles
        arguments += ["-o", outputPath]

        process.arguments = arguments

        let pipe = Pipe()
        process.standardInput = pipe

        try process.run()

        let sourceData = Data(source.utf8)
        pipe.fileHandleForWriting.write(sourceData)
        pipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw CLIError.compilationFailed(process.terminationStatus)
        }
    }
}

do {
    try GikhCLI.main()
} catch {
    FileHandle.standardError.write(Data("Error: \(error)\n".utf8))
    exit(1)
}
