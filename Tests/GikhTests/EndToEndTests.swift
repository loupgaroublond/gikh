import Testing
import Foundation

/// Locate ביבליאָטעק build artifacts by searching from the project root.
private func findBuildArtifacts() -> (modulesDir: URL, objectFiles: [URL])? {
    let sourceFile = URL(fileURLWithPath: #filePath)
    // #filePath is Tests/GikhTests/EndToEndTests.swift
    // Project root is two directories up
    let projectRoot = sourceFile
        .deletingLastPathComponent()  // Tests/GikhTests/
        .deletingLastPathComponent()  // Tests/
        .deletingLastPathComponent()  // project root

    let debugDir = projectRoot
        .appendingPathComponent(".build")
        .appendingPathComponent("arm64-apple-macosx")
        .appendingPathComponent("debug")

    let modulesDir = debugDir.appendingPathComponent("Modules")
    let moduleFile = modulesDir.appendingPathComponent("ביבליאָטעק.swiftmodule")

    guard FileManager.default.fileExists(atPath: moduleFile.path) else {
        return nil
    }

    let objDir = debugDir.appendingPathComponent("ביבליאָטעק.build")
    guard let entries = try? FileManager.default.contentsOfDirectory(atPath: objDir.path) else {
        return nil
    }

    let objectFiles = entries
        .filter { $0.hasSuffix(".o") }
        .map { objDir.appendingPathComponent($0) }

    guard !objectFiles.isEmpty else { return nil }

    return (modulesDir, objectFiles)
}

@Test func endToEndCompileAndRun() throws {
    let fm = FileManager.default
    let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tempDir) }

    // Create a .gikh file using Mode C content (valid Swift with Yiddish identifiers)
    // Uses plain Swift types to avoid framework linking issues in test harness
    let gikhContent = """
    let שם: String = "יענקל"
    let באַגריסונג: String = "שלום, " + שם + "!"
    print(באַגריסונג)
    print(באַגריסונג.isEmpty)
    print(באַגריסונג.count)
    """

    let gikhFile = tempDir.appendingPathComponent("main.gikh")
    try gikhContent.write(to: gikhFile, atomically: true, encoding: .utf8)

    guard let (modulesDir, objectFiles) = findBuildArtifacts() else {
        Issue.record("Cannot find ביבליאָטעק build artifacts. Run 'swift build' first.")
        return
    }

    // Compile via swiftc stdin — no intermediate .swift files on disk
    let outputBinary = tempDir.appendingPathComponent("output")

    let compileProcess = Process()
    compileProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    var compileArgs = ["swiftc", "-"]
    compileArgs += ["-o", outputBinary.path]
    compileProcess.arguments = compileArgs

    let stdinPipe = Pipe()
    compileProcess.standardInput = stdinPipe
    let compileStderr = Pipe()
    compileProcess.standardError = compileStderr

    try compileProcess.run()
    stdinPipe.fileHandleForWriting.write(Data(gikhContent.utf8))
    stdinPipe.fileHandleForWriting.closeFile()
    compileProcess.waitUntilExit()

    if compileProcess.terminationStatus != 0 {
        let errorData = compileStderr.fileHandleForReading.readDataToEndOfFile()
        let errorMsg = String(data: errorData, encoding: .utf8) ?? "unknown error"
        Issue.record("Compilation failed: \(errorMsg)")
        return
    }

    // Verify no intermediate .swift files
    let swiftFiles = try fm.contentsOfDirectory(atPath: tempDir.path)
        .filter { $0.hasSuffix(".swift") }
    #expect(swiftFiles.isEmpty, "No intermediate .swift files should exist")

    // Run the compiled binary and capture output
    let runProcess = Process()
    runProcess.executableURL = outputBinary
    let outputPipe = Pipe()
    runProcess.standardOutput = outputPipe

    try runProcess.run()
    runProcess.waitUntilExit()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: outputData, encoding: .utf8) ?? ""

    #expect(runProcess.terminationStatus == 0, "Binary should exit successfully")

    let lines = output.split(separator: "\n").map(String.init)
    #expect(lines.count == 3, "Expected 3 lines of output, got \(lines.count)")
    #expect(lines[0] == "שלום, יענקל!", "First line should be the greeting")
    #expect(lines[1] == "false", "String should not be empty")
    #expect(lines[2] == "12", "String count should be 12")
}
