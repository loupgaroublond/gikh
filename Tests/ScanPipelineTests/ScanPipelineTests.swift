import Testing
import Foundation
@testable import GikhCore

// MARK: - SymbolExtractor tests

@Suite("SymbolExtractor — From Source")
struct SymbolExtractorSourceTests {

    @Test("Extracts top-level type names from Swift source")
    func extractsTopLevelTypes() {
        let source = """
        struct Person {}
        class Vehicle {}
        enum Direction {}
        protocol Drawable {}
        """
        let symbols = SymbolExtractor.extractFromSource(source, moduleName: "App")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("Person"))
        #expect(names.contains("Vehicle"))
        #expect(names.contains("Direction"))
        #expect(names.contains("Drawable"))
    }

    @Test("Extracts function names from Swift source")
    func extractsFunctions() {
        let source = """
        func calculate() -> Int { return 0 }
        func fetchData(from url: String) async throws -> Data { fatalError() }
        """
        let symbols = SymbolExtractor.extractFromSource(source, moduleName: "App")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("calculate"))
        #expect(names.contains("fetchData"))
    }

    @Test("Extracts identifiers (type usages) from Swift source")
    func extractsIdentifiersFromSource() {
        let source = "let x: String = \"hello\"\nlet y: Int = 42"
        let symbols = SymbolExtractor.extractFromSource(source, moduleName: "App")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("String"))
        #expect(names.contains("Int"))
    }

    @Test("Module name is attached to extracted symbols")
    func moduleNameAttached() {
        let source = "func foo() {}"
        let symbols = SymbolExtractor.extractFromSource(source, moduleName: "MyModule")
        #expect(symbols.allSatisfy { $0.module == "MyModule" })
    }

    @Test("Empty source returns empty symbol list")
    func emptySourceReturnsEmpty() {
        let symbols = SymbolExtractor.extractFromSource("", moduleName: "App")
        #expect(symbols.isEmpty)
    }
}

@Suite("SymbolExtractor — From .swiftinterface")
struct SymbolExtractorInterfaceTests {

    @Test("Extracts symbols from a minimal .swiftinterface snippet")
    func extractsFromInterface() {
        let interface = """
        // swift-interface-format-version: 1.0
        // swift-compiler-version: Apple Swift version 5.9
        import Swift
        public struct URLSession {
          public func data(from url: URL) async throws -> (Data, URLResponse)
          public static var shared: URLSession { get }
        }
        public class URLRequest {}
        """
        let symbols = SymbolExtractor.extractFromInterface(interface, moduleName: "Foundation")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("URLSession"))
        #expect(names.contains("URLRequest"))
        #expect(names.contains("data"))
    }

    @Test("Module name from interface is used")
    func moduleNameFromInterface() {
        let interface = "public struct Foo {}"
        let symbols = SymbolExtractor.extractFromInterface(interface, moduleName: "TestModule")
        #expect(symbols.allSatisfy { $0.module == "TestModule" })
    }

    @Test("Empty interface returns empty symbol list")
    func emptyInterfaceReturnsEmpty() {
        let symbols = SymbolExtractor.extractFromInterface("", moduleName: "Foundation")
        #expect(symbols.isEmpty)
    }

    @Test("Symbols have correct kind classification")
    func symbolsHaveKind() {
        let interface = """
        public struct Person {}
        public func greet() {}
        public var name: String
        """
        let symbols = SymbolExtractor.extractFromInterface(interface, moduleName: "App")
        let byName = Dictionary(symbols.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        #expect(byName["Person"]?.kind == .type)
        #expect(byName["greet"]?.kind == .function)
    }
}

// MARK: - CoverageChecker tests

@Suite("CoverageChecker")
struct CoverageCheckerTests {

    private func makeLexicon() -> Lexicon {
        let bibliotek = BiMap<String, String>([
            ("סטרינג", "String"),
            ("צאָל", "Int"),
            ("דרוק", "print"),
        ])
        return Lexicon(
            keywords: SwiftKeywords.keywordsMap,
            bibliotek: bibliotek,
            identifiers: BiMap([])
        )
    }

    @Test("Covered symbol returns covered result")
    func coveredSymbol() {
        let lexicon = makeLexicon()
        let checker = CoverageChecker(lexicon: lexicon)
        let symbol = ExtractedSymbol(name: "String", module: "Swift", kind: .type)
        let result = checker.check(symbol)
        #expect(result == .covered(yiddish: "סטרינג"))
    }

