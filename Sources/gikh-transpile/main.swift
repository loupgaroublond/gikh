import Foundation
import GikhCore

// gikh-transpile: Helper tool invoked by the SwiftPM build plugin.
// Transpiles a .gikh file (Mode B — Yiddish) to a .swift file (Mode C — compilation-ready).
//
// Usage: gikh-transpile <input.gikh> <output.swift>

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write(
        Data("Usage: gikh-transpile <input.gikh> <output.swift>\n".utf8)
    )
    exit(1)
}

let inputPath = args[1]
let outputPath = args[2]

do {
    let source = try String(contentsOfFile: inputPath, encoding: .utf8)

    // Build a compilation lexicon (keywords only; bibliotek empty if not present).
    // The bibliotek directory, if it exists, lives next to the package root.
    // For now we resolve it relative to the input file's directory.
    let inputDir = URL(fileURLWithPath: inputPath).deletingLastPathComponent().path
    let bibliotekPath = (inputDir as NSString).appendingPathComponent("ביבליאָטעק")
    let lexicon = try Lexicon.forCompilation(bibliotekPath: bibliotekPath)

    // Run the B→C pipeline: Yiddish keywords → English, strip BiDi isolates.
    let output = Transpiler.transpile(source, lexicon: lexicon, target: .modeC)

    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try output.write(toFile: outputPath, atomically: true, encoding: .utf8)
} catch {
    FileHandle.standardError.write(
        Data("gikh-transpile error: \(error)\n".utf8)
    )
    exit(1)
}
