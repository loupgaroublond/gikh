import Foundation

// MARK: - ExtractedSymbol

/// A symbol extracted from a Swift source file or .swiftinterface file.
public struct ExtractedSymbol: Equatable, Sendable {
    public let name: String
    public let module: String
    public let kind: SymbolKind

    public init(name: String, module: String, kind: SymbolKind) {
        self.name = name
        self.module = module
        self.kind = kind
    }
}

/// The kind of a Swift symbol.
public enum SymbolKind: Equatable, Sendable {
    case type       // struct, class, enum, actor, typealias
    case function   // func
    case property   // var, let (stored/computed properties)
    case `protocol` // protocol
    case enumCase   // case
    case keyword    // Swift keyword
    case other
}

// MARK: - CoverageResult

/// The result of checking a symbol against the dictionary.
public enum CoverageResult: Equatable, Sendable {
    case covered(yiddish: String)
    case untranslated
}

// MARK: - ScanReport

/// The output of a full scan run.
public struct ScanReport: Sendable {
    public let projectName: String
    public let covered: Int
    public let total: Int
    public let uncoveredByModule: [String: [ExtractedSymbol]]

    public init(
        projectName: String,
        covered: Int,
        total: Int,
        uncoveredByModule: [String: [ExtractedSymbol]]
    ) {
        self.projectName = projectName
        self.covered = covered
        self.total = total
        self.uncoveredByModule = uncoveredByModule
    }

    public var coveragePercent: Double {
        guard total > 0 else { return 100.0 }
        return Double(covered) / Double(total) * 100.0
    }
}

// MARK: - SymbolExtractor

/// Extracts symbols from Swift source code or .swiftinterface files.
public enum SymbolExtractor {

    /// Extract symbols from a Swift source string.
    /// Uses the Scanner to tokenize and identify declarations.
    public static func extractFromSource(
        _ source: String,
        moduleName: String
    ) -> [ExtractedSymbol] {
        var symbols: [ExtractedSymbol] = []
        var scanner = Scanner(source: source)
        let tokens = scanner.scan()

        // Walk token stream looking for declaration keywords followed by identifiers
        var i = 0
        while i < tokens.count {
            let token = tokens[i]

            switch token {
            case .keyword(let kw, _):
                let kind: SymbolKind?
                switch kw {
                case "struct", "class", "enum", "actor", "typealias":
                    kind = .type
                case "func":
                    kind = .function
                case "protocol":
                    kind = .protocol
                case "var", "let":
                    kind = .property
                default:
                    kind = nil
                }

                if let k = kind, i + 1 < tokens.count {
                    // Skip whitespace
                    var j = i + 1
                    while j < tokens.count, case .whitespace = tokens[j] { j += 1 }
                    if j < tokens.count, case .identifier(let name, _) = tokens[j] {
                        if !name.isEmpty {
                            symbols.append(ExtractedSymbol(name: name, module: moduleName, kind: k))
                        }
                    }
                }

            case .identifier(let name, _):
                // Also collect identifiers that represent type usages
                if !name.isEmpty && name.first?.isUppercase == true {
                    symbols.append(ExtractedSymbol(name: name, module: moduleName, kind: .type))
                }

            default:
                break
            }

            i += 1
        }

        // Deduplicate by name
        var seen: Set<String> = []
        return symbols.filter { seen.insert($0.name).inserted }
    }

    /// Extract symbols from a .swiftinterface file string.
    public static func extractFromInterface(
        _ interface: String,
        moduleName: String
    ) -> [ExtractedSymbol] {
        SwiftInterfaceParser.parse(interface, moduleName: moduleName)
    }
}

// MARK: - SwiftInterfaceParser

/// Parses .swiftinterface files to extract symbol declarations.
public enum SwiftInterfaceParser {

