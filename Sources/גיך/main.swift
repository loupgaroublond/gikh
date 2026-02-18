import Foundation

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
    /// Auto-detects the source mode from the file extension / content.
    static func transpileSource(
        _ source: String,
        lexicon: Lexicon,
        target: TargetMode
    ) -> String {
        var scanner = Scanner(source: source)
        let tokens = scanner.scan()
        let annotator = BidiAnnotator()

        switch target {
        case .modeB:
            // Target Mode B: swap English → Yiddish (full mode), then annotate RTL
            let translator = Translator(
                lexicon: lexicon,
                direction: .toYiddish,
                mode: .full
            )
            let translated = translator.translate(tokens)
            return annotator.annotate(translated, target: .modeB)

        case .modeA:
            // Target Mode A: swap Yiddish → English (full mode), strip BiDi
            let translator = Translator(
                lexicon: lexicon,
                direction: .toEnglish,
                mode: .full
            )
            let translated = translator.translate(tokens)
            return annotator.annotate(translated, target: .modeA)

        case .modeC:
            // Target Mode C: swap Yiddish keywords → English (keywords only), strip BiDi
            let translator = Translator(
                lexicon: lexicon,
                direction: .toEnglish,
                mode: .keywordsOnly
            )
            let translated = translator.translate(tokens)
            return annotator.annotate(translated, target: .modeC)
        }
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
