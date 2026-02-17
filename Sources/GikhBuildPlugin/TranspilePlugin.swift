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

        let gikhTool = try context.tool(named: "gikh")
        let outputDir = context.pluginWorkDirectory

        var commands: [Command] = []

        // Find all .gikh files in the target's source files
        let gikhFiles = sourceTarget.sourceFiles.filter {
            $0.path.extension == "gikh"
        }

        for file in gikhFiles {
            let inputPath = file.path
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
