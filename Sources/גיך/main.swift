import Foundation
import GikhCore

// גיך CLI — Phase 2 transpiler
// Commands:
//   gikh compile      <file.gikh|dir> [-o output]   — B → C → swiftc
//   gikh to-english   <file|dir> [-o output-dir]    — any mode → Mode A
//   gikh to-yiddish   <file|dir> [-o output-dir]    — any mode → Mode B (.gikh)
//   gikh to-hybrid    <file|dir> [-o output-dir]    — any mode → Mode C

struct GikhCLI {
    enum CLIError: Error, CustomStringConvertible {
        case noInput
        case unknownCommand(String)
        case fileNotFound(String)
        case compilationFailed(Int32)
        case noBibliotekModule
        case readError(String)

        var description: String {
            switch self {
            case .noInput:
                return "Usage: gikh <command> <file.gikh|directory> [options]\n" +
                       "Commands: compile, to-english, to-yiddish, to-hybrid"
            case .unknownCommand(let cmd):
                return "Unknown command: \(cmd). Available: compile, to-english, to-yiddish, to-hybrid"
            case .fileNotFound(let path):
                return "File not found: \(path)"
            case .compilationFailed(let code):
                return "Compilation failed with exit code \(code)"
            case .noBibliotekModule:
                return "Cannot find ביבליאָטעק module. Run 'swift build' first."
            case .readError(let msg):
                return "Read error: \(msg)"
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
        case "to-english":
            try transpile(args: Array(args.dropFirst()), target: .modeA)
        case "to-yiddish":
            try transpile(args: Array(args.dropFirst()), target: .modeB)
        case "to-hybrid":
            try transpile(args: Array(args.dropFirst()), target: .modeC)
        case "scan":
            try scan(args: Array(args.dropFirst()))
        case "audit":
            try audit(args: Array(args.dropFirst()))
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    // MARK: - Transpilation commands

    /// Shared implementation for to-english, to-yiddish, to-hybrid.
    /// Reads all source files, transpiles each to the target mode, writes output.
    static func transpile(args: [String], target: TargetMode) throws {
        var inputPaths: [String] = []
        var outputDir: String? = nil
        var i = 0

        while i < args.count {
            if args[i] == "-o", i + 1 < args.count {
                outputDir = args[i + 1]
                i += 2
            } else {
                inputPaths.append(args[i])
                i += 1
            }
        }

        guard !inputPaths.isEmpty else {
            throw CLIError.noInput
        }

        // Collect all input files (both .gikh and .swift are valid inputs)
        let allFiles = try collectSourceFiles(from: inputPaths)
        guard !allFiles.isEmpty else {
            throw CLIError.noInput
        }

        // Find ביבליאָטעק path for lexicon loading (optional; best-effort)
        let bibliotekPath = findBibliotekSourcePath()

        // Build developer lexicon (loads all three tiers if available)
        let lexicon: Lexicon
        do {
            lexicon = try Lexicon.forDeveloper(
                bibliotekPath: bibliotekPath,
                projectPath: "./לעקסיקאָן.yaml"
            )
        } catch {
            // Fall back to compilation lexicon if developer lexicon fails
            lexicon = try Lexicon.forCompilation(bibliotekPath: bibliotekPath)
        }

        for file in allFiles {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let transpiled = transpileSource(content, lexicon: lexicon, target: target)

            if let outDir = outputDir {
                try writeOutput(
                    transpiled,
                    sourceFile: file,
                    inputPaths: inputPaths,
                    outputDir: outDir,
                    target: target
                )
            } else {
                // Print to stdout
                print(transpiled, terminator: "")
            }
        }
    }

    /// Transpile a source string to the given target mode.
    static func transpileSource(
        _ source: String,
        lexicon: Lexicon,
        target: TargetMode
    ) -> String {
        Transpiler.transpile(source, lexicon: lexicon, target: target)
    }

    // MARK: - File helpers

    /// Collect all .gikh and .swift files from the given paths.
    static func collectSourceFiles(from paths: [String]) throws -> [String] {
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
                        if file.hasSuffix(".gikh") || file.hasSuffix(".swift") {
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

    /// Collect only .gikh files from the given paths.
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

    /// Write transpiled output to the output directory, preserving relative path
    /// structure.
    static func writeOutput(
        _ content: String,
        sourceFile: String,
        inputPaths: [String],
        outputDir: String,
        target: TargetMode
    ) throws {
        // Determine relative path from input root
        let inputRoot = inputPaths.first ?? "."
        let relativePath: String
        if sourceFile.hasPrefix(inputRoot) {
            relativePath = String(sourceFile.dropFirst(inputRoot.count))
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        } else {
            relativePath = (sourceFile as NSString).lastPathComponent
        }

        // Change extension based on target
        let base = (relativePath as NSString).deletingPathExtension
        let ext: String
        switch target {
        case .modeB:  ext = "gikh"
        case .modeA, .modeC: ext = "swift"
        }

        let outputPath = (outputDir as NSString)
            .appendingPathComponent("\(base).\(ext)")

        let parent = (outputPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(
            atPath: parent,
            withIntermediateDirectories: true
        )

        try content.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }

    /// Find the ביבליאָטעק source directory (best-effort).
    static func findBibliotekSourcePath() -> String {
        let execURL = URL(fileURLWithPath: CommandLine.arguments[0])
        // Try common locations relative to the executable
        let candidates = [
            execURL.deletingLastPathComponent()
                .appendingPathComponent("../../../Sources/ביבליאָטעק").path,
            "./Sources/ביבליאָטעק",
            "./ביבליאָטעק",
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return "./Sources/ביבליאָטעק"
    }

    // MARK: - Scan command

    /// `gikh scan [--built <dir>] [--interface <file>] [--format table|yaml|diff] <path>`
    static func scan(args: [String]) throws {
        var inputPath: String? = nil
        var builtPath: String? = nil
        var interfacePath: String? = nil
        var format: ScanOutputFormat = .table
        var i = 0

        while i < args.count {
            switch args[i] {
            case "--built":
                i += 1
                if i < args.count { builtPath = args[i] }
            case "--interface":
                i += 1
                if i < args.count { interfacePath = args[i] }
            case "--format":
                i += 1
                if i < args.count {
                    format = ScanOutputFormat(rawValue: args[i]) ?? .table
                }
            default:
                inputPath = args[i]
            }
            i += 1
        }

        let lexicon = try Lexicon.forCompilation(
            bibliotekPath: findBibliotekSourcePath()
        )
        let checker = CoverageChecker(lexicon: lexicon)

        var symbols: [ExtractedSymbol] = []
        let projectName: String

        if let intfPath = interfacePath {
            // Scan a .swiftinterface file
            projectName = (intfPath as NSString).lastPathComponent
            let modName = projectName.components(separatedBy: ".").first ?? projectName
            let files = SwiftInterfaceParser.findInterfaceFiles(in: intfPath)
            if files.isEmpty {
                // Single file
                let content = (try? String(contentsOfFile: intfPath, encoding: .utf8)) ?? ""
                symbols = SwiftInterfaceParser.parse(content, moduleName: modName)
            } else {
                for f in files {
                    let content = (try? String(contentsOf: URL(fileURLWithPath: f), encoding: .utf8)) ?? ""
                    let mod = (f as NSString).lastPathComponent.components(separatedBy: ".").first ?? modName
                    symbols.append(contentsOf: SwiftInterfaceParser.parse(content, moduleName: mod))
                }
            }
        } else if let built = builtPath {
            // Scan built artifacts — find .swiftinterface files in .build directory
            projectName = (built as NSString).lastPathComponent
            let intfFiles = SwiftInterfaceParser.findInterfaceFiles(in: built)
            for f in intfFiles {
                let content = (try? String(contentsOf: URL(fileURLWithPath: f), encoding: .utf8)) ?? ""
                let mod = (f as NSString).lastPathComponent.components(separatedBy: ".").first ?? "Unknown"
                symbols.append(contentsOf: SwiftInterfaceParser.parse(content, moduleName: mod))
            }
        } else if let projPath = inputPath {
            // Scan source files in a project directory
            projectName = (projPath as NSString).lastPathComponent
            let fm = FileManager.default
            if let enumerator = fm.enumerator(atPath: projPath) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(".swift") || file.hasSuffix(".gikh") {
                        let fullPath = (projPath as NSString).appendingPathComponent(file)
                        let content = (try? String(contentsOfFile: fullPath, encoding: .utf8)) ?? ""
                        symbols.append(contentsOf: SymbolExtractor.extractFromSource(
                            content, moduleName: projectName
                        ))
                    }
                }
            }
        } else {
            throw CLIError.noInput
        }

        let report = checker.buildReport(symbols: symbols, projectName: projectName)
        let output = ScanOutputFormatter.format(report, format: format)
        print(output)
    }

    // MARK: - Audit command

    /// `gikh audit --compiled <.build dir>`
    static func audit(args: [String]) throws {
        var builtPath: String? = nil
        var i = 0
        while i < args.count {
            if args[i] == "--compiled", i + 1 < args.count {
                builtPath = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        }

        guard let path = builtPath else {
            print("Usage: gikh audit --compiled .build/")
            return
        }

        let lexicon = try Lexicon.forCompilation(
            bibliotekPath: findBibliotekSourcePath()
        )
        let checker = CoverageChecker(lexicon: lexicon)

        // Find .swiftinterface files in built artifacts
        let intfFiles = SwiftInterfaceParser.findInterfaceFiles(in: path)
        var symbols: [ExtractedSymbol] = []
        for f in intfFiles {
            let content = (try? String(contentsOf: URL(fileURLWithPath: f), encoding: .utf8)) ?? ""
            let mod = (f as NSString).lastPathComponent.components(separatedBy: ".").first ?? "Unknown"
            symbols.append(contentsOf: SwiftInterfaceParser.parse(content, moduleName: mod))
        }

        let report = checker.buildReport(symbols: symbols, projectName: "Audit")

        if report.uncoveredByModule.isEmpty {
            print("✓ All project identifiers covered")
            return
        }

        for (mod, syms) in report.uncoveredByModule.sorted(by: { $0.key < $1.key }) {
            print("⚠ \(syms.count) \(mod) symbols used but not in ביבליאָטעק:")
            for sym in syms.sorted(by: { $0.name < $1.name }) {
                print("  \(sym.name)  (\(mod))")
            }
        }
        print("\nAdd wrappers to ביבליאָטעק, or add translations to the project לעקסיקאָן.")
    }

    // MARK: - Compile command

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

        // Load compilation lexicon
        let bibliotekPath = findBibliotekSourcePath()
        let lexicon = try Lexicon.forCompilation(bibliotekPath: bibliotekPath)

        // Read, transpile (B→C), and concatenate all .gikh files
        var combinedSource = "import ביבליאָטעק\n"
        for file in gikhFiles {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let stripped = content.replacingOccurrences(
                of: "import ביבליאָטעק\n", with: ""
            )
            // Transpile Mode B → Mode C
            let transpiled = transpileSource(stripped, lexicon: lexicon, target: .modeC)
            combinedSource += transpiled
        }

        // Compile via stdin
        try invokeSwiftc(
            source: combinedSource,
            modulePath: modulePath,
            objectFiles: objectFiles,
            outputPath: outputPath
        )
    }

    static func findBibliotek() throws -> (modulePath: String, objectFiles: [String]) {
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
