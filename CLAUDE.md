# Gikh (גיך) — Yiddish Swift Transpiler

## What is this?

Gikh is a bidirectional transpiler that enables writing, reading, and distributing Swift code in Yiddish. The name גיך means "quick/fast" — a direct parallel to Swift.

## Current state

**Fully implemented across 6 phases.** The transpiler is working end-to-end: scanning, tokenizing, translating, and round-tripping between Mode A (English Swift), Mode B (Yiddish .gikh), and Mode C (hybrid for compilation).

## Build commands

```bash
swift build               # build all targets
swift test                # run all 211 tests
swift run גיך             # run the CLI transpiler
```

## Architecture

Five targets in `Sources/`:

- **GikhCore** — core transpiler: scanner, tokenizer, BiMap, Lexicon, Translator, Transpiler, BidiAnnotator, ScanPipeline
- **ביבליאָטעק** — Yiddish wrappers for Swift/Apple frameworks (SwiftUI, Foundation, AppKit, Charts, SwiftData, ArgumentParser). Source files derive the identifier dictionary directly.
- **גיך** — CLI executable (`swift run גיך`). Bundles `Dictionaries/` as a resource.
- **גיך_פּלאַגין** — SwiftPM build tool plugin. Invokes `gikh-transpile` to transpile `.gikh` → Mode C at build time.
- **gikh-transpile** — helper executable called by the build plugin.

## Tests

Two test suites in `Tests/`:

- **GikhTests** — transpiler unit tests (BiMap, Scanner, Lexicon, Translator, Transpiler, BidiAnnotator, round-trips, end-to-end compile)
- **ScanPipelineTests** — scan pipeline tests (SymbolExtractor, SwiftInterfaceParser, ScanOutputFormatter, LexiconSuggest, SDKVersionDiff, CoverageChecker)

Run: `swift test` — 211 tests total.

## Example apps

Five example apps in `Examples/`, each with `.gikh` source and a `project.yml` for xcodegen:

| Directory | App name | Type |
|-----------|----------|------|
| `שורה_כּלי/` | שורה_כּלי | CLI tool (text analysis) |
| `דאַטן_אַפּ/` | רעצעפּט_אַפּ | SwiftData recipe app |
| `טשאַרטן_אַפּ/` | וועטער_אַפּ | Charts weather dashboard |
| `קאָד_בליקער/` | קאָד_בליקער | AppKit .gikh code viewer with file tree |
| `באַניצער_פֿלאַך_אַפּ/` | צעטל_אַפּ | SwiftUI task list |

All source is 100% Yiddish `.gikh` files. Each example has a `לעקסיקאָן.yaml` with project-specific identifier translations.

To generate Xcode projects (`.xcodeproj` files are gitignored, generated on demand):

```bash
cd Examples/<example-dir> && xcodegen generate
```

## Key files

- `Package.swift` — package definition (targets: GikhCore, ביבליאָטעק, גיך, גיך_פּלאַגין, gikh-transpile)
- `Sources/GikhCore/Transpiler.swift` — main transpile entry point
- `Sources/GikhCore/Lexicon.swift` — loads and merges all dictionary tiers
- `Sources/GikhCore/BiMap.swift` — bidirectional map used for translation
- `Sources/GikhCore/Scanner.swift` — tokenizes Swift/Gikh source
- `Sources/ביבליאָטעק/` — framework wrapper source (also serves as dictionary tier 2)
- `Dictionaries/` — YAML dictionaries (keywords compiled in, common-words reference)
- `gikh-design_4.md` — original design document

## Dictionary tiers

1. Keywords — compiled into the binary (closed set)
2. ביבליאָטעק — derived from typealias/wrapper source files
3. Project YAML — `לעקסיקאָן.yaml` in each project root
4. Common-words reference — `Dictionaries/` YAML files

Translation approval is non-negotiable: no entry ships without explicit user approval.
