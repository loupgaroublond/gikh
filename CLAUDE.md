# Gikh (גיך) — Yiddish Swift Transpiler

## What is this?

Gikh is a bidirectional transpiler that enables writing, reading, and distributing Swift code in Yiddish. The name גיך means "quick/fast" — a direct parallel to Swift.

## Current state

**Design phase.** No implementation exists yet. The design document (`gikh-design_4.md`) is a starting point for discussion, not a finalized spec.

## Design document

`gikh-design_4.md` contains the full design proposal. Key concepts:

- **Three modes**: Mode A (full English `.swift`), Mode B (full Yiddish `.gikh` — source of truth), Mode C (hybrid for compilation). All modes are lossless and round-trippable. The same transpiler mechanism converts between any two modes.

- **Two workflows, same mechanism**: B→C is the compiler workflow (keywords + ביבליאָטעק only, runs at build time). A↔B is the developer workflow (all dictionaries, runs at interaction time for importing/rendering code).

- **ביבליאָטעק**: The framework wrapper library providing Yiddish names for Apple SDK symbols via `typealias` and `@_transparent` wrappers. Zero runtime overhead. The source files *are* dictionary 2 — the transpiler derives mappings directly from them. The submodule יסוד (Yesod) specifically wraps Foundation. The transpiler links ביבליאָטעק so `swift compile main.gikh` just works.

- **Keywords compiled in**: The keyword dictionary is compiled directly into the transpiler binary. It's a closed, finite set that only changes when Swift adds new keywords.

- **Translation approval workflow**: Every English-to-Yiddish translation must be reviewed and approved by the user before being committed to any dictionary.

## Development approach

- **Build plugin first** (Phase 1): The SwiftPM build plugin is a stub from day one, so `.gikh` files compile directly throughout development. If the plugin API allows it, pipe generated Swift to the compiler without writing intermediate files.

- **ביבליאָטעק coverage is scoped to examples**: Only translate enough framework surface for the example apps to be 100% Yiddish. Comprehensive coverage is a future goal.

- **No unit tests for ביבליאָטעק**: The wrappers are mechanical 1:1 translations. 100% test coverage applies to the transpiler itself.

- **Five example apps**: CLI tool, SwiftUI app, Charts app, SwiftData app, and a Gikh code viewer (macOS app with file tree, syntax highlighting, multi-file tiling).

## Intended tech stack

- Swift, SwiftPM
- SwiftPM build plugin for transparent `.gikh` compilation
- YAML for project dictionaries and common-words reference only (keywords compiled in, ביבליאָטעק mappings derived from source)

## Key constraint

The translation approval workflow is non-negotiable. No dictionary entry ships without explicit user approval. This applies to all four dictionary tiers.
