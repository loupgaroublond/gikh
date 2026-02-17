// CodebaseScanner.swift
// ScanPipeline — Analyzes external Swift codebases for translation coverage.

import Foundation
import GikhCore

/// Scans a directory of Swift files and reports which symbols have translations
/// in the lexicon and which still need Yiddish equivalents.
///
/// This is a read-only analysis tool — it never modifies the scanned files.
public struct CodebaseScanner {
    public let lexicon: Lexicon

    public init(lexicon: Lexicon) {
        self.lexicon = lexicon
    }

    // MARK: - Scan Result

    /// The result of scanning a codebase for translation coverage.
    public struct ScanResult {
        /// Total number of unique identifiers found across all scanned files.
        public let totalSymbols: Int
        /// Number of identifiers that have a translation in the lexicon.
        public let coveredSymbols: Int
        /// Identifiers without translations, grouped by module/directory.
        public let untranslatedSymbols: [String: [String]]

        /// Translation coverage as a percentage (0.0–100.0).
        public var coveragePercent: Double {
            guard totalSymbols > 0 else { return 100.0 }
            return Double(coveredSymbols) / Double(totalSymbols) * 100.0
        }
    }

    // MARK: - Public API

    /// Scan a directory of Swift files and return a coverage report.
    ///
    /// Recursively enumerates all `.swift` and `.gikh` files under `directory`,
    /// tokenizes each file, extracts identifiers, and checks each one against
    /// the lexicon.
    ///
    /// - Parameter directory: Absolute path to the directory to scan.
    /// - Returns: A `ScanResult` with coverage statistics and untranslated symbol lists.
    /// - Throws: `ScanError.directoryNotFound` if the path does not exist or is not a directory.
    public func scan(directory: String) throws -> ScanResult {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: directory)

        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: directory, isDirectory: &isDir), isDir.boolValue else {
            throw ScanError.directoryNotFound(directory)
        }

        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil) else {
            throw ScanError.directoryNotFound(directory)
        }

        var allIdentifiers: Set<String> = []

        while let fileURL = enumerator.nextObject() as? URL {
            let ext = fileURL.pathExtension
            guard ext == "swift" || ext == "gikh" else { continue }

            let source: String
            do {
                source = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                throw ScanError.parseError(
                    "Could not read \(fileURL.path): \(error.localizedDescription)"
                )
            }

            var scanner = Scanner(source: source)
            let tokens = scanner.scan()

            for token in tokens {
                if case .identifier(let name, _) = token {
                    // Skip trivial identifiers: single characters and underscores.
                    guard name.count > 1, name != "_" else { continue }
                    allIdentifiers.insert(name)
                }
            }
        }

        var covered: Set<String> = []
        var untranslated: [String] = []

        for ident in allIdentifiers {
            if lexicon.translate(ident, direction: .toEnglish) != nil ||
               lexicon.translate(ident, direction: .toYiddish) != nil {
                covered.insert(ident)
            } else {
                untranslated.append(ident)
            }
        }

        return ScanResult(
            totalSymbols: allIdentifiers.count,
            coveredSymbols: covered.count,
            untranslatedSymbols: ["Project": untranslated.sorted()]
        )
    }
}

// MARK: - Errors

/// Errors produced by the codebase scanner.
public enum ScanError: Error, LocalizedError {
    /// The specified directory does not exist or is not a directory.
    case directoryNotFound(String)
    /// A file could not be read or parsed.
    case parseError(String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound(let p):
            return "Directory not found: \(p)"
        case .parseError(let msg):
            return "Parse error: \(msg)"
        }
    }
}
