import Foundation
import GikhCore

// גיך CLI — Phase 2 transpiler
// Commands:
//   gikh compile      <file.gikh|dir> [-o output]   — B → C → swiftc
//   gikh to-english   <file|dir> [-o output-dir]    — any mode → Mode A
//   gikh to-yiddish   <file|dir> [-o output-dir]    — any mode → Mode B (.gikh)
//   gikh to-hybrid    <file|dir> [-o output-dir]    — any mode → Mode C
//   gikh verify       <file|dir>                    — round-trip verification + collision check
//   gikh lexicon      --add <english> <yiddish>     — add entry to project לעקסיקאָן.yaml
//   gikh lexicon      --scan <dir>                  — find untranslated identifiers in .gikh files
//   gikh lexicon      --suggest [--from-scan <dir>] — propose translations from common-words.yaml
//   gikh bridge       --generate                    — regenerate ביבליאָטעק wrapper files
//   gikh scan         <path>                        — analyze external codebase without modifying
//   gikh audit        --compiled <.build dir>       — check ביבליאָטעק coverage

struct GikhCLI {
    enum CLIError: Error, CustomStringConvertible {
        case noInput
        case unknownCommand(String)
        case fileNotFound(String)
        case compilationFailed(Int32)
        case noBibliotekModule
        case readError(String)
        case verificationFailed(diffs: [VerifyDiff])
        case lexiconError(String)

        var description: String {
            switch self {
            case .noInput:
                return "Usage: gikh <command> <file.gikh|directory> [options]\n" +
                       "Commands: compile, to-english, to-yiddish, to-hybrid, verify, lexicon, bridge, scan, audit"
            case .unknownCommand(let cmd):
                return "Unknown command: \(cmd). Available: compile, to-english, to-yiddish, to-hybrid, verify, lexicon, bridge, scan, audit"
            case .fileNotFound(let path):
                return "File not found: \(path)"
            case .compilationFailed(let code):
                return "Compilation failed with exit code \(code)"
            case .noBibliotekModule:
                return "Cannot find ביבליאָטעק module. Run 'swift build' first."
            case .readError(let msg):
                return "Read error: \(msg)"
            case .verificationFailed(let diffs):
                var lines = ["Verification failed: \(diffs.count) file(s) did not round-trip cleanly.\n"]
                for diff in diffs {
                    lines.append("  \(diff.file): \(diff.description)")
                }
                return lines.joined(separator: "\n")
            case .lexiconError(let msg):
                return "Lexicon error: \(msg)"
            }
        }
    }

    // MARK: - Round-trip verification diff result

    struct VerifyDiff {
        let file: String
        let description: String
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
        case "verify":
            try verify(args: Array(args.dropFirst()))
        case "lexicon":
            try lexicon(args: Array(args.dropFirst()))
        case "bridge":
            try bridge(args: Array(args.dropFirst()))
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

    // MARK: - Verify command

