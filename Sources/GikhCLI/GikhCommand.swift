// GikhCommand.swift
// GikhCLI — Main CLI entry point for the Gikh transpiler.

import ArgumentParser
import GikhCore
import Foundation

// MARK: - Root Command

@main
struct Gikh: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gikh",
        abstract: "גיך — A Yiddish Swift Transpiler",
        subcommands: [
            ToEnglish.self,
            ToYiddish.self,
            ToHybrid.self,
            Verify.self,
            LexiconCommand.self,
            ScanCommand.self,
        ]
    )
}

// MARK: - Shared Helpers

/// Options shared across transpilation subcommands.
struct TranspileOptions: ParsableArguments {
    @Argument(help: "Input file path(s) — .gikh or .swift files.")
    var paths: [String] = []

    @Option(name: .shortAndLong, help: "Output file path. Defaults to stdout.")
    var output: String?

    @Option(name: .long, help: "Path to the project dictionary (לעקסיקאָן.yaml).")
    var dictionary: String?
}

/// Load a lexicon from the shared options, falling back to a default.
func loadLexicon(dictionaryPath: String?) throws -> Lexicon {
    if let path = dictionaryPath {
        let projectIdentifiers = try Lexicon.loadProjectIdentifiers(from: path)
        return try Lexicon.forDeveloper(projectIdentifiers: projectIdentifiers)
    } else {
        // Minimal lexicon with compiled-in keywords only.
        return Lexicon.forCompilation()
    }
}

/// Read source from a file path, transpile, and write output.
func transpileFile(
    path: String,
    to targetMode: TargetMode,
    lexicon: Lexicon,
    outputPath: String?
) throws {
    let url = URL(fileURLWithPath: path)
    let source = try String(contentsOf: url, encoding: .utf8)
    let sourceMode = Transpiler.detectMode(path: path)

    let result = Transpiler.transpile(
        source: source,
        from: sourceMode,
        to: targetMode,
        lexicon: lexicon
    )

    if let outputPath = outputPath {
        try result.write(
            to: URL(fileURLWithPath: outputPath),
            atomically: true,
            encoding: .utf8
        )
    } else {
        print(result, terminator: "")
    }
}

// MARK: - ToEnglish

/// Transpile any mode → Mode A (fully English .swift).
struct ToEnglish: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "to-english",
        abstract: "Transpile to Mode A — fully English Swift source."
    )

    @OptionGroup var options: TranspileOptions

    func run() throws {
        let lexicon = try loadLexicon(dictionaryPath: options.dictionary)

        for path in options.paths {
            try transpileFile(
                path: path,
                to: .modeA,
                lexicon: lexicon,
                outputPath: options.output
            )
        }
    }
}

// MARK: - ToYiddish

/// Transpile any mode → Mode B (fully Yiddish .gikh source of truth).
struct ToYiddish: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "to-yiddish",
        abstract: "Transpile to Mode B — fully Yiddish .gikh source."
    )

    @OptionGroup var options: TranspileOptions

    func run() throws {
        let lexicon = try loadLexicon(dictionaryPath: options.dictionary)

        for path in options.paths {
            try transpileFile(
                path: path,
                to: .modeB,
                lexicon: lexicon,
                outputPath: options.output
            )
        }
    }
}

// MARK: - ToHybrid

/// Transpile any mode → Mode C (hybrid for compilation).
struct ToHybrid: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "to-hybrid",
        abstract: "Transpile to Mode C — hybrid source for compilation."
    )

    @OptionGroup var options: TranspileOptions

    @Option(name: .long, help: "Input file path (alternative to positional argument, for build plugin use).")
    var input: String?

    func run() throws {
        let lexicon = try loadLexicon(dictionaryPath: options.dictionary)

        // Collect paths from both positional arguments and --input flag.
        var allPaths = options.paths
        if let inputPath = input {
            allPaths.append(inputPath)
        }

        guard !allPaths.isEmpty else {
            throw ValidationError("Provide at least one input file path.")
        }

        for path in allPaths {
            try transpileFile(
                path: path,
                to: .modeC,
                lexicon: lexicon,
                outputPath: options.output
            )
        }
    }
}

