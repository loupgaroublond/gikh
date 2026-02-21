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

    // MARK: - Factory methods

    /// Compiler workflow: loads keywords (compiled in) + derives ביבליאָטעק
    /// mappings from source files at `bibliotekPath`.
    /// No project identifiers needed for B → C.
    public static func forCompilation(bibliotekPath: String) throws -> Lexicon {
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
    public static func forDeveloper(
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
    public static func deriveBibliotekMappings(from path: String) throws -> BiMap<String, String> {
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
    public static func extractMappings(from source: String) -> [(String, String)] {
        var pairs: [(String, String)] = []

        let lines = source.components(separatedBy: "\n")
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Comment-based mapping: `// mapping: יידיש = english`
            // Used for protocol method names and parameter labels that cannot
            // be expressed as typealiases or wrapper functions.
            if let pair = parseMappingComment(trimmed) {
                pairs.append(pair)
                continue
            }

            // typealias pattern: `[public] typealias <Yiddish> = <English>`
            if let pair = parseTypealias(trimmed) {
                pairs.append(pair)
                continue
            }

            // Extension member or global @_transparent function:
            // Parse wrapper functions and properties, extracting the English
            // equivalent from the function body.
            let nextLine: String? = idx + 1 < lines.count
                ? lines[idx + 1].trimmingCharacters(in: .whitespaces)
                : nil
            if let pair = parseExtensionMember(trimmed, nextLine: nextLine) {
                pairs.append(pair)
            }
        }

        return pairs
    }

    /// Parse `// mapping: יידיש = english` comments.
    /// These provide explicit Yiddish↔English mappings for protocol method names,
    /// parameter labels, and other identifiers that cannot be expressed as
    /// typealiases or wrapper functions.
    private static func parseMappingComment(_ line: String) -> (String, String)? {
        guard line.hasPrefix("// mapping: ") else { return nil }
        let rest = String(line.dropFirst("// mapping: ".count))
        let parts = rest.components(separatedBy: " = ")
        guard parts.count == 2 else { return nil }
        let yiddish = parts[0].trimmingCharacters(in: .whitespaces)
        let english = parts[1].trimmingCharacters(in: .whitespaces)
        guard !yiddish.isEmpty, !english.isEmpty else { return nil }
        return (yiddish, english)
    }

    /// Parse extension member declarations (func/var/static var) and global
    /// @_transparent/@_alwaysEmitIntoClient functions, extracting a
    /// (Yiddish, English) name pair.
    ///
    /// Handles:
    ///   - `[@_transparent] public [static] var יידיש: Type { body }`
    ///   - `[@_transparent] public [static] func יידיש(...) ... { body }`
    ///   - Multi-line bodies: if `{` ends the line, `nextLine` is inspected.
    ///
    /// The English equivalent is extracted from the body:
    ///   - `{ count }` → "count"
    ///   - `{ .red }` / `{ .red.something }` → "red"
    ///   - `{ lowercased() }` → "lowercased"
    ///   - `{ self.padding(...) }` → "padding"
    ///   - `{ Swift.min(...) }` → "min"
    ///   - `{ print(...) }` → "print"
    ///   - `{ !isEmpty }` → "isEmpty"
    ///   - `{ fatalError(...) }` → "fatalError"
    static func parseExtensionMember(_ line: String, nextLine: String?) -> (String, String)? {
        // Strip known attributes and access modifiers to get to the declaration.
        var rest = line
        for attr in ["@_transparent ", "@_alwaysEmitIntoClient "] {
            if rest.hasPrefix(attr) { rest = String(rest.dropFirst(attr.count)) }
        }
        for mod in ["public ", "internal ", "private ", "fileprivate "] {
            if rest.hasPrefix(mod) { rest = String(rest.dropFirst(mod.count)) }
        }
        // Strip `mutating` and `static`
        for mod in ["mutating ", "static "] {
            if rest.hasPrefix(mod) { rest = String(rest.dropFirst(mod.count)) }
        }

        let isFunc = rest.hasPrefix("func ")
        let isVar  = rest.hasPrefix("var ")
        guard isFunc || isVar else { return nil }

        // Extract the Yiddish name: first identifier token after `func`/`var`.
        rest = String(rest.dropFirst(isFunc ? "func ".count : "var ".count))
        let yiddishName = extractIdentifier(from: rest)
        guard !yiddishName.isEmpty else { return nil }

        // Find the body: look for `{ ... }` on the same line, or fall back to nextLine.
        let bodySource: String
        if let openBrace = line.firstIndex(of: "{") {
            let afterBrace = line[line.index(after: openBrace)...]
            // Check if brace is the very last non-whitespace char (multi-line body)
            let afterBraceTrimmed = afterBrace.trimmingCharacters(in: .whitespaces)
            if afterBraceTrimmed.isEmpty || afterBraceTrimmed == "}" {
                // Body is on next line
                let next = (nextLine ?? "").trimmingCharacters(in: .whitespaces)
                // Multi-line get/set computed property: extract from inside `get { ... }`
                if next.hasPrefix("get ") || next.hasPrefix("get{") {
                    if let innerOpen = next.firstIndex(of: "{") {
                        bodySource = String(next[next.index(after: innerOpen)...])
                    } else {
                        return nil
                    }
                } else {
                    bodySource = next
                }
            } else {
                bodySource = String(afterBrace)
            }
        } else {
            // No brace on this line — skip
            return nil
        }

        guard let englishName = extractEnglishFromBody(bodySource) else { return nil }

        // Skip if yiddish == english (not a translation wrapper)
        guard yiddishName != englishName else { return nil }

        return (yiddishName, englishName)
    }

    /// Extract the leading identifier from a string (stops at `(`, `<`, `:`,
    /// whitespace, `_` chains are included).
    private static func extractIdentifier(from str: String) -> String {
        var result = ""
        for ch in str {
            if ch.isLetter || ch.isNumber || ch == "_" {
                result.append(ch)
            } else {
                break
            }
        }
        return result
    }

    /// Given the text inside/after `{`, extract the English function/property name.
    private static func extractEnglishFromBody(_ body: String) -> String? {
        let trimmed = body.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Strip leading `!` or `return ` to reach the actual expression
        var expr = trimmed
        if expr.hasPrefix("!") { expr = String(expr.dropFirst()) }
        if expr.hasPrefix("return ") { expr = String(expr.dropFirst("return ".count)) }

        // Strip `self.` prefix
        if expr.hasPrefix("self.") { expr = String(expr.dropFirst("self.".count)) }

        // Strip module prefix like `Swift.`
        if let dotRange = expr.range(of: "."),
           expr[expr.startIndex..<dotRange.lowerBound].allSatisfy({ $0.isLetter || $0.isNumber }) {
            let prefix = String(expr[expr.startIndex..<dotRange.lowerBound])
            // Only strip if it looks like a module qualifier (all ASCII letters, e.g. "Swift")
            let isModule = prefix.unicodeScalars.allSatisfy({ $0.value < 128 && ($0.isASCII) })
            if isModule && !prefix.isEmpty {
                let afterDot = String(expr[dotRange.upperBound...])
                // If what follows is `.something`, this is a dot-enum prefix, handle below
                if !afterDot.hasPrefix(".") {
                    expr = afterDot
                }
            }
        }

        // Dot-prefixed enum/static member: `.red`, `.red.opacity(...)` → "red"
        if expr.hasPrefix(".") {
            expr = String(expr.dropFirst())
            // Take just the first identifier component (before another `.` or `(`)
            return extractIdentifier(from: expr).nilIfEmpty
        }

        // Bare identifier or function call: `count`, `isEmpty`, `lowercased()`, `padding(...)`
        let name = extractIdentifier(from: expr)
        return name.nilIfEmpty
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

    public static func loadProjectIdentifiers(from path: String) throws -> BiMap<String, String> {
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
    public static func parseYAMLIdentifiers(_ yaml: String) -> [(String, String)] {
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
    public static func validateNoCrossCollisions(
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

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

public enum LexiconError: Error, CustomStringConvertible {
    case collision(yiddish: String, english: String, tier: String)

    public var description: String {
        switch self {
        case .collision(let y, let e, let tier):
            return "Collision: '\(y)' ↔ '\(e)' conflicts with \(tier)"
        }
    }
}
