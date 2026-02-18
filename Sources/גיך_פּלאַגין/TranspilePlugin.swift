import PackagePlugin

@main
struct TranspilePlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // Phase 1 stub: no build commands yet
        return []
    }
}
