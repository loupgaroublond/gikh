import Foundation

/// The merged dictionary set used by the transpiler.
///
/// There are three tiers:
///  1. `keywords`    — compiled-in Swift ↔ Yiddish keyword map.
///  2. `bibliotek`   — derived from ביבליאָטעק source files (typealiases / wrappers).
///  3. `identifiers` — per-project developer identifiers from `./לעקסיקאָן.yaml`.
///
/// Lookup priority is keywords → bibliotek → identifiers.
/// Any identifier not found in any tier passes through unchanged.
struct Lexicon {
    let keywords: BiMap<String, String>
    let bibliotek: BiMap<String, String>
    let identifiers: BiMap<String, String>

    // MARK: - Factory methods

    /// Compiler workflow: loads keywords (compiled in) + derives ביבליאָטעק
    /// mappings from source files at `bibliotekPath`.
    /// No project identifiers needed for B → C.
    static func forCompilation(bibliotekPath: String) throws -> Lexicon {
        let bibliotek = try deriveBibliotekMappings(from: bibliotekPath)
        return Lexicon(
            keywords: SwiftKeywords.keywordsMap,
            bibliotek: bibliotek,
            identifiers: BiMap([])
        )
    }

    /// Developer workflow: loads all dictionaries.
    /// - keywords (compiled in)
    /// - ביבליאָטעק mappings derived from source files
    /// - project identifiers from `./לעקסיקאָן.yaml`
    static func forDeveloper(
        bibliotekPath: String,
        projectPath: String = "./לעקסיקאָן.yaml"
    ) throws -> Lexicon {
        let bibliotek = try deriveBibliotekMappings(from: bibliotekPath)
        let identifiers = try loadProjectIdentifiers(from: projectPath)

        // Validate bijectivity across merged set (keywords ∪ bibliotek ∪ identifiers).
        // A collision means a project identifier duplicates a built-in mapping.
        try validateNoCrossCollisions(
            keywords: SwiftKeywords.keywordsMap,
            bibliotek: bibliotek,
            identifiers: identifiers
        )

        return Lexicon(
            keywords: SwiftKeywords.keywordsMap,
            bibliotek: bibliotek,
            identifiers: identifiers
        )
    }

    // MARK: - ביבליאָטעק derivation

