// Lexicon.swift
// GikhCore — Loads and merges dictionaries for the transpiler.

import Foundation
import Yams

/// The merged dictionary stack used by the transpiler.
///
/// Holds three `BiMap`s representing the three active dictionary tiers:
/// 1. **Keywords** — compiled into the binary (Dictionary 1)
/// 2. **ביבליאָטעק** — derived from framework wrapper source files (Dictionary 2)
/// 3. **Identifiers** — per-project developer names (Dictionary 3)
///
/// Dictionary 4 (common words) is advisory only and never loaded here.
public struct Lexicon {
    public let keywords: BiMap<String, String>
    public let bibliotek: BiMap<String, String>
    public let identifiers: BiMap<String, String>

    public init(
        keywords: BiMap<String, String>,
        bibliotek: BiMap<String, String>,
        identifiers: BiMap<String, String>
    ) {
        self.keywords = keywords
        self.bibliotek = bibliotek
        self.identifiers = identifiers
    }

    // MARK: - Factory Methods

    /// Compiler workflow: keywords + bibliotek only (B → C).
    ///
    /// Project identifiers are not needed for compilation — the Yiddish identifiers
    /// pass through untranslated into Mode C, which is exactly what the compiler sees.
    public static func forCompilation(
        bibliotekMappings: BiMap<String, String> = BiMap()
    ) -> Lexicon {
        Lexicon(
            keywords: Keywords.dictionary,
            bibliotek: bibliotekMappings,
            identifiers: BiMap()
        )
    }

    /// Developer workflow: all dictionaries (A ↔ B).
    ///
    /// Validates bijectivity across the merged set of bibliotek and project identifiers,
    /// and checks that neither collides with the compiled-in keywords.
    public static func forDeveloper(
        bibliotekMappings: BiMap<String, String> = BiMap(),
        projectIdentifiers: BiMap<String, String> = BiMap()
    ) throws -> Lexicon {
        // Merge bibliotek and project identifiers, checking for inter-tier collisions.
        let merged = try bibliotekMappings.merged(with: projectIdentifiers)

        // Verify no collisions with the keyword tier.
        for (key, value) in merged.allPairs {
            if Keywords.dictionary.toValue(key) != nil {
                throw LexiconError.collision(
                    "Project identifier '\(key)' collides with keyword"
                )
            }
            if Keywords.dictionary.toKey(value) != nil {
                throw LexiconError.collision(
                    "Project identifier value '\(value)' collides with keyword"
                )
            }
        }

        return Lexicon(
            keywords: Keywords.dictionary,
            bibliotek: bibliotekMappings,
            identifiers: projectIdentifiers
        )
    }

    // MARK: - YAML Loading

    /// Loads project identifiers from a YAML file (לעקסיקאָן.yaml).
    ///
    /// Expected format:
    /// ```yaml
    /// tier: project
    /// identifiers:
    ///   יידיש_ווערט: english_value
    /// ```
    public static func loadProjectIdentifiers(
        from path: String
    ) throws -> BiMap<String, String> {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw LexiconError.fileNotFound(
                "Project dictionary not found at \(path)"
            )
        }

        let yamlString: String
        do {
            yamlString = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw LexiconError.invalidFormat(
                "Could not read \(path): \(error.localizedDescription)"
            )
        }

        let projectLexicon: ProjectLexicon
        do {
            let decoder = YAMLDecoder()
            projectLexicon = try decoder.decode(ProjectLexicon.self, from: yamlString)
        } catch {
            throw LexiconError.invalidFormat(
                "Invalid YAML in \(path): \(error.localizedDescription)"
            )
        }

        return BiMap(projectLexicon.identifiers.map { ($0.key, $0.value) })
    }

    // MARK: - Lookup

    /// Looks up a word across all tiers: keywords → bibliotek → identifiers.
    ///
    /// Returns the translation, or `nil` if the word is not in any dictionary
    /// (in which case it passes through untranslated).
    public func translate(_ word: String, direction: Direction) -> String? {
        let maps = [keywords, bibliotek, identifiers]
        for map in maps {
            switch direction {
            case .toEnglish:
                if let v = map.toValue(word) { return v }
            case .toYiddish:
                if let v = map.toKey(word) { return v }
            }
        }
        return nil
    }
}

// MARK: - Supporting Types

/// Errors from dictionary loading and merging.
public enum LexiconError: Error, LocalizedError {
    /// A mapping in one tier collides with a mapping in another tier.
    case collision(String)
    /// A dictionary file has invalid or unparseable content.
    case invalidFormat(String)
    /// A dictionary file does not exist at the expected path.
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .collision(let msg): return "Dictionary collision: \(msg)"
        case .invalidFormat(let msg): return "Invalid dictionary format: \(msg)"
        case .fileNotFound(let msg): return "Dictionary file not found: \(msg)"
        }
    }
}

/// Codable representation of a project dictionary YAML file (לעקסיקאָן.yaml).
struct ProjectLexicon: Codable {
    let tier: String
    let identifiers: [String: String]
}
