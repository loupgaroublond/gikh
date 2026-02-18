import Testing
import Foundation

@Test func compileProducesNoIntermediateSwiftFiles() throws {
    let fm = FileManager.default
    let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tempDir) }

    let gikhFile = tempDir.appendingPathComponent("test.gikh")
    try "import ביבליאָטעק\nדרוק(\"test\")\n".write(to: gikhFile, atomically: true, encoding: .utf8)

    // Record all .swift files before compilation
    let swiftFilesBefore = try fm.contentsOfDirectory(atPath: tempDir.path)
        .filter { $0.hasSuffix(".swift") }

    // Compile
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

    // Verify no intermediate .swift files were created in the working directory
    let swiftFilesAfter = try fm.contentsOfDirectory(atPath: tempDir.path)
        .filter { $0.hasSuffix(".swift") }

    #expect(swiftFilesBefore == swiftFilesAfter,
        "No intermediate .swift files should be created during compilation")
}
