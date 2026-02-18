import PackagePlugin
import Foundation

@main
struct TranspilePlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let gikhTool = try context.tool(named: "GikhCLI")
        let outputDir = context.pluginWorkDirectory

        var commands: [Command] = []

        // Find .gikh files from sourceFiles (if SwiftPM includes them)
        var gikhFiles = sourceTarget.sourceFiles.filter {
            $0.path.extension == "gikh"
        }.map { $0.path }

        // Also scan the target directory for .gikh files that SwiftPM may not
        // include in sourceFiles (unknown extension). This ensures .gikh files
        // are discovered regardless of Package.swift configuration.
        if gikhFiles.isEmpty {
            let targetDir = sourceTarget.directory.string
            let fm = FileManager.default
            if let enumerator = fm.enumerator(atPath: targetDir) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(".gikh") {
                        let fullPath = Path(targetDir + "/" + file)
                        if !gikhFiles.contains(where: { $0.string == fullPath.string }) {
                            gikhFiles.append(fullPath)
                        }
                    }
                }
            }
        }

        for inputPath in gikhFiles {
            let outputFileName = inputPath.stem + ".swift"
            let outputPath = outputDir.appending(outputFileName)

            commands.append(.buildCommand(
                displayName: "Transpile \(inputPath.lastComponent) → \(outputFileName)",
                executable: gikhTool.path,
                arguments: [
                    "to-hybrid",
                    "--input", "\(inputPath)",
                    "--output", "\(outputPath)"
                ],
                inputFiles: [inputPath],
                outputFiles: [outputPath]
            ))
        }

        return commands
    }
}