// MARK: - Verify

/// Round-trip verification: B → C → B, then diff against the original.
struct Verify: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify",
        abstract: "Verify round-trip fidelity: B → C → B, diff against original."
    )

    @Argument(help: "Input .gikh file(s) to verify.")
    var paths: [String]

    @Option(name: .long, help: "Path to the project dictionary (לעקסיקאָן.yaml).")
    var dictionary: String?

    func run() throws {
        let lexicon = try loadLexicon(dictionaryPath: dictionary)
        var hasFailures = false

        for path in paths {
            guard path.hasSuffix(".gikh") else {
                print("⚠ Skipping \(path) — verify only applies to .gikh files.")
                continue
            }

            let url = URL(fileURLWithPath: path)
            let original = try String(contentsOf: url, encoding: .utf8)

            // B → C
            let modeC = Transpiler.transpile(
                source: original,
                from: .modeB,
                to: .modeC,
                lexicon: lexicon
            )

            // C → B
            let roundTripped = Transpiler.transpile(
                source: modeC,
                from: .modeC,
                to: .modeB,
                lexicon: lexicon
            )

            if original == roundTripped {
                print("OK: \(path)")
            } else {
                hasFailures = true
                print("FAIL: \(path)")
                printDiff(original: original, roundTripped: roundTripped)
            }
        }

        if hasFailures {
            throw ExitCode(1)
        }
    }

    /// Print a simple line-by-line diff between the original and round-tripped content.
    private func printDiff(original: String, roundTripped: String) {
        let originalLines = original.components(separatedBy: "\n")
        let roundTrippedLines = roundTripped.components(separatedBy: "\n")
        let maxLines = max(originalLines.count, roundTrippedLines.count)

        for i in 0..<maxLines {
            let orig = i < originalLines.count ? originalLines[i] : ""
            let rt = i < roundTrippedLines.count ? roundTrippedLines[i] : ""

            if orig != rt {
                print("  line \(i + 1):")
                print("    - \(orig)")
                print("    + \(rt)")
            }
        }
    }
}

// MARK: - LexiconCommand