    /// `gikh verify <file|dir>`
    ///
    /// Performs round-trip verification:
    ///   - Mode B (.gikh) → Mode C → Mode B must produce identical output.
    ///   - Mode A → Mode B → Mode A must produce identical output.
    /// Also checks for collisions between built-in mappings and project identifiers.
    /// Exit code 0 on success, non-zero on any diff or collision.
    static func verify(args: [String]) throws {
        var inputPaths: [String] = []
        for arg in args where !arg.hasPrefix("-") {
            inputPaths.append(arg)
        }

        guard !inputPaths.isEmpty else {
            throw CLIError.noInput
        }

        let bibliotekPath = findBibliotekSourcePath()

        // Step 1: Check for collisions between built-in mappings and project identifiers.
        // This loads the full developer lexicon (which validates on construction).
        print("Checking collision detection...")
        do {
            _ = try Lexicon.forDeveloper(
                bibliotekPath: bibliotekPath,
                projectPath: "./לעקסיקאָן.yaml"
            )
            print("  ✓ No collisions between built-in mappings and project identifiers.")
        } catch let e as LexiconError {
            // Collision detected — print and exit non-zero
            fputs("  ✗ \(e.description)\n", stderr)
            exit(1)
        } catch {
            fputs("  ✗ Lexicon error: \(error)\n", stderr)
            exit(1)
        }

        // Use compilation lexicon for the round-trip verification itself.
        // (The developer lexicon with project identifiers is already validated above.)
        let compileLexicon = try Lexicon.forCompilation(bibliotekPath: bibliotekPath)

        // Load developer lexicon for A↔B round-trips
        let developerLexicon: Lexicon
        do {
            developerLexicon = try Lexicon.forDeveloper(
                bibliotekPath: bibliotekPath,
                projectPath: "./לעקסיקאָן.yaml"
            )
        } catch {
            developerLexicon = compileLexicon
        }

        // Collect .gikh files for B→C→B round-trip test
        let gikhFiles = try collectGikhFiles(from: inputPaths)

        var diffs: [VerifyDiff] = []

        // Step 2: B → C → B round-trip
        print("Verifying B → C → B round-trip (\(gikhFiles.count) .gikh file(s))...")
        for file in gikhFiles {
            let original = try String(contentsOfFile: file, encoding: .utf8)
            // B → C (keywords-only transpilation, strip BiDi)
            let modeC = Transpiler.transpile(original, lexicon: compileLexicon, target: .modeC)
            // C → B (add BiDi back, swap keywords back to Yiddish)
            let roundTripped = Transpiler.transpile(modeC, lexicon: compileLexicon, target: .modeB)

            if roundTripped != original {
                let diffDesc = diffDescription(original: original, roundTripped: roundTripped, label: "B→C→B")
                diffs.append(VerifyDiff(file: file, description: diffDesc))
                print("  ✗ \(file): B→C→B mismatch")
                print(diffDesc)
            } else {
                print("  ✓ \(file): B→C→B OK")
            }
        }

        // Step 3: A → B → A round-trip (for .swift files)
        let swiftFiles = try collectSwiftFiles(from: inputPaths)
        print("Verifying A → B → A round-trip (\(swiftFiles.count) .swift file(s))...")
        for file in swiftFiles {
            let original = try String(contentsOfFile: file, encoding: .utf8)
            // A → B (full translation with BiDi)
            let modeB = Transpiler.transpile(original, lexicon: developerLexicon, target: .modeB)
            // B → A (strip BiDi, full translation back)
            let roundTripped = Transpiler.transpile(modeB, lexicon: developerLexicon, target: .modeA)

            if roundTripped != original {
                let diffDesc = diffDescription(original: original, roundTripped: roundTripped, label: "A→B→A")
                diffs.append(VerifyDiff(file: file, description: diffDesc))
                print("  ✗ \(file): A→B→A mismatch")
                print(diffDesc)
            } else {
                print("  ✓ \(file): A→B→A OK")
            }
        }

        if diffs.isEmpty {
            print("\n✓ All verifications passed.")
        } else {
            throw CLIError.verificationFailed(diffs: diffs)
        }
    }

