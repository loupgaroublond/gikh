# Gikh (גיך) — Yiddish Swift Transpiler

## What is this?

Gikh is a bidirectional transpiler that enables writing, reading, and distributing Swift code in Yiddish. The name גיך means "quick/fast" — a direct parallel to Swift.

## Current state

**Design phase.** No implementation exists yet. The design document (`gikh-design_4.md`) is a starting point for discussion, not a finalized spec.

## Design document

`gikh-design_4.md` contains the full design proposal. Key concepts:

- **Three modes**: Mode A (full English `.swift`), Mode B (full Yiddish `.gikh` — source of truth), Mode C (hybrid for compilation). All modes are lossless and round-trippable. The same transpiler mechanism converts between any two modes.

- **Two workflows, same mechanism**: B→C is the compiler workflow (keywords + ביבליאָטעק only, runs at build time). A↔B is the developer workflow (all dictionaries, runs at interaction time for importing/rendering code).

- **ביבליאָטעק**: The framework wrapper library. Source files *are* dictionary 2 — transpiler derives mappings directly from typealiases and wrappers. Two sections: core defaults (pre-built object code shipped with the tool) and project extensions (optional local `ביבליאָטעק/` directory). Every symbol fully translated — function names, parameter labels, properties, everything. The submodule יסוד (Yesod) specifically wraps Foundation.

- **Compiler integration**: Two steps — (1) transpile `.gikh` → Mode C in memory (no intermediate files on disk), (2) link ביבליאָטעק object code into the final binary. Project ביבליאָטעק extensions are built and linked too. Result: `gikh compile main.gikh` produces a working program.

- **Keywords compiled in**: Closed, finite set compiled into the transpiler binary.

- **Translation approval workflow**: Every English-to-Yiddish translation must be reviewed and approved by the user before being committed to any dictionary.

## Development approach

- **Tests first**: Write all tests before implementation code. Tests are immutable once written (except bug fixes).

- **Compiler integration first** (Phase 1): Wire the full pipeline as a stub — passes `.gikh` through unchanged (Mode C content), compiles it, links ביבליאָטעק. Proves end-to-end toolchain integration before any transpilation logic exists. Phase 2 replaces the stub with real B→C conversion.

- **ביבליאָטעק coverage is scoped to examples**: Only translate enough framework surface for the example apps to be 100% Yiddish. Comprehensive coverage is a future goal.

- **No unit tests for ביבליאָטעק**: The wrappers are mechanical 1:1 translations. 100% test coverage applies to the transpiler itself.

- **Five example apps**: CLI tool, SwiftUI app, Charts app, SwiftData app, and a document-based Gikh code viewer (opens .gikh files, syntax highlighting, RTL rendering, file tree, multi-file tiling). All are Xcode projects (xcodegen). GUI apps compile to .app packages.

- **100% Yiddish in examples**: All example app source is entirely RTL Yiddish `.gikh` files. No English identifiers anywhere. No exceptions.

- **No generated artifacts**: No `.gikh/generated/` directory. Mode A and Mode C copies are for human consumption only, produced on demand. All tools accept `.gikh` directly.

## Intended tech stack

- Swift, SwiftPM, xcodegen
- SwiftPM build plugin for transparent `.gikh` compilation + ביבליאָטעק linking
- YAML for project dictionaries and common-words reference only (keywords compiled in, ביבליאָטעק mappings derived from source)

## Key constraint

The translation approval workflow is non-negotiable. No dictionary entry ships without explicit user approval. This applies to all four dictionary tiers.