    /// Parse a .swiftinterface file string and extract top-level symbol declarations.
    public static func parse(_ source: String, moduleName: String) -> [ExtractedSymbol] {
        var symbols: [ExtractedSymbol] = []
        var seen: Set<String> = []

        for line in source.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            guard !trimmed.isEmpty && !trimmed.hasPrefix("//") && !trimmed.hasPrefix("@") else {
                continue
            }

            if let sym = parseDeclLine(trimmed, moduleName: moduleName) {
                if seen.insert(sym.name).inserted {
                    symbols.append(sym)
                }
            }
        }

        return symbols
    }

    /// Find all .swiftinterface files in a directory (recursively).
    public static func findInterfaceFiles(in directoryPath: String) -> [String] {
        guard let enumerator = FileManager.default.enumerator(atPath: directoryPath) else {
            return []
        }
        var files: [String] = []
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swiftinterface") {
                files.append((directoryPath as NSString).appendingPathComponent(file))
            }
        }
        return files
    }

    /// Parse a single declaration line.
    private static func parseDeclLine(_ line: String, moduleName: String) -> ExtractedSymbol? {
        // Strip access modifiers: public, open, internal, private, fileprivate
        // NOTE: "class" is NOT stripped here because it's also a declaration keyword.
        var rest = line
        for mod in ["public ", "open ", "internal ", "private ", "fileprivate ",
                    "final ", "static ", "mutating ", "nonmutating ",
                    "override ", "required ", "convenience ", "indirect "] {
            while rest.hasPrefix(mod) {
                rest = String(rest.dropFirst(mod.count))
            }
        }

        // Determine kind from declaration keyword
        let declPrefixes: [(String, SymbolKind)] = [
            ("struct ", .type),
            ("class ", .type),
            ("enum ", .type),
            ("actor ", .type),
            ("typealias ", .type),
            ("protocol ", .protocol),
            ("func ", .function),
            ("var ", .property),
            ("let ", .property),
            ("case ", .enumCase),
        ]

        for (prefix, kind) in declPrefixes {
            if rest.hasPrefix(prefix) {
                let afterKw = String(rest.dropFirst(prefix.count))
                // Extract name: everything up to whitespace, (, {, :, <
                let name = extractName(from: afterKw)
                guard !name.isEmpty else { return nil }
                return ExtractedSymbol(name: name, module: moduleName, kind: kind)
            }
        }

        return nil
    }

    /// Extract the symbol name from the rest of a declaration line.
    private static func extractName(from text: String) -> String {
        var name = ""
        for ch in text {
            if ch.isLetter || ch.isNumber || ch == "_" { name.append(ch) }
            else { break }
        }
        return name
    }
}

// MARK: - CoverageChecker

/// Checks extracted symbols against the merged Lexicon.
public struct CoverageChecker {
    public let lexicon: Lexicon

    public init(lexicon: Lexicon) {
        self.lexicon = lexicon
    }

    /// Check a single symbol against the lexicon.
    public func check(_ symbol: ExtractedSymbol) -> CoverageResult {
        let name = symbol.name
        guard !name.isEmpty else { return .untranslated }

        // Check keywords (by English name → Yiddish)
        if let yiddish = lexicon.keywords.toKey(name) {
            return .covered(yiddish: yiddish)
        }

        // Check bibliotek (English → Yiddish)
        if let yiddish = lexicon.bibliotek.toKey(name) {
            return .covered(yiddish: yiddish)
        }

        // Check identifiers (English → Yiddish)
        if let yiddish = lexicon.identifiers.toKey(name) {
            return .covered(yiddish: yiddish)
        }

        return .untranslated
    }

    /// Build a full coverage report from a symbol list.
    public func buildReport(symbols: [ExtractedSymbol], projectName: String) -> ScanReport {
        var covered = 0
        var total = 0
        var uncoveredByModule: [String: [ExtractedSymbol]] = [:]

        for symbol in symbols {
            guard !symbol.name.isEmpty else { continue }
            total += 1

            switch check(symbol) {
            case .covered:
                covered += 1
            case .untranslated:
                let mod = symbol.module.isEmpty ? "Unknown" : symbol.module
                uncoveredByModule[mod, default: []].append(symbol)
            }
        }

        return ScanReport(
            projectName: projectName,
            covered: covered,
            total: total,
            uncoveredByModule: uncoveredByModule
        )
    }
}

