import PackagePlugin

@main
struct TranspilePlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let transpileTool = try context.tool(named: "gikh-transpile")
        let outputDir = context.pluginWorkDirectoryURL

        let gikhFiles = sourceTarget.sourceFiles.filter { file in
            file.url.pathExtension == "gikh"
        }

        // Resolve the ביבליאָטעק source directory relative to the package root
        let bibliotekPath = context.package.directoryURL
            .appending(path: "Sources/ביבליאָטעק")
            .path(percentEncoded: false)

        return gikhFiles.map { file in
            let inputURL = file.url
            let outputFileName = inputURL.deletingPathExtension()
                .appendingPathExtension("swift").lastPathComponent
            let outputURL = outputDir.appending(path: outputFileName)

            return .buildCommand(
                displayName: "Transpile \(inputURL.lastPathComponent)",
                executable: transpileTool.url,
                arguments: [
                    inputURL.path(percentEncoded: false),
                    outputURL.path(percentEncoded: false),
                    bibliotekPath,
                ],
                inputFiles: [inputURL],
                outputFiles: [outputURL]
            )
        }
    }
}
