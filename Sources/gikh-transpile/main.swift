import Foundation

// gikh-transpile: Helper tool invoked by the SwiftPM build plugin.
// Phase 1 stub: copies .gikh content unchanged to .swift output.
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

let content = try String(contentsOfFile: inputPath, encoding: .utf8)

let outputURL = URL(fileURLWithPath: outputPath)
let outputDir = outputURL.deletingLastPathComponent()
try FileManager.default.createDirectory(
    at: outputDir, withIntermediateDirectories: true
)
try content.write(toFile: outputPath, atomically: true, encoding: .utf8)