    /// Produce a short human-readable diff description.
    static func diffDescription(original: String, roundTripped: String, label: String) -> String {
        let origLines = original.components(separatedBy: "\n")
        let rtLines = roundTripped.components(separatedBy: "\n")
        var lines: [String] = ["  Diff (\(label)):"]

        let maxLines = max(origLines.count, rtLines.count)
        var diffCount = 0
        for i in 0..<maxLines {
            let orig = i < origLines.count ? origLines[i] : "<missing>"
            let rt   = i < rtLines.count   ? rtLines[i]   : "<missing>"
            if orig != rt {
                lines.append("  Line \(i + 1):")
                lines.append("  - \(orig)")
                lines.append("  + \(rt)")
                diffCount += 1
                if diffCount >= 5 {
                    let remaining = maxLines - i - 1
                    if remaining > 0 {
                        lines.append("  ... (\(remaining) more line(s) differ)")
                    }
                    break
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Lexicon commands

    /// Dispatcher for `gikh lexicon --add|--scan|--suggest`.
    static func lexicon(args: [String]) throws {
        guard let flag = args.first else {
            print("Usage: gikh lexicon --add <english> <yiddish>")
            print("       gikh lexicon --scan <dir>")
            print("       gikh lexicon --suggest [--from-scan <dir>]")
            return
        }

        switch flag {
        case "--add":
            try lexiconAdd(args: Array(args.dropFirst()))
        case "--scan":
            try lexiconScan(args: Array(args.dropFirst()))
        case "--suggest":
            try lexiconSuggest(args: Array(args.dropFirst()))
        default:
            throw CLIError.lexiconError("Unknown lexicon flag: \(flag). Use --add, --scan, or --suggest.")
        }
    }

    // MARK: - gikh lexicon --add

    /// `gikh lexicon --add <english> <yiddish>`
    /// Adds a new entry to the project's לעקסיקאָן.yaml, validating bijectivity
    /// against the merged dictionary (tiers 1-3).
    static func lexiconAdd(args: [String]) throws {
        guard args.count >= 2 else {
            throw CLIError.lexiconError("Usage: gikh lexicon --add <english> <yiddish>")
        }

        let english = args[0]
        let yiddish = args[1]
        let lexiconPath = "./לעקסיקאָן.yaml"
        let bibliotekPath = findBibliotekSourcePath()

        // Load existing project identifiers
        let existingPairs = loadExistingPairs(from: lexiconPath)

        // Build the merged lexicon to check collisions
        let keywords = SwiftKeywords.keywordsMap
        let bibliotek = try Lexicon.deriveBibliotekMappings(from: bibliotekPath)

        // Check if this new pair collides with keywords
        if keywords.toValue(yiddish) != nil || keywords.toKey(english) != nil {
            let existing = keywords.toValue(yiddish).map { "'\(yiddish)' → '\($0)'" }
                        ?? keywords.toKey(english).map { "'\($0)' → '\(english)'" }
                        ?? ""
            throw CLIError.lexiconError(
                "Collision with keywords tier: \(english) ↔ \(yiddish) conflicts with \(existing)"
            )
        }

        // Check if this new pair collides with bibliotek
        if bibliotek.toValue(yiddish) != nil || bibliotek.toKey(english) != nil {
            let existing = bibliotek.toValue(yiddish).map { "'\(yiddish)' → '\($0)'" }
                        ?? bibliotek.toKey(english).map { "'\($0)' → '\(english)'" }
                        ?? ""
            throw CLIError.lexiconError(
                "Collision with ביבליאָטעק tier: \(english) ↔ \(yiddish) conflicts with \(existing)"
            )
        }

        // Check if this new pair collides with existing project identifiers
        for (existY, existE) in existingPairs {
            if existY == yiddish {
                throw CLIError.lexiconError(
                    "Collision in project lexicon: '\(yiddish)' is already mapped to '\(existE)'"
                )
            }
            if existE == english {
                throw CLIError.lexiconError(
                    "Collision in project lexicon: '\(english)' is already mapped from '\(existY)'"
                )
            }
        }

        // Append to לעקסיקאָן.yaml (create if not exists)
        try appendToLexicon(yiddish: yiddish, english: english, path: lexiconPath)
        print("Added: \(yiddish) ↔ \(english) to \(lexiconPath)")
    }

    /// Load existing (yiddish, english) pairs from the project lexicon without full validation.
    static func loadExistingPairs(from path: String) -> [(String, String)] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return []
        }
        return Lexicon.parseYAMLIdentifiers(content)
    }

    /// Append a new yiddish: english entry to the project lexicon YAML.
    /// Creates the file with proper structure if it does not exist.
    static func appendToLexicon(yiddish: String, english: String, path: String) throws {
        let fm = FileManager.default

        if !fm.fileExists(atPath: path) {
            // Create fresh lexicon file
            let content = """
                tier: project

                identifiers:
                  \(yiddish): \(english)
                """
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            return
        }

        // Append to existing file
        var existing = try String(contentsOfFile: path, encoding: .utf8)

        // Ensure file ends with newline
        if !existing.hasSuffix("\n") {
            existing += "\n"
        }

        // Check if identifiers section exists; if not, append it
        if !existing.contains("identifiers:") {
            existing += "\nidentifiers:\n"
        }

        existing += "  \(yiddish): \(english)\n"
        try existing.write(toFile: path, atomically: true, encoding: .utf8)
    }

    // MARK: - gikh lexicon --scan

    /// `gikh lexicon --scan <dir>`
    /// Finds untranslated identifiers in .gikh source files.
    /// Tokenises each file, checks identifiers against the merged dictionary,
    /// and reports untranslated symbols grouped by file.
    static func lexiconScan(args: [String]) throws {
        guard let dir = args.first else {
            throw CLIError.lexiconError("Usage: gikh lexicon --scan <directory>")
        }

        let bibliotekPath = findBibliotekSourcePath()
        let developerLexicon: Lexicon
        do {
            developerLexicon = try Lexicon.forDeveloper(
                bibliotekPath: bibliotekPath,
                projectPath: "./לעקסיקאָן.yaml"
            )
        } catch {
            developerLexicon = try Lexicon.forCompilation(bibliotekPath: bibliotekPath)
        }

        let gikhFiles = try collectGikhFiles(from: [dir])

        if gikhFiles.isEmpty {
            print("No .gikh files found in \(dir).")
            return
        }

        var totalUntranslated = 0
        var filesWithUntranslated = 0

        for file in gikhFiles.sorted() {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            var scanner = GikhCore.Scanner(source: content)
            let tokens = scanner.scan()

            // Find identifiers not in any dictionary tier
            var untranslated: [String] = []
            var seen: Set<String> = []

            for token in tokens {
                guard case .identifier(let name, _) = token else { continue }
                guard !seen.contains(name) else { continue }
                seen.insert(name)

                // Check if it's in any dictionary tier (Yiddish side)
                let inKeywords   = developerLexicon.keywords.toValue(name) != nil
                let inBibliotek  = developerLexicon.bibliotek.toValue(name) != nil
                let inIdentifiers = developerLexicon.identifiers.toValue(name) != nil

                // Also check the English side (for Mode C / hybrid files)
                let inKeywordsE   = developerLexicon.keywords.toKey(name) != nil
                let inBibliotekE  = developerLexicon.bibliotek.toKey(name) != nil
                let inIdentifiersE = developerLexicon.identifiers.toKey(name) != nil

                let covered = inKeywords || inBibliotek || inIdentifiers
                           || inKeywordsE || inBibliotekE || inIdentifiersE

                if !covered {
                    untranslated.append(name)
                }
            }

            if !untranslated.isEmpty {
                filesWithUntranslated += 1
                totalUntranslated += untranslated.count
                print("\(file):")
                for name in untranslated.sorted() {
                    print("  \(name)  →  ?")
                }
                print()
            }
        }

        if totalUntranslated == 0 {
            print("✓ All identifiers in \(gikhFiles.count) file(s) are covered by the dictionary.")
        } else {
            print("Found \(totalUntranslated) untranslated identifier(s) in \(filesWithUntranslated) file(s).")
            print("Run 'gikh lexicon --suggest' to get translation proposals.")
        }
    }

    // MARK: - gikh lexicon --suggest

    /// `gikh lexicon --suggest [--from-scan <dir>]`
    /// Proposes translations from the common-words.yaml (Dictionary 4).
    /// Interactive: presents proposals for user review.
    /// Only approved translations are added.
    static func lexiconSuggest(args: [String]) throws {
        var scanDir: String? = nil
        var i = 0
        while i < args.count {
            if args[i] == "--from-scan", i + 1 < args.count {
                scanDir = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        }

        // Load the common-words dictionary
        let commonWords = loadCommonWords()
        if commonWords.isEmpty {
            print("No common-words.yaml found. Cannot suggest translations.")
            return
        }

        let bibliotekPath = findBibliotekSourcePath()
        let developerLexicon: Lexicon
        do {
            developerLexicon = try Lexicon.forDeveloper(
                bibliotekPath: bibliotekPath,
                projectPath: "./לעקסיקאָן.yaml"
            )
        } catch {
            developerLexicon = try Lexicon.forCompilation(bibliotekPath: bibliotekPath)
        }

        // If --from-scan specified, find untranslated identifiers first
        var candidates: [String] = []
        if let dir = scanDir {
            let gikhFiles = try collectGikhFiles(from: [dir])
            for file in gikhFiles {
                let content = try String(contentsOfFile: file, encoding: .utf8)
                var scanner = GikhCore.Scanner(source: content)
                let tokens = scanner.scan()
                for token in tokens {
                    guard case .identifier(let name, _) = token else { continue }
                    let covered = developerLexicon.keywords.toValue(name) != nil
                              || developerLexicon.bibliotek.toValue(name) != nil
                              || developerLexicon.identifiers.toValue(name) != nil
                              || developerLexicon.keywords.toKey(name) != nil
                              || developerLexicon.bibliotek.toKey(name) != nil
                              || developerLexicon.identifiers.toKey(name) != nil
                    if !covered && !candidates.contains(name) {
                        candidates.append(name)
                    }
                }
            }
        } else {
            // Without --from-scan, propose everything in common-words not yet covered
            candidates = commonWords.keys.filter { english in
                developerLexicon.keywords.toKey(english) == nil
                    && developerLexicon.bibliotek.toKey(english) == nil
                    && developerLexicon.identifiers.toKey(english) == nil
            }.sorted()
        }

        if candidates.isEmpty {
            print("No untranslated identifiers found to suggest translations for.")
            return
        }

        // Build proposals: match candidates against common-words
        var proposals: [(english: String, yiddish: String)] = []
        for candidate in candidates {
            if let yiddish = commonWords[candidate] {
                proposals.append((english: candidate, yiddish: yiddish))
            }
        }

        if proposals.isEmpty {
            print("No matches found in common-words dictionary for the untranslated identifiers.")
            print("Consider adding custom translations with 'gikh lexicon --add <english> <yiddish>'.")
            return
        }

        // Interactive review
        print("Proposed translations (\(proposals.count) suggestion(s)):")
        print("For each proposal: [y]es / [n]o / [e]dit / [a]ll / [q]uit\n")

        var approved: [(english: String, yiddish: String)] = []

        for (index, proposal) in proposals.enumerated() {
            print("[\(index + 1)/\(proposals.count)] \(proposal.english)  →  \(proposal.yiddish)")
            print("  [y/n/e/a/q]: ", terminator: "")

            guard let line = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
                break
            }

            switch line {
            case "y", "yes", "":
                approved.append(proposal)
                print("  Approved.")
            case "a", "all":
                // Approve this and all remaining
                approved.append(proposal)
                for remaining in proposals[(index + 1)...] {
                    approved.append(remaining)
                }
                print("  Approved all remaining \(proposals.count - index) proposal(s).")
                break
            case "e", "edit":
                print("  Enter Yiddish translation for '\(proposal.english)': ", terminator: "")
                if let edited = readLine()?.trimmingCharacters(in: .whitespaces), !edited.isEmpty {
                    approved.append((english: proposal.english, yiddish: edited))
                    print("  Approved (edited): \(proposal.english)  →  \(edited)")
                } else {
                    print("  Skipped (no input).")
                }
            case "q", "quit":
                print("  Quitting suggestion review.")
                break
            default:
                print("  Skipped.")
            }
        }

        if approved.isEmpty {
            print("\nNo translations approved.")
            return
        }

        // Add approved translations to the project lexicon
        let lexiconPath = "./לעקסיקאָן.yaml"
        for proposal in approved {
            do {
                try lexiconAdd(args: [proposal.english, proposal.yiddish])
            } catch {
                print("  Skipped '\(proposal.english)': \(error)")
            }
        }

        print("\n✓ Added \(approved.count) approved translation(s) to \(lexiconPath).")
    }

    /// Load the common-words.yaml dictionary bundled with Gikh.
    /// Returns a dict mapping English → Yiddish.
    static func loadCommonWords() -> [String: String] {
        // Look for common-words.yaml relative to the executable or source
        let candidates = [
            findDictionaryPath(name: "common-words.yaml"),
            "./Dictionaries/common-words.yaml",
            "../Dictionaries/common-words.yaml",
        ].compactMap { $0 }

        for path in candidates {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                return parseCommonWords(content)
            }
        }
        return [:]
    }

    /// Find a dictionary file relative to the executable.
    static func findDictionaryPath(name: String) -> String? {
        let execURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let candidates = [
            execURL.deletingLastPathComponent()
                .appendingPathComponent("../../Dictionaries/\(name)").path,
            execURL.deletingLastPathComponent()
                .appendingPathComponent("../../../Dictionaries/\(name)").path,
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }

    /// Parse common-words.yaml (format: `english: yiddish` under `words:`).
    static func parseCommonWords(_ yaml: String) -> [String: String] {
        var result: [String: String] = [:]
        var inWords = false

        for line in yaml.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "words:" || trimmed.hasPrefix("words:") {
                inWords = true
                continue
            }

            if inWords && !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let hasLeadingWhitespace = line.first == " " || line.first == "\t"
                if !hasLeadingWhitespace {
                    inWords = false
                    continue
                }
            }

            guard inWords else { continue }
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }

            guard let colonIdx = trimmed.firstIndex(of: ":") else { continue }
            let english = String(trimmed[trimmed.startIndex..<colonIdx])
                .trimmingCharacters(in: .whitespaces)
            let yiddish = String(trimmed[trimmed.index(after: colonIdx)...])
                .trimmingCharacters(in: .whitespaces)

            guard !english.isEmpty, !yiddish.isEmpty else { continue }
            result[english] = yiddish
        }