    @Test("Uncovered symbol returns untranslated result")
    func uncoveredSymbol() {
        let lexicon = makeLexicon()
        let checker = CoverageChecker(lexicon: lexicon)
        let symbol = ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type)
        let result = checker.check(symbol)
        #expect(result == .untranslated)
    }

    @Test("Keyword symbol is covered")
    func keywordCovered() {
        let lexicon = makeLexicon()
        let checker = CoverageChecker(lexicon: lexicon)
        let symbol = ExtractedSymbol(name: "func", module: "", kind: .keyword)
        let result = checker.check(symbol)
        #expect(result == .covered(yiddish: "פֿונקציע"))
    }

    @Test("Coverage report counts covered vs total correctly")
    func coverageReport() {
        let lexicon = makeLexicon()
        let checker = CoverageChecker(lexicon: lexicon)
        let symbols = [
            ExtractedSymbol(name: "String", module: "Swift", kind: .type),
            ExtractedSymbol(name: "Int", module: "Swift", kind: .type),
            ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type),
            ExtractedSymbol(name: "Date", module: "Foundation", kind: .type),
        ]
        let report = checker.buildReport(symbols: symbols, projectName: "TestApp")
        #expect(report.covered == 2)
        #expect(report.total == 4)
        #expect(report.coveragePercent == 50.0)
    }

    @Test("Report groups uncovered symbols by module")
    func reportGroupsByModule() {
        let lexicon = makeLexicon()
        let checker = CoverageChecker(lexicon: lexicon)
        let symbols = [
            ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type),
            ExtractedSymbol(name: "Date", module: "Foundation", kind: .type),
            ExtractedSymbol(name: "Button", module: "SwiftUI", kind: .type),
        ]
        let report = checker.buildReport(symbols: symbols, projectName: "TestApp")
        let modules = Set(report.uncoveredByModule.keys)
        #expect(modules.contains("Foundation"))
        #expect(modules.contains("SwiftUI"))
        #expect(report.uncoveredByModule["Foundation"]?.count == 2)
        #expect(report.uncoveredByModule["SwiftUI"]?.count == 1)
    }

    @Test("Symbols with empty names are ignored")
    func emptyNamesIgnored() {
        let lexicon = makeLexicon()
        let checker = CoverageChecker(lexicon: lexicon)
        let symbols = [
            ExtractedSymbol(name: "", module: "App", kind: .type),
            ExtractedSymbol(name: "String", module: "Swift", kind: .type),
        ]
        let report = checker.buildReport(symbols: symbols, projectName: "TestApp")
        #expect(report.total == 1)
    }
}

// MARK: - Output formatter tests

@Suite("ScanOutputFormatter — Table")
struct ScanOutputFormatterTableTests {

    private func makeReport() -> ScanReport {
        ScanReport(
            projectName: "WeatherApp",
            covered: 10,
            total: 13,
            uncoveredByModule: [
                "Foundation": [
                    ExtractedSymbol(name: "DateFormatter", module: "Foundation", kind: .type),
                    ExtractedSymbol(name: "Locale", module: "Foundation", kind: .type),
                ],
                "WeatherKit": [
                    ExtractedSymbol(name: "WeatherService", module: "WeatherKit", kind: .type),
                ],
            ]
        )
    }

    @Test("Table format contains project name")
    func tableContainsProjectName() {
        let report = makeReport()
        let output = ScanOutputFormatter.format(report, format: .table)
        #expect(output.contains("WeatherApp"))
    }

    @Test("Table format shows coverage percentage")
    func tableShowsCoverage() {
        let report = makeReport()
        let output = ScanOutputFormatter.format(report, format: .table)
        #expect(output.contains("76"))  // 10/13 ≈ 76.9%
    }

    @Test("Table format groups by module")
    func tableGroupsByModule() {
        let report = makeReport()
        let output = ScanOutputFormatter.format(report, format: .table)
        #expect(output.contains("Foundation"))
        #expect(output.contains("WeatherKit"))
    }

    @Test("Table format shows untranslated symbols")
    func tableShowsSymbols() {
        let report = makeReport()
        let output = ScanOutputFormatter.format(report, format: .table)
        #expect(output.contains("DateFormatter"))
        #expect(output.contains("WeatherService"))
    }
}