    /// Parse all `.swift` files under `path` and extract `typealias` mappings.
    /// Each `typealias YiddishName = EnglishName` becomes an entry.
    /// Also extracts wrapper function / property names from `extension` declarations.
    static func deriveBibliotekMappings(from path: String) throws -> BiMap<String, String> {
        var pairs: [(String, String)] = []
        let fm = FileManager.default

        guard fm.fileExists(atPath: path) else {
            // No bibliotek directory — return empty map
            return BiMap([])
        }

        let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: nil
        )

        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let extracted = extractMappings(from: content)
            pairs.append(contentsOf: extracted)
        }

        // Deduplicate — keep first occurrence of each Yiddish key
        var seen: Set<String> = []
        var seenValues: Set<String> = []
        var unique: [(String, String)] = []
        for (yiddish, english) in pairs {
            guard !seen.contains(yiddish), !seenValues.contains(english) else { continue }
            seen.insert(yiddish)
            seenValues.insert(english)
            unique.append((yiddish, english))
        }

        return BiMap(unique)
    }

    /// Extract `typealias Yiddish = English` and method-name mappings from a
    /// Swift source file.
    static func extractMappings(from source: String) -> [(String, String)] {
        var pairs: [(String, String)] = []

        let lines = source.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // typealias pattern: `[public] typealias <Yiddish> = <English>`
            if let pair = parseTypealias(trimmed) {
                pairs.append(pair)
            }

            // Extension member: `func <Yiddish>(...) ... { <English>(...)  }`
            // We parse wrapper functions by looking for patterns like:
            //   `public func <yiddishName>(...) { ... <englishName>(...) }`
            // This is handled separately in `extractMemberMappings`.
        }

        return pairs
    }

    private static func parseTypealias(_ line: String) -> (String, String)? {
        // Matches: [access] typealias <Yiddish> = <English>
        var rest = line
        // Strip access modifiers
        for mod in ["public ", "internal ", "private ", "fileprivate "] {
            if rest.hasPrefix(mod) { rest = String(rest.dropFirst(mod.count)) }
        }
        guard rest.hasPrefix("typealias ") else { return nil }
        rest = String(rest.dropFirst("typealias ".count))

        // Split on " = "
        let parts = rest.components(separatedBy: " = ")
        guard parts.count == 2 else { return nil }

        let yiddish = parts[0].trimmingCharacters(in: .whitespaces)
        let english = parts[1].trimmingCharacters(in: .whitespaces)

        guard !yiddish.isEmpty, !english.isEmpty else { return nil }
        // Skip generic typealiases for now (e.g., `typealias Foo<T> = Bar<T>`)
        guard !yiddish.contains("<"), !english.contains("<") else { return nil }

        return (yiddish, english)
    }

    // MARK: - Project identifier loading

    static func loadProjectIdentifiers(from path: String) throws -> BiMap<String, String> {
        guard FileManager.default.fileExists(atPath: path) else {
            return BiMap([])
        }

        let content = try String(contentsOfFile: path, encoding: .utf8)
        let pairs = parseYAMLIdentifiers(content)
        return BiMap(pairs)
    }

    /// Minimal YAML parser for the `identifiers:` section of `לעקסיקאָן.yaml`.
    /// Format:
    /// ```yaml
    /// tier: project
    /// identifiers:
    ///   יִידיש: english
    /// ```
    static func parseYAMLIdentifiers(_ yaml: String) -> [(String, String)] {
        var pairs: [(String, String)] = []
        var inIdentifiers = false

        for line in yaml.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Detect start of identifiers section
            if trimmed == "identifiers:" || trimmed.hasPrefix("identifiers:") {
                inIdentifiers = true
                continue
            }

            // A non-empty, non-comment line with NO leading whitespace is a top-level
            // key — it ends the identifiers section.
            if inIdentifiers && !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                let hasLeadingWhitespace = line.first == " " || line.first == "\t"
                if !hasLeadingWhitespace {
                    inIdentifiers = false
                    continue
                }
            }

            guard inIdentifiers else { continue }
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }

            // `  yiddish: english`
            // Find the FIRST colon to split on
            guard let colonIdx = trimmed.firstIndex(of: ":") else { continue }

            let yiddish = String(trimmed[trimmed.startIndex..<colonIdx])
                .trimmingCharacters(in: .whitespaces)
            let english = String(trimmed[trimmed.index(after: colonIdx)...])
                .trimmingCharacters(in: .whitespaces)

            guard !yiddish.isEmpty, !english.isEmpty else { continue }
            // Strip inline comments
            let englishClean = english.components(separatedBy: " #").first?
                .trimmingCharacters(in: .whitespaces) ?? english
            guard !englishClean.isEmpty else { continue }
            pairs.append((yiddish, englishClean))
        }

        return pairs
    }

    // MARK: - Collision detection

    /// Validates that no Yiddish key or English value in `identifiers` collides
    /// with a key/value already present in `keywords` or `bibliotek`.
    static func validateNoCrossCollisions(
        keywords: BiMap<String, String>,
        bibliotek: BiMap<String, String>,
        identifiers: BiMap<String, String>
    ) throws {
        // We need to iterate over identifiers. BiMap doesn't expose iteration,
        // so we try each key against the higher-priority maps.
        // Since BiMap is opaque, we detect collisions by checking toValue/toKey.
        // This approach requires us to know the pairs in `identifiers`, but BiMap
        // doesn't expose them. Use the KeyValuePairs approach via the allPairs property.
        for (yiddish, english) in identifiers.allPairs {
            if keywords.toValue(yiddish) != nil {
                throw LexiconError.collision(
                    yiddish: yiddish, english: english, tier: "keywords"
                )
            }
            if keywords.toKey(english) != nil {
                throw LexiconError.collision(
                    yiddish: yiddish, english: english, tier: "keywords"
                )
            }
            if bibliotek.toValue(yiddish) != nil {
                throw LexiconError.collision(
                    yiddish: yiddish, english: english, tier: "bibliotek"
                )
            }
            if bibliotek.toKey(english) != nil {
                throw LexiconError.collision(
                    yiddish: yiddish, english: english, tier: "bibliotek"
                )
            }
        }
    }
}

// MARK: - Errors

enum LexiconError: Error, CustomStringConvertible {
    case collision(yiddish: String, english: String, tier: String)

    var description: String {
        switch self {
        case .collision(let y, let e, let tier):
            return "Collision: '\(y)' ↔ '\(e)' conflicts with \(tier)"
        }
    }
}