        return result
    }

    // MARK: - Bridge command

    /// `gikh bridge --generate`
    /// Regenerates ביבליאָטעק wrapper files from the approved translations
    /// in the project's לעקסיקאָן.yaml.
    static func bridge(args: [String]) throws {
        guard args.first == "--generate" else {
            print("Usage: gikh bridge --generate")
            return
        }

        let lexiconPath = "./לעקסיקאָן.yaml"
        let pairs = loadExistingPairs(from: lexiconPath)

        if pairs.isEmpty {
            print("No approved translations found in \(lexiconPath).")
            print("Run 'gikh lexicon --add' or 'gikh lexicon --suggest' to add translations.")
            return
        }

        let outputDir = "./ביבליאָטעק/פּראָיעקט"
        let fm = FileManager.default
        try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        // Generate a single Swift file with typealias declarations for each translation
        var lines: [String] = [
            "// Auto-generated by `gikh bridge --generate`",
            "// Do not edit manually — run `gikh bridge --generate` to regenerate.",
            "// Source: \(lexiconPath)",
            "",
            "import Foundation",
            "",
        ]

        for (yiddish, english) in pairs.sorted(by: { $0.0 < $1.0 }) {
            lines.append("public typealias \(yiddish) = \(english)")
        }

        lines.append("")

        let outputPath = "\(outputDir)/איבערזעצונגען.swift"
        let content = lines.joined(separator: "\n")
        try content.write(toFile: outputPath, atomically: true, encoding: .utf8)

        print("Generated \(pairs.count) typealias declaration(s) → \(outputPath)")
        print("\nContents:")
        print(content)
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

    /// Collect only .swift files from the given paths.
    static func collectSwiftFiles(from paths: [String]) throws -> [String] {
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
                        if file.hasSuffix(".swift") {
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