@Suite("ScanOutputFormatter — YAML")
struct ScanOutputFormatterYAMLTests {

    private func makeReport() -> ScanReport {
        ScanReport(
            projectName: "TestApp",
            covered: 5,
            total: 7,
            uncoveredByModule: [
                "Foundation": [
                    ExtractedSymbol(name: "Locale", module: "Foundation", kind: .type),
                ],
            ]
        )
    }

    @Test("YAML format starts with project info")
    func yamlStartsWithProject() {
        let report = makeReport()
        let output = ScanOutputFormatter.format(report, format: .yaml)
        #expect(output.contains("project:") || output.contains("TestApp"))
    }

    @Test("YAML format contains coverage data")
    func yamlContainsCoverage() {
        let report = makeReport()
        let output = ScanOutputFormatter.format(report, format: .yaml)
        #expect(output.contains("covered:") || output.contains("5"))
        #expect(output.contains("total:") || output.contains("7"))
    }

    @Test("YAML format lists untranslated symbols")
    func yamlListsUntranslated() {
        let report = makeReport()
        let output = ScanOutputFormatter.format(report, format: .yaml)
        #expect(output.contains("Locale"))
    }
}

@Suite("ScanOutputFormatter — Diff")
struct ScanOutputFormatterDiffTests {

    @Test("Diff format shows only untranslated symbols")
    func diffShowsOnlyUntranslated() {
        let report = ScanReport(
            projectName: "TestApp",
            covered: 3,
            total: 5,
            uncoveredByModule: [
                "Foundation": [
                    ExtractedSymbol(name: "Locale", module: "Foundation", kind: .type),
                    ExtractedSymbol(name: "TimeZone", module: "Foundation", kind: .type),
                ],
            ]
        )
        let output = ScanOutputFormatter.format(report, format: .diff)
        #expect(output.contains("Locale"))
        #expect(output.contains("TimeZone"))
    }

    @Test("Diff format shows ? for untranslated")
    func diffShowsQuestionMark() {
        let report = ScanReport(
            projectName: "TestApp",
            covered: 0,
            total: 1,
            uncoveredByModule: [
                "Foundation": [
                    ExtractedSymbol(name: "Locale", module: "Foundation", kind: .type),
                ],
            ]
        )
        let output = ScanOutputFormatter.format(report, format: .diff)
        #expect(output.contains("?"))
    }
}

// MARK: - .swiftinterface parser tests

@Suite("SwiftInterfaceParser")
struct SwiftInterfaceParserTests {

    @Test("Parses struct declarations")
    func parsesStructs() {
        let interface = "public struct URLSession {}"
        let symbols = SwiftInterfaceParser.parse(interface, moduleName: "Foundation")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("URLSession"))
    }

    @Test("Parses class declarations")
    func parsesClasses() {
        let interface = "public class NSObject {}"
        let symbols = SwiftInterfaceParser.parse(interface, moduleName: "Foundation")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("NSObject"))
    }

    @Test("Parses enum declarations")
    func parsesEnums() {
        let interface = "public enum ComparisonResult { case orderedAscending }"
        let symbols = SwiftInterfaceParser.parse(interface, moduleName: "Foundation")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("ComparisonResult"))
    }

    @Test("Parses protocol declarations")
    func parsesProtocols() {
        let interface = "public protocol Hashable {}"
        let symbols = SwiftInterfaceParser.parse(interface, moduleName: "Swift")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("Hashable"))
    }

    @Test("Parses func declarations")
    func parsesFunctions() {
        let interface = "public func print(_ items: Any...)"
        let symbols = SwiftInterfaceParser.parse(interface, moduleName: "Swift")
        let names = Set(symbols.map(\.name))
        #expect(names.contains("print"))
    }

    @Test("Skips comment lines")
    func skipsComments() {
        let interface = """
        // swift-interface-format-version: 1.0
        // swift-compiler-version: Apple Swift version 5.9
        public struct Foo {}
        """
        let symbols = SwiftInterfaceParser.parse(interface, moduleName: "Test")
        // Should only get Foo, not the comment lines
        #expect(symbols.count == 1)
        #expect(symbols[0].name == "Foo")
    }

    @Test("Finds .swiftinterface files on disk")
    func findsInterfaceFiles() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let content = "public struct TestType {}"
        try content.write(
            to: dir.appendingPathComponent("arm64-apple-macosx.swiftinterface"),
            atomically: true, encoding: .utf8
        )

        let files = SwiftInterfaceParser.findInterfaceFiles(in: dir.path)
        #expect(!files.isEmpty)
    }
}

