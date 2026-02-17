// CodebaseScannerTests.swift
// ScanPipeline — Tests for the external codebase scanner.

import XCTest
@testable import ScanPipeline
@testable import GikhCore

final class CodebaseScannerTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gikh-scan-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Helpers

    private func writeFile(_ name: String, content: String) throws {
        let path = tempDir.appendingPathComponent(name)
        try content.write(to: path, atomically: true, encoding: .utf8)
    }

    // MARK: - Basic Scan

    func testScan_emptyDirectory() throws {
        let lexicon = Lexicon.forCompilation()
        let scanner = CodebaseScanner(lexicon: lexicon)
        let result = try scanner.scan(directory: tempDir.path)

        XCTAssertEqual(result.totalSymbols, 0)
        XCTAssertEqual(result.coveredSymbols, 0)
        XCTAssertEqual(result.coveragePercent, 100.0)
    }

    func testScan_singleSwiftFile_withUntranslated() throws {
        try writeFile("main.swift", content: "func myFunction() { return }")

        let lexicon = Lexicon.forCompilation()
        let scanner = CodebaseScanner(lexicon: lexicon)
        let result = try scanner.scan(directory: tempDir.path)

        XCTAssertTrue(result.totalSymbols > 0)
        XCTAssertTrue(result.untranslatedSymbols["Project"]?.contains("myFunction") ?? false)
    }

    func testScan_identifierInLexicon_isCovered() throws {
        try writeFile("main.swift", content: "let name = \"hello\"\n")

        let bib = BiMap<String, String>([("נאָמען", "name")])
        let lexicon = Lexicon(
            keywords: Keywords.dictionary,
            bibliotek: bib,
            identifiers: BiMap()
        )
        let scanner = CodebaseScanner(lexicon: lexicon)
        let result = try scanner.scan(directory: tempDir.path)

        XCTAssertEqual(result.coveredSymbols, result.totalSymbols)
    }

    func testScan_gikhFiles_included() throws {
        try writeFile("main.gikh", content: "לאָז נאָמען = \"שלום\"\n")

        let ids = BiMap<String, String>([("נאָמען", "name")])
        let lexicon = Lexicon(
            keywords: Keywords.dictionary,
            bibliotek: BiMap(),
            identifiers: ids
        )
        let scanner = CodebaseScanner(lexicon: lexicon)
        let result = try scanner.scan(directory: tempDir.path)

        XCTAssertGreaterThanOrEqual(result.coveredSymbols, 1)
    }

    func testScan_ignoresNonSwiftFiles() throws {
        try writeFile("readme.txt", content: "func myFunction() { }")
        try writeFile("data.json", content: "{\"key\": \"value\"}")

        let lexicon = Lexicon.forCompilation()
        let scanner = CodebaseScanner(lexicon: lexicon)
        let result = try scanner.scan(directory: tempDir.path)

        XCTAssertEqual(result.totalSymbols, 0)
    }

    // MARK: - Error Cases

    func testScan_nonexistentDirectory_throws() {
        let lexicon = Lexicon.forCompilation()
        let scanner = CodebaseScanner(lexicon: lexicon)

        XCTAssertThrowsError(try scanner.scan(directory: "/nonexistent/path")) { error in
            guard case ScanError.directoryNotFound = error else {
                XCTFail("Expected ScanError.directoryNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Coverage Calculation

    func testCoveragePercent_halfCovered() {
        let result = CodebaseScanner.ScanResult(
            totalSymbols: 10,
            coveredSymbols: 5,
            untranslatedSymbols: ["Project": ["a", "b", "c", "d", "e"]]
        )
        XCTAssertEqual(result.coveragePercent, 50.0, accuracy: 0.01)
    }

    func testCoveragePercent_fullyCovered() {
        let result = CodebaseScanner.ScanResult(
            totalSymbols: 10,
            coveredSymbols: 10,
            untranslatedSymbols: [:]
        )
        XCTAssertEqual(result.coveragePercent, 100.0)
    }

    func testCoveragePercent_empty() {
        let result = CodebaseScanner.ScanResult(
            totalSymbols: 0,
            coveredSymbols: 0,
            untranslatedSymbols: [:]
        )
        XCTAssertEqual(result.coveragePercent, 100.0)
    }
}
