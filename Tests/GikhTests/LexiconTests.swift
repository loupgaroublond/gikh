import Testing
import Foundation
@testable import גיך

// MARK: - Helpers

/// Create a temporary directory with the given files (relative path → content).
private func makeTempDir(files: [String: String]) throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for (path, content) in files {
        let url = dir.appendingPathComponent(path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    return dir
}

// MARK: - Typealias parsing tests

@Suite("Lexicon — Typealias Parsing")
struct LexiconTypealiasParsingTests {

    @Test("Parse simple typealias")
    func simpleTypealias() {
        let source = "public typealias סטרינג = String"
        let pairs = Lexicon.extractMappings(from: source)
        #expect(pairs.count == 1)
        #expect(pairs[0].0 == "סטרינג")
        #expect(pairs[0].1 == "String")
    }

    @Test("Parse typealias without access modifier")
    func typealiasWithoutModifier() {
        let source = "typealias צאָל = Int"
        let pairs = Lexicon.extractMappings(from: source)
        #expect(pairs.count == 1)
        #expect(pairs[0].0 == "צאָל")
        #expect(pairs[0].1 == "Int")
    }

    @Test("Parse multiple typealiases from multiline source")
    func multipleTypealiases() {
        let source = """
        public typealias סטרינג = String
        public typealias צאָל = Int
        public typealias טאָפּל = Double
        """
        let pairs = Lexicon.extractMappings(from: source)
        #expect(pairs.count == 3)
        let yiddishKeys = Set(pairs.map(\.0))
        #expect(yiddishKeys.contains("סטרינג"))
        #expect(yiddishKeys.contains("צאָל"))
        #expect(yiddishKeys.contains("טאָפּל"))
    }

    @Test("Skip generic typealiases")
    func skipGenericTypealiases() {
        let source = "public typealias מאַסיוו<T> = Array<T>"
        let pairs = Lexicon.extractMappings(from: source)
        #expect(pairs.isEmpty)
    }

    @Test("Skip lines without typealias keyword")
    func skipNonTypealiasLines() {
        let source = """
        // This is a comment
        struct Foo {}
        public typealias סטרינג = String
        func bar() {}
        """
        let pairs = Lexicon.extractMappings(from: source)
        #expect(pairs.count == 1)
    }

    @Test("Parse internal typealias")
    func internalTypealias() {
        let source = "internal typealias באָאָל = Bool"
        let pairs = Lexicon.extractMappings(from: source)
        #expect(pairs.count == 1)
        #expect(pairs[0].0 == "באָאָל")
    }
}

// MARK: - YAML identifier parsing tests

@Suite("Lexicon — YAML Identifier Parsing")
struct LexiconYAMLParsingTests {

    @Test("Parse simple YAML identifiers section")
    func simpleYAMLIdentifiers() {
        let yaml = """
        tier: project
        identifiers:
          מענטש: Person
          נאָמען: name
          עלטער: age
        """
        let pairs = Lexicon.parseYAMLIdentifiers(yaml)
        #expect(pairs.count == 3)
        let dict = Dictionary(uniqueKeysWithValues: pairs)
        #expect(dict["מענטש"] == "Person")
        #expect(dict["נאָמען"] == "name")
        #expect(dict["עלטער"] == "age")
    }

    @Test("YAML with comments ignored")
    func yamlWithComments() {
        let yaml = """
        identifiers:
          # This is a comment
          מענטש: Person
          # Another comment
          נאָמען: name
        """
        let pairs = Lexicon.parseYAMLIdentifiers(yaml)
        #expect(pairs.count == 2)
    }

    @Test("Empty YAML returns empty pairs")
    func emptyYAML() {
        let pairs = Lexicon.parseYAMLIdentifiers("")
        #expect(pairs.isEmpty)
    }

    @Test("YAML without identifiers section returns empty pairs")
    func yamlWithoutIdentifiersSection() {
        let yaml = "tier: project\ndescription: test"
        let pairs = Lexicon.parseYAMLIdentifiers(yaml)
        #expect(pairs.isEmpty)
    }
}

// MARK: - BiMap derivation from source files

@Suite("Lexicon — ביבליאָטעק Derivation")
struct LexiconBibliotekDerivationTests {

    @Test("Derive mappings from Swift file with typealiases")
    func deriveFromSwiftFile() throws {
        let dir = try makeTempDir(files: [
            "טיפּן/סטרינג.swift": """
            public typealias סטרינג = String
            public typealias צאָל = Int
            """
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        let map = try Lexicon.deriveBibliotekMappings(from: dir.path)
        #expect(map.toValue("סטרינג") == "String")
        #expect(map.toValue("צאָל") == "Int")
    }

    @Test("Derive from multiple Swift files")
    func deriveFromMultipleFiles() throws {
        let dir = try makeTempDir(files: [
            "file1.swift": "public typealias סטרינג = String",
            "file2.swift": "public typealias צאָל = Int",
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        let map = try Lexicon.deriveBibliotekMappings(from: dir.path)
        #expect(map.toValue("סטרינג") == "String")
        #expect(map.toValue("צאָל") == "Int")
    }

    @Test("Missing bibliotek path returns empty BiMap")
    func missingPathReturnsEmpty() throws {
        let map = try Lexicon.deriveBibliotekMappings(from: "/nonexistent/path")
        #expect(map.count == 0)
    }

    @Test("Reverse lookup: English → Yiddish")
    func reverseLookupEnglishToYiddish() throws {
        let dir = try makeTempDir(files: [
            "types.swift": "public typealias סטרינג = String"
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        let map = try Lexicon.deriveBibliotekMappings(from: dir.path)
        #expect(map.toKey("String") == "סטרינג")
    }
}

// MARK: - forCompilation factory

@Suite("Lexicon — forCompilation")
struct LexiconForCompilationTests {

    @Test("forCompilation loads keywords and bibliotek")
    func forCompilationLoadsKeywordsAndBibliotek() throws {
        let dir = try makeTempDir(files: [
            "types.swift": "public typealias סטרינג = String"
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        let lexicon = try Lexicon.forCompilation(bibliotekPath: dir.path)

        // Keywords must be present
        #expect(lexicon.keywords.toValue("לאָז") == "let")
        #expect(lexicon.keywords.toValue("פֿונקציע") == "func")

        // Bibliotek mappings present
        #expect(lexicon.bibliotek.toValue("סטרינג") == "String")

        // No project identifiers
        #expect(lexicon.identifiers.count == 0)
    }

    @Test("forCompilation with no bibliotek path returns lexicon with empty bibliotek")
    func forCompilationWithNoBibliotek() throws {
        let lexicon = try Lexicon.forCompilation(bibliotekPath: "/nonexistent")
        #expect(lexicon.keywords.toValue("לאָז") == "let")
        #expect(lexicon.bibliotek.count == 0)
    }
}

// MARK: - forDeveloper factory

@Suite("Lexicon — forDeveloper")
struct LexiconForDeveloperTests {

    @Test("forDeveloper loads all three dictionary tiers")
    func forDeveloperLoadsAllTiers() throws {
        let dir = try makeTempDir(files: [
            "bibliotek/types.swift": "public typealias סטרינג = String",
            "לעקסיקאָן.yaml": """
            tier: project
            identifiers:
              מענטש: Person
            """
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        let bibliotekPath = dir.appendingPathComponent("bibliotek").path
        let projectPath = dir.appendingPathComponent("לעקסיקאָן.yaml").path

        let lexicon = try Lexicon.forDeveloper(
            bibliotekPath: bibliotekPath,
            projectPath: projectPath
        )

        #expect(lexicon.keywords.toValue("לאָז") == "let")
        #expect(lexicon.bibliotek.toValue("סטרינג") == "String")
        #expect(lexicon.identifiers.toValue("מענטש") == "Person")
    }

    @Test("forDeveloper with missing project YAML returns empty identifiers")
    func forDeveloperWithMissingYAML() throws {
        let dir = try makeTempDir(files: [
            "types.swift": "public typealias סטרינג = String"
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        let lexicon = try Lexicon.forDeveloper(
            bibliotekPath: dir.path,
            projectPath: "/nonexistent/לעקסיקאָן.yaml"
        )

        #expect(lexicon.identifiers.count == 0)
        #expect(lexicon.bibliotek.toValue("סטרינג") == "String")
    }

    @Test("forDeveloper detects cross-tier collision with bibliotek")
    func forDeveloperDetectsCollisionWithBibliotek() throws {
        let dir = try makeTempDir(files: [
            "bibliotek/types.swift": "public typealias סטרינג = String",
            "לעקסיקאָן.yaml": """
            tier: project
            identifiers:
              סטרינג: SomethingElse
            """
        ])
        defer { try? FileManager.default.removeItem(at: dir) }

        let bibliotekPath = dir.appendingPathComponent("bibliotek").path
        let projectPath = dir.appendingPathComponent("לעקסיקאָן.yaml").path

        #expect(throws: LexiconError.self) {
            _ = try Lexicon.forDeveloper(
                bibliotekPath: bibliotekPath,
                projectPath: projectPath
            )
        }
    }
}

// MARK: - Keywords map tests

@Suite("Lexicon — Keywords Map")
struct LexiconKeywordsMapTests {

    @Test("Keywords map contains פֿונקציע → func")
    func keywordsMapFuncMapping() {
        let map = SwiftKeywords.keywordsMap
        #expect(map.toValue("פֿונקציע") == "func")
    }

    @Test("Keywords map reverse lookup: func → פֿונקציע")
    func keywordsMapFuncReverse() {
        let map = SwiftKeywords.keywordsMap
        #expect(map.toKey("func") == "פֿונקציע")
    }

    @Test("Keywords map contains לאָז → let")
    func keywordsMapLetMapping() {
        #expect(SwiftKeywords.keywordsMap.toValue("לאָז") == "let")
    }

    @Test("Keywords map contains all yiddishToEnglish entries")
    func keywordsMapCompletenesss() {
        let map = SwiftKeywords.keywordsMap
        for (yiddish, english) in SwiftKeywords.yiddishToEnglish {
            #expect(map.toValue(yiddish) == english)
        }
    }
}