// MARK: - SDK diff tests

@Suite("SDKVersionDiff")
struct SDKVersionDiffTests {

    @Test("Identifies new symbols added between versions")
    func identifiesNewSymbols() {
        let v1 = [
            ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type),
        ]
        let v2 = [
            ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type),
            ExtractedSymbol(name: "URLSessionWebSocketTask", module: "Foundation", kind: .type),
        ]
        let diff = SDKVersionDiff.diff(from: v1, to: v2)
        #expect(diff.added.contains(where: { $0.name == "URLSessionWebSocketTask" }))
        #expect(diff.removed.isEmpty)
    }

    @Test("Identifies removed symbols between versions")
    func identifiesRemovedSymbols() {
        let v1 = [
            ExtractedSymbol(name: "OldAPI", module: "Foundation", kind: .type),
            ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type),
        ]
        let v2 = [
            ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type),
        ]
        let diff = SDKVersionDiff.diff(from: v1, to: v2)
        #expect(diff.removed.contains(where: { $0.name == "OldAPI" }))
        #expect(diff.added.isEmpty)
    }

    @Test("Empty diff when versions are identical")
    func emptyDiffIdentical() {
        let symbols = [ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type)]
        let diff = SDKVersionDiff.diff(from: symbols, to: symbols)
        #expect(diff.added.isEmpty)
        #expect(diff.removed.isEmpty)
    }

    @Test("Diff report shows coverage impact")
    func diffReportShowsCoverageImpact() {
        let lexicon = Lexicon(
            keywords: SwiftKeywords.keywordsMap,
            bibliotek: BiMap([("סטרינג", "String")]),
            identifiers: BiMap([])
        )
        let added = [
            ExtractedSymbol(name: "String", module: "Swift", kind: .type),
            ExtractedSymbol(name: "NewThing", module: "Foundation", kind: .type),
        ]
        let diff = SymbolDiff(added: added, removed: [])
        let report = SDKVersionDiff.coverageReport(for: diff, lexicon: lexicon)
        // String is covered, NewThing is not
        #expect(report.coveredAdded == 1)
        #expect(report.uncoveredAdded == 1)
    }
}

// MARK: - Lexicon suggest from scan tests

@Suite("LexiconSuggest — From Scan")
struct LexiconSuggestTests {

    @Test("Suggestions categorize framework vs project symbols")
    func categorizesByOrigin() {
        let uncovered = [
            ExtractedSymbol(name: "URLSession", module: "Foundation", kind: .type),
            ExtractedSymbol(name: "MyViewModel", module: "App", kind: .type),
        ]
        let suggestions = LexiconSuggest.suggest(for: uncovered, commonWords: [:])
        let frameworkNames = Set(suggestions.frameworkSymbols.map(\.symbol.name))
        let projectNames = Set(suggestions.projectSymbols.map(\.symbol.name))
        #expect(frameworkNames.contains("URLSession"))
        #expect(projectNames.contains("MyViewModel"))
    }

    @Test("Common words dictionary consulted for proposals")
    func commonWordsDictionaryConsulted() {
        let uncovered = [
            ExtractedSymbol(name: "session", module: "App", kind: .function),
        ]
        let commonWords = ["session": "זיצונג"]
        let suggestions = LexiconSuggest.suggest(for: uncovered, commonWords: commonWords)
        let all = suggestions.frameworkSymbols + suggestions.projectSymbols
        let forSession = all.first(where: { $0.symbol.name == "session" })
        #expect(forSession?.proposedYiddish == "זיצונג")
    }

    @Test("No proposal when common words has no match")
    func noProposalWhenNoMatch() {
        let uncovered = [
            ExtractedSymbol(name: "floogleBorp", module: "App", kind: .type),
        ]
        let suggestions = LexiconSuggest.suggest(for: uncovered, commonWords: [:])
        let all = suggestions.frameworkSymbols + suggestions.projectSymbols
        let found = all.first(where: { $0.symbol.name == "floogleBorp" })
        // Should still appear but with nil proposal
        #expect(found != nil)
        #expect(found?.proposedYiddish == nil)
    }
}
