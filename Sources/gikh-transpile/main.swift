import Foundation
import GikhCore

// gikh-transpile: Helper tool invoked by the SwiftPM build plugin.
// Transpiles a .gikh file (Mode B — Yiddish) to a .swift file (Mode C — compilation-ready).
//
// Usage: gikh-transpile <input.gikh> <output.swift>

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(
        Data("Usage: gikh-transpile <input.gikh> <output.swift> [bibliotek-path]\n".utf8)
    )
    exit(1)
}

let inputPath = args[1]
let outputPath = args[2]

do {
    let source = try String(contentsOfFile: inputPath, encoding: .utf8)

    // Resolve the ביבליאָטעק source directory.
    // Priority: (1) explicit third argument, (2) search up from input file for Sources/ביבליאָטעק.
    let bibliotekPath: String
    if args.count >= 4 {
        bibliotekPath = args[3]
    } else {
        // Walk up from the input file directory looking for Sources/ביבליאָטעק
        var dir = URL(fileURLWithPath: inputPath).deletingLastPathComponent()
        var found: String?
        for _ in 0..<10 {
            let candidate = dir.appendingPathComponent("Sources/ביבליאָטעק").path
            if FileManager.default.fileExists(atPath: candidate) {
                found = candidate
                break
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
        bibliotekPath = found ?? dir.appendingPathComponent("ביבליאָטעק").path
    }
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