// MARK: - ScanOutputFormat

public enum ScanOutputFormat: String, Sendable {
    case table
    case yaml
    case diff
}

// MARK: - ScanOutputFormatter

/// Formats scan reports in table, YAML, or diff format.
public enum ScanOutputFormatter {

    public static func format(_ report: ScanReport, format: ScanOutputFormat) -> String {
        switch format {
        case .table: return formatTable(report)
        case .yaml:  return formatYAML(report)
        case .diff:  return formatDiff(report)
        }
    }

    // MARK: - Table format

    private static func formatTable(_ report: ScanReport) -> String {
        var out = ""
        let pct = String(format: "%.1f", report.coveragePercent)
        out += "Scanning \(report.projectName)...\n"
        out += "\nCoverage: \(report.covered)/\(report.total) (\(pct)%)\n"

        if report.uncoveredByModule.isEmpty {
            out += "\nAll symbols covered!\n"
            return out
        }

        out += "\nUntranslated symbols by module:\n"
        let sortedModules = report.uncoveredByModule.keys.sorted()
        for mod in sortedModules {
            let syms = report.uncoveredByModule[mod] ?? []
            out += "\n  \(mod) (\(syms.count) uncovered):\n"
            for sym in syms.sorted(by: { $0.name < $1.name }) {
                let padding = String(repeating: " ", count: max(0, 30 - sym.name.count))
                out += "    \(sym.name)\(padding) → ?\n"
            }
        }
        return out
    }

    // MARK: - YAML format

    private static func formatYAML(_ report: ScanReport) -> String {
        var out = ""
        out += "project: \(report.projectName)\n"
        out += "coverage:\n"
        out += "  covered: \(report.covered)\n"
        out += "  total: \(report.total)\n"
        out += "  percent: \(String(format: "%.1f", report.coveragePercent))\n"
        out += "untranslated:\n"

        let sortedModules = report.uncoveredByModule.keys.sorted()
        for mod in sortedModules {
            let syms = report.uncoveredByModule[mod] ?? []
            out += "  \(mod):\n"
            for sym in syms.sorted(by: { $0.name < $1.name }) {
                out += "    - \(sym.name)\n"
            }
        }
        return out
    }

    // MARK: - Diff format

    private static func formatDiff(_ report: ScanReport) -> String {
        var out = ""
        let sortedModules = report.uncoveredByModule.keys.sorted()
        for mod in sortedModules {
            let syms = report.uncoveredByModule[mod] ?? []
            for sym in syms.sorted(by: { $0.name < $1.name }) {
                out += "+ \(sym.name) (\(mod)) → ?\n"
            }
        }
        return out
    }
}

// MARK: - SDK Version Diffing

/// Represents the difference between two SDK versions' symbol sets.
public struct SymbolDiff: Sendable {
    public let added: [ExtractedSymbol]
    public let removed: [ExtractedSymbol]

    public init(added: [ExtractedSymbol], removed: [ExtractedSymbol]) {
        self.added = added
        self.removed = removed
    }
}

/// The coverage impact report for an SDK diff.
public struct DiffCoverageReport: Sendable {
    public let coveredAdded: Int
    public let uncoveredAdded: Int
    public let removed: [ExtractedSymbol]

    public init(coveredAdded: Int, uncoveredAdded: Int, removed: [ExtractedSymbol]) {
        self.coveredAdded = coveredAdded
        self.uncoveredAdded = uncoveredAdded
        self.removed = removed
    }
}

/// Tools for comparing SDK versions and identifying new symbols.
public enum SDKVersionDiff {

    /// Diff two symbol lists: returns added and removed symbols.
    public static func diff(
        from v1: [ExtractedSymbol],
        to v2: [ExtractedSymbol]
    ) -> SymbolDiff {
        let v1Names = Set(v1.map(\.name))
        let v2Names = Set(v2.map(\.name))

        let addedNames = v2Names.subtracting(v1Names)
        let removedNames = v1Names.subtracting(v2Names)

        let added = v2.filter { addedNames.contains($0.name) }
        let removed = v1.filter { removedNames.contains($0.name) }

        return SymbolDiff(added: added, removed: removed)
    }