/// Manage the project dictionary: add entries or scan for untranslated identifiers.
struct LexiconCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lexicon",
        abstract: "Manage the project dictionary (לעקסיקאָן)."
    )

    @Option(name: .long, help: "Path to the project dictionary (לעקסיקאָן.yaml). Defaults to ./לעקסיקאָן.yaml.")
    var dictionary: String = "./\u{05DC}\u{05E2}\u{05E7}\u{05E1}\u{05D9}\u{05E7}\u{05D0}\u{05B8}\u{05DF}.yaml"

    @Flag(name: .long, help: "Add a new entry to the project dictionary.")
    var add = false

    @Flag(name: .long, help: "Scan for untranslated identifiers.")
    var scan = false

    @Argument(help: "For --add: <yiddish> <english>. For --scan: <path>.")
    var arguments: [String] = []

    func validate() throws {
        if add {
            guard arguments.count == 2 else {
                throw ValidationError("--add requires exactly two arguments: <yiddish> <english>")
            }
        }
        if scan {
            guard arguments.count == 1 else {
                throw ValidationError("--scan requires exactly one argument: <path>")
            }
        }
        if !add && !scan {
            throw ValidationError("Specify either --add or --scan.")
        }
    }

    func run() throws {
        if add {
            try runAdd()
        } else if scan {
            try runScan()
        }
    }

    private func runAdd() throws {
        let yiddish = arguments[0]
        let english = arguments[1]

        // Load existing dictionary or start fresh.
        let url = URL(fileURLWithPath: dictionary)
        var identifiers: [(String, String)] = []

        if FileManager.default.fileExists(atPath: url.path) {
            let existing = try Lexicon.loadProjectIdentifiers(from: dictionary)
            identifiers = existing.allPairs
        }

        // Check for duplicates before adding.
        let existingBiMap = BiMap<String, String>(identifiers)
        if existingBiMap.containsKey(yiddish) {
            print("Entry already exists: \(yiddish) → \(existingBiMap.toValue(yiddish)!)")
            return
        }
        if existingBiMap.containsValue(english) {
            print("English value already mapped: \(existingBiMap.toKey(english)!) → \(english)")
            return
        }

        identifiers.append((yiddish, english))

        // Write back as YAML.
        var yaml = "tier: project\nidentifiers:\n"
        for (yi, en) in identifiers {
            yaml += "  \(yi): \(en)\n"
        }
        try yaml.write(to: url, atomically: true, encoding: .utf8)

        print("Added: \(yiddish) → \(english)")
    }

    private func runScan() throws {
        let path = arguments[0]
        let lexicon = try loadLexicon(dictionaryPath: dictionary)

        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default

        // Collect all Swift/Gikh files.
        var files: [URL] = []
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil) {
                    while let fileURL = enumerator.nextObject() as? URL {
                        if fileURL.pathExtension == "swift" || fileURL.pathExtension == "gikh" {
                            files.append(fileURL)
                        }
                    }
                }
            } else {
                files.append(url)
            }
        }

        var untranslated: Set<String> = []

        for fileURL in files {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            var scanner = Scanner(source: source)
            let tokens = scanner.scan()

            for token in tokens {
                if case .identifier(let name, _) = token {
                    // Skip single-character identifiers and underscores.
                    guard name.count > 1, name != "_" else { continue }

                    if lexicon.translate(name, direction: .toEnglish) == nil &&
                       lexicon.translate(name, direction: .toYiddish) == nil {
                        untranslated.insert(name)
                    }
                }
            }
        }

        if untranslated.isEmpty {
            print("All identifiers have translations.")
        } else {
            print("Untranslated identifiers (\(untranslated.count)):")
            for ident in untranslated.sorted() {
                print("  \(ident)")
            }
        }
    }
}

// MARK: - ScanCommand

/// Scan an external Swift codebase and report translation coverage.
struct ScanCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan an external Swift codebase for translation coverage."
    )

    @Argument(help: "Path to the directory to scan.")
    var path: String

    @Option(name: .long, help: "Path to the project dictionary (לעקסיקאָן.yaml).")
    var dictionary: String?

    func run() throws {
        let lexicon = try loadLexicon(dictionaryPath: dictionary)

        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default

        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            print("Error: \(path) is not a directory.")
            throw ExitCode(1)
        }

        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil) else {
            print("Error: Could not enumerate \(path).")
            throw ExitCode(1)
        }

        var allIdentifiers: Set<String> = []
        var fileCount = 0

        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }
            fileCount += 1

            let source = try String(contentsOf: fileURL, encoding: .utf8)
            var scanner = Scanner(source: source)
            let tokens = scanner.scan()

            for token in tokens {
                if case .identifier(let name, _) = token {
                    guard name.count > 1, name != "_" else { continue }
                    allIdentifiers.insert(name)
                }
            }
        }

        var covered = 0
        var untranslated: [String] = []

        for ident in allIdentifiers {
            if lexicon.translate(ident, direction: .toEnglish) != nil ||
               lexicon.translate(ident, direction: .toYiddish) != nil {
                covered += 1
            } else {
                untranslated.append(ident)
            }
        }

        let total = allIdentifiers.count
        let percent = total > 0 ? Double(covered) / Double(total) * 100.0 : 100.0

        print("Scanned \(fileCount) Swift files.")
        print("Unique identifiers: \(total)")
        print("Covered: \(covered) (\(String(format: "%.1f", percent))%)")
        print("Untranslated: \(untranslated.count)")

        if !untranslated.isEmpty {
            print("\nUntranslated identifiers:")
            for ident in untranslated.sorted().prefix(50) {
                print("  \(ident)")
            }
            if untranslated.count > 50 {
                print("  ... and \(untranslated.count - 50) more")
            }
        }
    }
}