    /// Build a coverage impact report for the added symbols in a diff.
    public static func coverageReport(
        for diff: SymbolDiff,
        lexicon: Lexicon
    ) -> DiffCoverageReport {
        let checker = CoverageChecker(lexicon: lexicon)
        var covered = 0
        var uncovered = 0

        for sym in diff.added {
            switch checker.check(sym) {
            case .covered: covered += 1
            case .untranslated: uncovered += 1
            }
        }

        return DiffCoverageReport(
            coveredAdded: covered,
            uncoveredAdded: uncovered,
            removed: diff.removed
        )
    }
}

// MARK: - Lexicon Suggest

/// Represents a translation suggestion for an untranslated symbol.
public struct TranslationSuggestion: Sendable {
    public let symbol: ExtractedSymbol
    public let proposedYiddish: String?

    public init(symbol: ExtractedSymbol, proposedYiddish: String?) {
        self.symbol = symbol
        self.proposedYiddish = proposedYiddish
    }
}

/// Grouped suggestions for framework and project symbols.
public struct SuggestionsResult: Sendable {
    public let frameworkSymbols: [TranslationSuggestion]
    public let projectSymbols: [TranslationSuggestion]

    public init(frameworkSymbols: [TranslationSuggestion], projectSymbols: [TranslationSuggestion]) {
        self.frameworkSymbols = frameworkSymbols
        self.projectSymbols = projectSymbols
    }
}

/// Integrates scan output with the common-words dictionary to propose translations.
public enum LexiconSuggest {

    /// The main app module name used to identify project symbols vs framework symbols.
    /// In practice this is derived from the project name.
    private static let knownFrameworkModules: Set<String> = [
        "Foundation", "Swift", "SwiftUI", "UIKit", "AppKit", "CoreData",
        "CoreGraphics", "CoreLocation", "MapKit", "Combine", "Charts",
        "SwiftData", "AVFoundation", "UserNotifications", "XCTest",
        "ArgumentParser", "CryptoKit", "Security", "WebKit", "GameKit",
        "CloudKit", "StoreKit", "CoreBluetooth", "CoreNFC", "ARKit",
        "RealityKit", "Vision", "CreateML", "CoreML", "NaturalLanguage",
        "AuthenticationServices", "LocalAuthentication",
    ]

    /// Generate translation suggestions for untranslated symbols.
    ///
    /// - Parameters:
    ///   - uncovered: symbols that are not in any dictionary tier
    ///   - commonWords: the common-words reference dictionary (English → Yiddish)
    public static func suggest(
        for uncovered: [ExtractedSymbol],
        commonWords: [String: String]
    ) -> SuggestionsResult {
        var framework: [TranslationSuggestion] = []
        var project: [TranslationSuggestion] = []

        for sym in uncovered {
            let proposed = commonWords[sym.name.lowercased()]
                ?? findPartialMatch(name: sym.name, in: commonWords)

            let suggestion = TranslationSuggestion(symbol: sym, proposedYiddish: proposed)

            if knownFrameworkModules.contains(sym.module) {
                framework.append(suggestion)
            } else {
                project.append(suggestion)
            }
        }

        return SuggestionsResult(frameworkSymbols: framework, projectSymbols: project)
    }

    /// Try to find a partial match by splitting CamelCase names into components.
    private static func findPartialMatch(
        name: String,
        in dictionary: [String: String]
    ) -> String? {
        // Direct lookup (case-insensitive)
        if let match = dictionary[name.lowercased()] { return match }

        // Try splitting on underscores
        let underscoreParts = name.components(separatedBy: "_")
        if underscoreParts.count > 1 {
            let parts = underscoreParts.compactMap { dictionary[$0.lowercased()] }
            if !parts.isEmpty { return parts.joined(separator: "_") }
        }

        return nil
    }
}
