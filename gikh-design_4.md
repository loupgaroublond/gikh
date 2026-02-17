# גיך (Gikh) — A Yiddish Swift Transpiler

<div dir="rtl"><strong>ס׳איז Swift פֿאַר ייִדן</strong></div>

---

## Agent Instructions

This document serves as both a design reference and a development prompt. The agent building this project must follow these instructions precisely.

### Translation Approval Workflow

**Every English-to-Yiddish translation must be reviewed and approved by the user before it is committed to any dictionary.** The agent must not unilaterally decide on translations. The workflow is:

1. The agent proposes a batch of translations (e.g., 10–20 at a time) with rationale for each choice — etymology, register, alternatives considered.
2. The user approves, rejects, or modifies each translation.
3. Only approved translations are added to the relevant dictionary.
4. The agent must track approval status and never ship unapproved translations into any dictionary or wrapper code.

This applies to all four dictionary tiers: keywords, standard library, macOS APIs, and the common-words defaults dictionary.

### Code Quality Requirements

- **100% code coverage on the transpiler.** Every line of the transpiler — scanner, translator, BiDi annotator, BiMap, lexicon loader — must be covered by tests. The ביבליאָטעק wrappers are mechanical 1:1 translations and do not require unit tests.
- **Zero warnings, zero errors.** The project must build and test with `-warnings-as-errors` enabled. No deprecation warnings, no unused variable warnings, no compiler remarks. The build must be completely clean.
- **Round-trip verification.** Every test suite must include round-trip tests: Mode B → Mode C → Mode B must produce identical output. Mode A → Mode B → Mode A must produce identical output.
- **`gikh verify` must pass** on every CI run with zero diffs.

### Example Applications

The agent must build a suite of example applications that exercise prominent Apple ecosystem APIs. These apps serve as both integration tests for ביבליאָטעק coverage and demonstrations of Gikh in practice. Each must be fully functional and written entirely in Yiddish (Mode B `.gikh` files as source of truth).

The agent may propose the specific apps creatively and discuss choices with the user, but the suite must include **at minimum**:

1. **A CLI tool** — demonstrates Foundation, ArgumentParser, file I/O, networking, and string processing in a terminal context.
2. **A SwiftUI app** — demonstrates views, state management, navigation, modifiers, shapes, colors, gestures, and animations.
3. **A Swift Charts app** — demonstrates data visualization with Charts framework wrappers.
4. **A SwiftData app** — demonstrates persistence with @Model, ModelContainer, FetchDescriptor, and queries.
5. **A Gikh code viewer** — a native macOS app for browsing Gikh projects. File tree sidebar, syntax-highlighted `.gikh` source display, and tiling of multiple files in a single window.

The ביבליאָטעק wrappers only need to cover enough framework surface for these example apps to be written 100% in Yiddish. Comprehensive framework coverage is a future goal, not a requirement for this initial version.

The apps may be small/trivial in scope but must be fully functional, build without warnings, and pass all tests. They may be written in English first and then converted to Yiddish via the transpiler, or written directly in Yiddish — either path is acceptable as long as the final distributed form is Mode B `.gikh` files.

### Development Phases

The agent should approach the build in this order:

1. **Phase 1: SwiftPM build plugin (stub)** — Wire the transpiler as a build plugin from the start, so `.gikh` files compile seamlessly throughout development. Start with a minimal stub that transpiles `.gikh` → Mode C and feeds the result to the compiler. If SwiftPM's plugin API supports it, pipe the generated Swift directly to the compiler without writing intermediate files to disk.
2. **Phase 2: Core transpiler** — Scanner, Translator, BiDi Annotator, BiMap, Lexicon loader, CLI. Dictionary files (starting with keywords, then expanding). Round-trip tests.
3. **Phase 3: ביבליאָטעק foundation** — stdlib typealiases and wrappers, יסוד (Foundation) wrappers, global function wrappers. Expand dictionaries with user-approved translations.
4. **Phase 4: Scan pipeline** — The external codebase scanner that identifies untranslated symbols without modifying the target project.
5. **Phase 5: Framework wrappers (scoped to examples)** — Translate enough SwiftUI, CoreGraphics, SwiftData, Charts, and other framework surface for the example apps to be 100% Yiddish. Comprehensive coverage is a future goal.
6. **Phase 6: Example apps** — Build the example suite, using the scan pipeline to identify coverage gaps, expanding ביבליאָטעק as needed.

---

## Overview

Gikh is a bidirectional transpiler that enables writing, reading, and distributing Swift code in Yiddish. It maintains three lossless, round-trippable representations of the same source code, each optimized for a different audience.

The name גיך means "quick/fast" in Yiddish — a direct conceptual parallel to Swift.

---

## The Three Modes

### Mode A: Full English

Standard Swift. LTR. No BiDi characters. English keywords, English identifiers. This is not stored in version control or distributed — it exists only as a debug/inspection artifact or as an entry point for integrating existing Swift code into a Gikh project.

- **Extension:** `.swift`
- **Base direction:** LTR
- **Keywords:** English
- **Identifiers:** English
- **BiDi markers:** None
- **Purpose:** Debug inspection, onboarding existing code

### Mode B: Full Yiddish

The human-readable, distributable source of truth. RTL base direction. Yiddish keywords and identifiers. Mirrored characters (brackets, braces, parens) render naturally via Unicode's RTL mirroring. Slashes are flipped relative to Mode C so they lean correctly when rendered right-to-left. The transpiler flips all slashes in code tokens, leaving strings, comments, and regex literals untouched. This mode is about readability first and foremost.

- **Extension:** `.gikh`
- **Base direction:** RTL
- **Keywords:** Yiddish
- **Identifiers:** Yiddish
- **BiDi markers:** Yes (isolates around tokens as needed)
- **Slash handling:** `/` and `\` flipped vs Mode C so they lean correctly in RTL (see below)
- **Purpose:** Reading, writing, distributing Yiddish source code

### Mode C: Hybrid (Compilation Format)

English keywords with Yiddish identifiers. LTR base direction. No BiDi characters. This is the format the Swift compiler sees. The Yiddish identifiers survive into compiler diagnostics, so error messages reference the same names the developer uses in Mode B.

- **Extension:** `.swift` (generated, gitignored)
- **Base direction:** LTR
- **Keywords:** English
- **Identifiers:** Yiddish
- **BiDi markers:** None
- **Purpose:** Compiler input (auto-generated from Mode B by the build plugin)

### Mode relationships

```
Mode A (Full English)
  .swift
  Standard Swift code
       │
       │  gikh to-yiddish (developer workflow, all dictionaries)
       ▼
Mode B (Full Yiddish)          ◄── Source of truth, stored in VCS
  .gikh
  RTL, Yiddish keywords,
  Yiddish identifiers,
  BiDi annotations
       │
       │  Build plugin auto-transpiles (keywords + ביבליאָטעק only)
       ▼
Mode C (Hybrid)                ◄── Transient compilation artifact
  .swift (generated)
  LTR, English keywords,
  Yiddish identifiers,
  No BiDi characters
       │
       │  swiftc compiles normally (links ביבליאָטעק)
       ▼
    Binary
```

All three modes are 1:1 mappings. Any mode can convert to any other mode losslessly.

---

## Slash Handling in Mode B

In Mode B (RTL), slashes are flipped — `/` becomes `\` and `\` becomes `/` — because they visually lean the wrong way in right-to-left rendering. The transpiler flips all slashes in code tokens during mode conversion. String literals, comments, and regex literals are opaque tokens and are never modified.

### How it looks in RTL

Division operator — the `/` in Mode C becomes `\` in Mode B so it leans correctly in RTL:

<div dir="rtl"><pre>
לאָז תּוצאָה = א \ ב
</pre></div>

Mode C (LTR):
```swift
let תּוצאָה = א / ב
```

Keypath prefix — the `\` in Mode C becomes `/` in Mode B:

<div dir="rtl"><pre>
לאָז וועג = /מענטש.נאָמען
</pre></div>

Mode C (LTR):
```swift
let וועג = \מענטש.נאָמען
```

---

## Dictionaries and Workflows

The same transpiler mechanism converts between any two modes. What differs is *when* it runs, *why*, and *which dictionaries are in play*.

### Compiler workflow: B → C

This is the hot path. The build plugin transpiles `.gikh` → Mode C `.swift` and feeds it to the compiler. It uses only two sources of translation:

1. **Keywords** — a closed, finite set compiled directly into the transpiler binary. Changes only when Swift adds new keywords.
2. **ביבליאָטעק mappings** — derived automatically from the ביבליאָטעק source files themselves. The typealiases and wrappers *are* the dictionary. No separate YAML to maintain.

The transpiler also links ביבליאָטעק so the Yiddish type names and wrappers resolve at compile time. The goal: `swift compile main.gikh` just works.

Projects can also ship their own ביבליאָטעק extensions — typealiases and wrappers for framework symbols not yet covered by the core package. Dictionary 2 is the union of core ביבליאָטעק and project-local ביבליאָטעק, derived the same way from source files. A project doesn't have to wait for core Gikh to translate a framework — it can bridge the gap locally.

### Developer workflow: A ↔ B

This runs at interaction time — when importing existing Swift into a Gikh project (A → B), or rendering Yiddish back to English for someone who doesn't read Yiddish (B → A). These workflows need the full dictionary stack:

1. **Keywords** — same as above.
2. **ביבליאָטעק mappings** — same as above.
3. **Project identifiers** — the per-project dictionary for developer-created names.
4. **Common words** — advisory only, used by `gikh lexicon --suggest` to propose translations.

### Dictionary 1: Keywords

The Swift language keyword dictionary. A closed, finite set — it maps every Swift keyword and attribute to its Yiddish equivalent. Compiled into the transpiler binary. Changes only when Swift adds new keywords.

```yaml
keywords:
  פֿונקציע: func
  לאָז: let
  באַשטימען: var
  צוריק: return
  אויב: if
  אַנדערש: else
  פֿאַר: for
  אין: in
  בשעת: while
  סטרוקטור: struct
  קלאַס: class
  פּראָטאָקאָל: protocol
  היטער: guard
  וועקסל: switch
  פֿאַל: case
  ברעכן: break
  ממשיכן: continue
  טאָן: do
  כאַפּן: catch
  וואַרפֿן: throw
  וואַרפֿט: throws
  אַסינכראָן: async
  וואַרטן: await
  סטאַטיש: static
  פּריוואַט: private
  עפֿנטלעך: public
  אינערלעך: internal
  פּראָפּערטי: property
  פֿאַרלענגערונג: extension
  אימפּאָרט: import
  # ... complete Swift keyword set
```

### Dictionary 2: ביבליאָטעק Mappings

Not a hand-maintained YAML — derived from the ביבליאָטעק source files. Every `typealias` and `@_transparent` wrapper in ביבליאָטעק implicitly defines a dictionary entry. The transpiler reads these at build time. Representative examples of what the source files define:

**stdlib types and members:**
```
סטרינג ↔ String       צאָל ↔ Int          טאָפּל ↔ Double
פֿלאָוט ↔ Float        באָאָל ↔ Bool         מאַסיוו ↔ Array
ווערטערבוך ↔ Dictionary  סעט ↔ Set          אָפּציע ↔ Optional
דרוק ↔ print          צאָל_פֿון ↔ count     איז_ליידיק ↔ isEmpty
צולייגן ↔ append       פֿילטער ↔ filter     מאַפּע ↔ map
```

**Framework types (Foundation, SwiftUI, etc.):**
```
דאַטום ↔ Date          נעץ_זיצונג ↔ URLSession    בליק ↔ View
טעקסט ↔ Text          קנעפּל ↔ Button             רשימה ↔ List
צושטאַנד ↔ State       בינדונג ↔ Binding           פּאַדינג ↔ padding
```

### Dictionary 3: Project Identifiers

The per-project dictionary. Lives in the project root, contains only identifiers specific to this codebase. Small, human-maintained, versioned with the project. Only needed for A ↔ B developer workflows — not for compilation.

```yaml
# Project root: ./לעקסיקאָן.yaml
tier: project

identifiers:
  באַרעכן: calculate
  מענטש: Person
  נאָמען: name
  עלטער: age
  באַשרײַב: describe
  אָנהייבן: initialize
  פֿאַרבינדונג: connection
  אײַנשטעלונגען: settings
```

### Dictionary 4: Common Words Defaults

A reference dictionary of common English programming terms translated to Yiddish. This is **not** used directly by the transpiler — it serves as a guide and a reasonable set of defaults that developers can draw from when naming their project identifiers. Think of it as a phrasebook for Yiddish programming.

When a developer runs `gikh lexicon --suggest`, the tool consults this dictionary to propose translations. The developer then approves or modifies the suggestions before they're added to their project dictionary.

```yaml
# Bundled in Gikh package: Dictionaries/common-words.yaml
tier: defaults
description: >
  Common English programming words with recommended Yiddish translations.
  Not used directly by the transpiler. Serves as a reference for developers
  and as the basis for `gikh lexicon --suggest`.

words:
  # Actions
  initialize: אָנהייבן
  configure: אײַנשטעלן
  validate: באַשטעטיקן
  process: באַאַרבעטן
  transform: איבערמאַכן
  execute: אויספֿירן
  handle: באַהאַנדלען
  create: שאַפֿן
  delete: אויסמעקן
  update: דערהײַנטיקן
  fetch: ברענגען
  send: שיקן
  receive: באַקומען
  load: לאָדן
  save: אָפּהיטן
  parse: צעטיילן
  render: אויסשטעלן
  display: ווײַזן
  connect: פֿאַרבינדן
  disconnect: אָפּבינדן
  enable: אָנמאַכן
  disable: אָפּמאַכן
  start: אָנהייבן
  stop: אָפּשטעלן
  reset: צוריקשטעלן
  cancel: אָפּזאָגן
  retry: פּרובירן_ווידער
  complete: פֿאַרענדיקן
  fail: דורכפֿאַלן
  succeed: באַגליקן

  # Data / state
  value: ווערט
  result: רעזולטאַט
  error: פֿעלער
  state: צושטאַנד
  status: סטאַטוס
  count: צאָל_פֿון
  index: אינדעקס
  key: שליסל
  name: נאָמען
  title: טיטל
  description: באַשרײַבונג
  message: מעלדונג
  request: בקשה
  response: ענטפֿער
  data: דאַטן
  content: אינהאַלט
  item: פּונקט
  list: רשימה
  collection: זאַמלונג
  source: מקור
  destination: ציל
  input: אײַנגאַב
  output: אויסגאַב
  settings: אײַנשטעלונגען
  options: אָפּציעס
  config: קאָנפֿיגוראַציע
  path: וועג
  url: אַדרעס
  identifier: אידענטיפֿיקאַטאָר
  token: צייכן
  session: זיצונג
  cache: באַהעלטעניש
  buffer: פּופֿער
  queue: רײ
  stack: שטאַפּל

  # UI
  view: בליק
  screen: עקראַן
  page: בלאַט
  button: קנעפּל
  label: עטיקעט
  image: בילד
  icon: סימבאָל
  color: פֿאַרב
  font: שריפֿט
  size: גרייס
  width: ברייט
  height: הייך
  margin: ראַנד
  padding: פּאַדינג
  border: געצוים
  visible: זעיק
  hidden: באַהאַלטן
  selected: אויסגעקליבן
  enabled: אָנגעמאַכט
  disabled: אָפּגעמאַכט
  animated: אַנימירט
  gesture: געסט
  tap: טאַפּ
  swipe: וויש
  drag: שלעפּ
  scroll: בלעטער

  # Common patterns
  delegate: דעלעגאַט
  observer: באָאָבאַכטער
  listener: צוהערער
  handler: באַהאַנדלער
  factory: פֿאַבריק
  builder: בויער
  manager: פֿאַרוואַלטער
  controller: קאָנטראָלער
  provider: צושטעלער
  service: דינסט
  repository: אוצר
  model: מאָדעל
  entity: ענטיטעט
  component: באַשטאַנדטייל
  module: מאָדול
  plugin: פּלאַגין
  wrapper: אײַנוויקלער
  adapter: אַדאַפּטער
  converter: קאָנווערטער
  formatter: פֿאָרמאַטירער
  validator: באַשטעטיקער
  serializer: סעריאַליזירער
  parser: צעטיילער
  mapper: מאַפּער
  reducer: רעדוצירער
  filter: פֿילטער
  sorter: סאָרטירער
  logger: לאָגער
  debugger: דעבאַגער
  profiler: פּראָפֿילער
  tester: פּראָבירער
```

### Dictionary loading by workflow

**Compiler workflow (B → C):**
1. **Keywords** — compiled into the transpiler binary
2. **ביבליאָטעק mappings** — derived from ביבליאָטעק source files

**Developer workflow (A ↔ B):**
1. **Keywords** — same
2. **ביבליאָטעק mappings** — same
3. **Project identifiers** (`./לעקסיקאָן.yaml`) — loaded if present
4. **Common words** — loaded only by `gikh lexicon --suggest`, never by the transpiler itself

Priority on lookup: keywords → ביבליאָטעק → project. If a word matches in an earlier tier, that match wins. The BiMap enforces bijectivity across the merged set. Dictionary 4 is advisory only and is never part of the merge.

### Automatic passthrough

There are no explicit passthrough lists. Any identifier not found in any dictionary is automatically passed through untranslated. The scan pipeline flags these as untranslated symbols — the presumption is that serious Gikh users will use the scan and lexicon tools to create project-specific translations for everything in their codebase.

### Collision detection

The BiMap enforces bijectivity across the merged dictionary (tiers 1–3). If a project identifier collides with a built-in mapping, `gikh lexicon --add` rejects it and explains the conflict. If a Gikh version update introduces a new built-in mapping that collides with an existing project identifier, `gikh verify` catches it at build time.

---

## The External Codebase Scanner

Gikh includes a scan pipeline that analyzes any Swift codebase — without modifying it or converting it to Gikh — and produces a list of symbols that would need translation coverage in order to fully support that codebase in Yiddish.

This is the primary tool for planning ביבליאָטעק expansion and for onboarding new projects.

### How it works

1. The scanner compiles the target project normally (or reads its `.swiftinterface` / type-checked AST if already built).
2. It extracts every symbol referenced: types, functions, properties, protocol conformances, operators, enum cases.
3. It checks each symbol against the merged dictionary (tiers 1–3).
4. Symbols found in the dictionary are marked as covered.
5. Symbols not found are reported as untranslated, grouped by framework/module.

### CLI usage

```
gikh scan /path/to/SomeProject/                 # scan a project directory
gikh scan --built /path/to/SomeProject/.build/   # scan built artifacts
gikh scan --interface /path/to/Framework.swiftinterface  # scan interface file
gikh scan /path/to/project --format table        # human-readable (default)
gikh scan /path/to/project --format yaml         # machine-readable
gikh scan /path/to/project --format diff         # only untranslated symbols
```

### Example output

```
$ gikh scan ~/Projects/WeatherApp/

Scanning WeatherApp...
  Compiled successfully.
  Found 247 unique symbols.

Coverage: 189/247 (76.5%)

Untranslated symbols by module:

  Foundation (12 uncovered):
    DateComponentsFormatter        → ?
    MeasurementFormatter           → ?
    Locale                         → ?
    TimeZone                       → ?
    ...

  WeatherKit (23 uncovered):
    WeatherService                 → ?
    CurrentWeather                 → ?
    HourlyForecast                 → ?
    ...

  CoreLocation (8 uncovered):
    CLLocationManager              → ?
    CLGeocoder                     → ?
    ...

  Project identifiers (15 uncovered):
    WeatherViewModel               → ?
    LocationService                → ?
    ForecastCard                   → ?
    ...

Run `gikh scan --format yaml` for machine-readable output.
Run `gikh lexicon --suggest --from-scan` to get translation proposals.
```

### Integration with lexicon --suggest

The scan output feeds directly into the suggestion pipeline:

```
$ gikh lexicon --suggest --from-scan ~/Projects/WeatherApp/

Proposed translations (from common-words dictionary + analysis):

  Framework symbols (add to ביבליאָטעק):
    WeatherService      → וועטער_דינסט
    CurrentWeather      → איצטיקע_וועטער
    HourlyForecast      → שעהדיקע_פֿאָרויסזאָג
    ...

  Project identifiers (add to project לעקסיקאָן.yaml):
    WeatherViewModel    → וועטער_מאָדעל_בליק
    LocationService     → אָרט_דינסט
    ForecastCard        → פֿאָרויסזאָג_קאַרטל
    ...

Approve translations? [review each / approve all / edit]
```

The user reviews and approves each translation per the agent instructions above.

---

## Transpiler Architecture

```
┌─────────────────────────────────────────────────┐
│                    gikh                          │
│                                                  │
│  ┌───────────┐    ┌───────────┐    ┌──────────┐ │
│  │  Lexer /  │    │   Token   │    │  BiDi    │ │
│  │  Scanner  │───▶│ Translator│───▶│ Annotator│ │
│  └───────────┘    └───────────┘    └──────────┘ │
│       │                                   │      │
│  Preserves:                          Mode B:     │
│  - String literals               - RLM/LRM      │
│  - Comments                      - Isolates     │
│  - Whitespace                    - Slash subs   │
│  - Structure                                     │
│                                  Mode A/C:       │
│                                  - Strip all     │
└─────────────────────────────────────────────────┘
```

### Core data types

```swift
enum Token {
    case keyword(String, Range<String.Index>)
    case identifier(String, Range<String.Index>)
    case stringLiteral(String, Range<String.Index>)  // preserved verbatim
    case comment(String, Range<String.Index>)         // preserved verbatim
    case whitespace(String, Range<String.Index>)      // preserved verbatim
    case punctuation(String, Range<String.Index>)     // preserved verbatim
    case operatorToken(String, Range<String.Index>)   // preserved verbatim
    case numberLiteral(String, Range<String.Index>)   // preserved verbatim
    case unknown(String, Range<String.Index>)         // preserved verbatim
}

enum Direction {
    case toEnglish   // יידיש → English
    case toYiddish   // English → יידיש
}

enum TargetMode {
    case modeA  // Full English
    case modeB  // Full Yiddish (.gikh)
    case modeC  // Hybrid (compilation)
}
```

### Lexicon

```swift
struct Lexicon: Codable {
    // Dictionary 1: Keywords (compiled into the transpiler)
    let keywords: BiMap<String, String>

    // Dictionary 2: Derived from ביבליאָטעק source files
    let bibliotek: BiMap<String, String>

    // Dictionary 3: Project identifiers (per-project, developer workflow only)
    let identifiers: BiMap<String, String>

    /// Compiler workflow: loads keywords + ביבליאָטעק mappings only.
    static func forCompilation(
        bibliotekPath: String
    ) throws -> Lexicon {
        // keywords are compiled in
        // ביבליאָטעק mappings derived from source files
        // no project identifiers needed for B → C
    }

    /// Developer workflow: loads all dictionaries.
    static func forDeveloper(
        bibliotekPath: String,
        projectPath: String = "./לעקסיקאָן.yaml"
    ) throws -> Lexicon {
        // keywords + ביבליאָטעק + project identifiers
        // validates bijectivity across merged set
    }
}
```

### BiMap — the foundation for round-trip fidelity

```swift
struct BiMap<Key: Hashable, Value: Hashable> {
    private var forward: [Key: Value]
    private var reverse: [Value: Key]

    init(_ pairs: [(Key, Value)]) {
        forward = Dictionary(uniqueKeysWithValues: pairs)
        reverse = Dictionary(uniqueKeysWithValues: pairs.map { ($1, $0) })

        precondition(forward.count == reverse.count,
            "Dictionary has duplicate values — mapping is not bijective")
    }

    func toValue(_ key: Key) -> Value? { forward[key] }
    func toKey(_ value: Value) -> Key? { reverse[value] }
}
```

### Scanner

```swift
struct Scanner {
    let source: String
    var position: String.Index

    // Contexts:
    // 1. Keywords       — translatable
    // 2. Identifiers    — translatable (if in dictionary)
    // 3. String literals — NEVER touch (including interpolations)
    // 4. Comments        — NEVER touch
    // 5. Everything else — NEVER touch

    mutating func scan() -> [Token] {
        var tokens: [Token] = []

        while position < source.endIndex {
            if scanStringLiteral(&tokens) { continue }
            if scanComment(&tokens) { continue }
            if scanWhitespace(&tokens) { continue }
            if scanNumber(&tokens) { continue }
            if scanPunctuation(&tokens) { continue }
            if scanOperator(&tokens) { continue }
            if scanWord(&tokens) { continue }

            let start = position
            let char = source[position]
            position = source.index(after: position)
            tokens.append(.unknown(String(char), start..<position))
        }

        return tokens
    }

    private mutating func scanWord(_ tokens: inout [Token]) -> Bool {
        let start = position

        guard let first = peek(),
              first.isSwiftIdentifierStart else { return false }

        advance()
        while let c = peek(), c.isSwiftIdentifierContinue {
            advance()
        }

        let word = String(source[start..<position])
        let range = start..<position

        if SwiftKeywords.all.contains(word) || isYiddishKeyword(word) {
            tokens.append(.keyword(word, range))
        } else {
            tokens.append(.identifier(word, range))
        }

        return true
    }

    /// String literals: single-line, multi-line, raw, interpolation.
    /// All returned as a single opaque token.
    private mutating func scanStringLiteral(
        _ tokens: inout [Token]
    ) -> Bool {
        // Handles all four forms, tracks nesting for
        // interpolations, returns entire literal as one opaque token
    }
}
```

### Translator

```swift
struct Translator {
    let lexicon: Lexicon
    let direction: Direction
    let mode: TranslationMode

    enum TranslationMode {
        case keywordsOnly   // Mode B ↔ Mode C
        case full           // Mode C ↔ Mode A, or Mode B ↔ Mode A
    }

    func translate(_ tokens: [Token]) -> [Token] {
        tokens.map { token in
            switch token {
            case .keyword(let word, let range):
                let translated = translateKeyword(word)
                return .keyword(translated, range)

            case .identifier(let word, let range):
                guard mode == .full else { return token }
                let translated = translateIdentifier(word)
                return .identifier(translated, range)

            default:
                return token
            }
        }
    }

    private func translateKeyword(_ word: String) -> String {
        switch direction {
        case .toEnglish:
            return lexicon.keywords.toValue(word) ?? word
        case .toYiddish:
            return lexicon.keywords.toKey(word) ?? word
        }
    }

    private func translateIdentifier(_ word: String) -> String {
        // No explicit passthrough — identifiers not in any dictionary
        // are returned unchanged automatically (the ?? word fallthrough).
        let maps = [
            lexicon.stdlibTypes,
            lexicon.stdlibMembers,
            lexicon.frameworkTypes,
            lexicon.frameworkMembers,
            lexicon.identifiers,
        ]

        for map in maps {
            switch direction {
            case .toEnglish:
                if let v = map.toValue(word) { return v }
            case .toYiddish:
                if let v = map.toKey(word) { return v }
            }
        }

        return word
    }
}
```

### BiDi Annotator

Handles BiDi control characters for Mode B output and strips them for Mode A/C. Flips slashes (`/` ↔ `\`) in all code tokens when emitting Mode B — string literals, comments, and regex literals are opaque and never touched.

```swift
struct BidiAnnotator {
    static let lri = "\u{2066}"  // Left-to-Right Isolate
    static let rli = "\u{2067}"  // Right-to-Left Isolate
    static let fsi = "\u{2068}"  // First Strong Isolate
    static let pdi = "\u{2069}"  // Pop Directional Isolate
    static let rlm = "\u{200F}"  // Right-to-Left Mark
    static let lrm = "\u{200E}"  // Left-to-Right Mark

    func annotate(_ tokens: [Token], target: TargetMode) -> String {
        switch target {
        case .modeB:
            return emitModeB(tokens)
        case .modeA, .modeC:
            return emitLTR(tokens)
        }
    }

    private func emitModeB(_ tokens: [Token]) -> String {
        var output = ""

        for token in tokens {
            switch token {
            case .keyword(let word, _),
                 .identifier(let word, _):
                if word.containsRTL {
                    output += "\(Self.rli)\(word)\(Self.pdi)"
                } else {
                    output += "\(Self.lri)\(word)\(Self.pdi)"
                }

            case .stringLiteral(let s, _):
                output += "\(Self.fsi)\(s)\(Self.pdi)"

            case .punctuation(let p, _):
                output += p
                if "({[".contains(p) {
                    output += Self.lrm
                }

            case .operatorToken(let op, _):
                output += "\(Self.lri)\(flipSlashes(op))\(Self.pdi)"

            case .whitespace(let ws, _),
                 .comment(let ws, _),
                 .numberLiteral(let ws, _),
                 .unknown(let ws, _):
                output += ws
            }
        }

        return output
    }

    private func emitLTR(_ tokens: [Token]) -> String {
        let bidiChars = CharacterSet(
            charactersIn: "\u{200E}\u{200F}\u{2066}\u{2067}\u{2068}\u{2069}\u{202A}\u{202B}\u{202C}\u{202D}\u{202E}"
        )

        return tokens
            .map { token in
                switch token {
                case .operatorToken(let op, _):
                    return flipSlashes(op)  // flip back for LTR
                default:
                    return token.text
                }
            }
            .joined()
            .unicodeScalars
            .filter { !bidiChars.contains($0) }
            .map { String($0) }
            .joined()
    }

    /// Swaps / ↔ \ so slashes lean correctly in each direction.
    private func flipSlashes(_ text: String) -> String {
        var result = ""
        for char in text {
            switch char {
            case "/":  result.append("\\")
            case "\\": result.append("/")
            default:   result.append(char)
            }
        }
        return result
    }
}
```

---

## ביבליאָטעק: The Framework Wrapper Library

ביבליאָטעק provides Yiddish names for Apple SDK symbols via typealiases and `@_transparent` wrappers. The source files *are* Dictionary 2 — the transpiler derives its mappings directly from the typealiases and wrappers defined here. No separate YAML to maintain. The name יסוד (Yesod, "foundation") is reserved specifically for the Foundation framework submodule.

### Inlining strategy: `@_transparent`

Every wrapper must compile to zero overhead. `@_transparent` inlines at the SIL level before optimization passes — the function ceases to exist at the call site unconditionally. This is what the Swift stdlib uses for trivial forwarding.

Fall back to `@_alwaysEmitIntoClient` only if `@_transparent` rejects a specific wrapper (recursive functions, `@objc` interop, complex generic constraints).

Verify inlining:

```bash
swiftc -emit-sil -O MyFile.swift -I ביבליאָטעק | grep פֿילטער
```

### Representative wrappers

```swift
// ביבליאָטעק/טיפּן/סטרינג.swift
import Foundation

public typealias סטרינג = String

extension String {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ element: Character) { append(element) }
}
```

```swift
// ביבליאָטעק/טיפּן/מאַסיוו.swift
public typealias מאַסיוו = Array

extension Array {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ newElement: Element) { append(newElement) }
    @_transparent public func פֿילטער(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] { try filter(isIncluded) }
    @_transparent public func מאַפּע<T>(_ transform: (Element) throws -> T) rethrows -> [T] { try map(transform) }
}
```

```swift
// ביבליאָטעק/נעץ/נעץ_זיצונג.swift
import Foundation

public struct נעץ_זיצונג {
    @usableFromInline internal let _session: URLSession
    @_transparent public init(קאָנפֿיגוראַציע: URLSessionConfiguration = .default) { _session = URLSession(configuration: קאָנפֿיגוראַציע) }
    @_transparent public func דאַטן(פֿון url: URL) async throws -> (Data, URLResponse) { try await _session.data(from: url) }
}
```

```swift
// ביבליאָטעק/באַניצער_פֿלאַך/בליקן.swift
import SwiftUI

public typealias בליק = View
public typealias טעקסט = Text
public typealias קנעפּל = Button
public typealias בילד = Image
public typealias רשימה = List
public typealias נאַוויגאַציע_שטאַפּל = NavigationStack
public typealias שטאַפּל_ה = HStack
public typealias שטאַפּל_וו = VStack
public typealias שטאַפּל_צ = ZStack
public typealias בלעטל = ScrollView
public typealias פּלאַצהאַלטער = Spacer
public typealias טיילער = Divider
```

```swift
// ביבליאָטעק/באַניצער_פֿלאַך/מאָדיפֿיקאַטאָרן.swift
import SwiftUI

extension View {
    @_transparent public func פּאַדינג(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View { self.padding(edges, length) }
    @_transparent public func אונטערלייג(_ style: some ShapeStyle) -> some View { self.background(style) }
    @_transparent public func פֿאָרגרונט_פֿאַרב(_ color: Color) -> some View { self.foregroundStyle(color) }
    @_transparent public func שריפֿט(_ font: Font?) -> some View { self.font(font) }
    @_transparent public func בלעטל_טיטל(_ title: String) -> some View { self.navigationTitle(title) }
}
```

```swift
// ביבליאָטעק/באַניצער_פֿלאַך/פֿאַרבן.swift
import SwiftUI

extension Color {
    @_transparent public static var רויט: Color { .red }
    @_transparent public static var בלוי: Color { .blue }
    @_transparent public static var גרין: Color { .green }
    @_transparent public static var ווײַס: Color { .white }
    @_transparent public static var שוואַרץ: Color { .black }
    @_transparent public static var גרוי: Color { .gray }
    @_transparent public static var געל: Color { .yellow }
    @_transparent public static var אָראַנזש: Color { .orange }
    @_transparent public static var לילאַ: Color { .purple }
    @_transparent public static var ראָזע: Color { .pink }
}
```

```swift
// ביבליאָטעק/גלאָבאַל/דרוק.swift
@_transparent
public func דרוק(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
}
```

### Framework coverage table

| ביבליאָטעק submodule | Wraps | Scope |
|---|---|---|
| `ביבליאָטעק/טיפּן` | Swift stdlib | All types, protocols, global functions |
| `ביבליאָטעק/יסוד` | Foundation | URL, Date, FileManager, JSONDecoder, Codable, NotificationCenter, UserDefaults |
| `ביבליאָטעק/נעץ` | Foundation networking | URLSession, URLRequest, URLResponse, URLCache |
| `ביבליאָטעק/פֿײַלן` | Foundation file I/O | FileManager, FileHandle, Data reading/writing |
| `ביבליאָטעק/באַניצער_פֿלאַך` | SwiftUI | Views, modifiers, layout, state, navigation, animations, gestures |
| `ביבליאָטעק/טשאַרטן` | Swift Charts | Chart, BarMark, LineMark, PointMark, AreaMark, RuleMark |
| `ביבליאָטעק/דאַטן_באַזע` | SwiftData | @Model, ModelContainer, ModelContext, FetchDescriptor, #Predicate |
| `ביבליאָטעק/קאָמבינע` | Combine | Publisher, Subscriber, Subject, operators |
| `ביבליאָטעק/פֿאַרוואַלטער` | UIKit (where needed) | UIViewController, UIApplication, UIScene, lifecycle |
| `ביבליאָטעק/גראַפֿיק` | CoreGraphics | CGFloat, CGPoint, CGSize, CGRect, CGAffineTransform |
| `ביבליאָטעק/אַנימאַציע` | CoreAnimation | CALayer, CAAnimation, CATransaction |
| `ביבליאָטעק/לאָקאַל` | MapKit / CoreLocation | CLLocationManager, MKMapView, coordinates |
| `ביבליאָטעק/מעדיע` | AVFoundation | AVPlayer, AVAudioSession, AVCaptureSession |
| `ביבליאָטעק/מיטטיילונגען` | UserNotifications | UNUserNotificationCenter, UNNotificationRequest |
| `ביבליאָטעק/זיכערהייט` | Security / CryptoKit | Keychain wrappers, hashing, encryption |
| `ביבליאָטעק/פּראָבירן` | XCTest | XCTestCase, assertions, expectations |
| `ביבליאָטעק/אַרגומענטן` | ArgumentParser | ParsableCommand, @Argument, @Option, @Flag |

---

## The swiftinterface Pipeline

SDK interface files live at:

```
$(xcrun --show-sdk-path)/usr/lib/swift/Foundation.swiftmodule/
    arm64-apple-ios.swiftinterface
```

These are plain-text Swift, parseable with `swift-syntax`. Diffing between SDK versions to identify new symbols needing translation is mechanical — an LLM can track Apple's API changes across releases.

```
$ gikh audit --compiled .build/
✓ All project identifiers covered
⚠ 3 Apple API symbols used but not in ביבליאָטעק:
  URLSession.shared           (Foundation)
  JSONDecoder.decode(_:from:) (Foundation)
  Color.accentColor           (SwiftUI)

Add wrappers to ביבליאָטעק, or add translations to the project לעקסיקאָן.
```

---

## CLI Reference

```
# Transpilation
gikh to-english  src/            # any mode → Mode A
gikh to-yiddish  src/            # any mode → Mode B (.gikh)
gikh to-hybrid   src/            # any mode → Mode C
gikh compile     src/            # B → C → swiftc (standard build)

# Dictionary management
gikh lexicon     --add person מענטש
gikh lexicon     --scan src/     # find untranslated identifiers
gikh lexicon     --suggest       # proposals from common-words dictionary
gikh lexicon     --suggest --from-scan /path/to/project

# External codebase scanning
gikh scan        /path/to/project           # analyze without modifying
gikh scan        --built /path/to/.build/   # analyze built artifacts
gikh scan        --interface /path/to/Framework.swiftinterface
gikh scan        --format yaml              # machine-readable output

# Validation
gikh verify      src/            # round-trip: B→C→B, diff
gikh audit       --compiled .build/         # check ביבליאָטעק coverage

# ביבליאָטעק
gikh bridge      --generate      # regenerate ביבליאָטעק wrappers
```

---

## Project Structure

```
גיך/
├── Sources/
│   ├── גיך/                     # CLI transpiler tool
│   │   ├── Scanner.swift
│   │   ├── Translator.swift
│   │   ├── BidiAnnotator.swift
│   │   ├── Lexicon.swift
│   │   ├── BiMap.swift
│   │   └── main.swift
│   │
│   ├── ביבליאָטעק/               # Framework wrappers
│   │   ├── טיפּן/                # Swift stdlib
│   │   ├── יסוד/                 # Foundation core (Yesod)
│   │   ├── נעץ/                  # Networking
│   │   ├── פֿײַלן/               # File I/O
│   │   ├── באַניצער_פֿלאַך/       # SwiftUI
│   │   ├── טשאַרטן/             # Swift Charts
│   │   ├── דאַטן_באַזע/          # SwiftData
│   │   ├── קאָמבינע/             # Combine
│   │   ├── פֿאַרוואַלטער/         # UIKit
│   │   ├── גראַפֿיק/             # CoreGraphics
│   │   ├── לאָקאַל/              # MapKit / CoreLocation
│   │   ├── מעדיע/               # AVFoundation
│   │   ├── מיטטיילונגען/        # UserNotifications
│   │   ├── זיכערהייט/           # Security / CryptoKit
│   │   ├── אַרגומענטן/          # ArgumentParser
│   │   ├── פּראָבירן/            # XCTest
│   │   └── גלאָבאַל/             # Global functions
│   │
│   └── גיך_פּלאַגין/             # SwiftPM build tool plugin
│       └── TranspilePlugin.swift
│
├── Dictionaries/
│   └── common-words.yaml         # Dictionary 4: common defaults (advisory)
│
├── Examples/
│   ├── CLITool/                  # Example: CLI application
│   │   ├── לעקסיקאָן.yaml        # Dictionary 3 for this example
│   │   ├── Package.swift
│   │   └── Sources/
│   ├── SwiftUIApp/               # Example: SwiftUI application
│   │   ├── לעקסיקאָן.yaml
│   │   ├── Package.swift
│   │   └── Sources/
│   ├── ChartsApp/                # Example: Swift Charts
│   │   ├── לעקסיקאָן.yaml
│   │   ├── Package.swift
│   │   └── Sources/
│   ├── DataApp/                  # Example: SwiftData
│   │   ├── לעקסיקאָן.yaml
│   │   ├── Package.swift
│   │   └── Sources/
│   └── CodeViewer/               # Example: Gikh code viewer (macOS)
│       ├── לעקסיקאָן.yaml
│       ├── Package.swift
│       └── Sources/
│
├── Package.swift
└── Tests/
    ├── GikhTests/                # Transpiler unit tests (100% coverage)
    │   ├── ScannerTests.swift
    │   ├── TranslatorTests.swift
    │   ├── BidiAnnotatorTests.swift
    │   ├── BiMapTests.swift
    │   ├── LexiconTests.swift
    │   └── RoundTripTests.swift
    └── ScanPipelineTests/        # Scanner pipeline tests (100% coverage)
        └── ScannerTests.swift
```

---

## File Format Conventions

A Gikh project on disk:

```
MyProject/
├── לעקסיקאָן.yaml               # Dictionary 3: project identifiers (A ↔ B only)
├── Package.swift
├── Sources/
│   ├── מענטש.gikh               # Mode B — source of truth
│   ├── אײַנשטעלונגען.gikh
│   └── ראַשי.gikh               # main
├── ביבליאָטעק/                   # Optional: project-local framework wrappers
│   └── ...                      # typealiases/wrappers for symbols not yet in core
└── .gikh/
    └── generated/               # gitignored
        ├── מענטש.swift           # Mode C — auto-generated for compiler
        ├── אײַנשטעלונגען.swift
        └── ראַשי.swift
```

At build time, the build plugin uses keywords (compiled into the transpiler) and ביבליאָטעק mappings (derived from source files) to transpile `.gikh` → Mode C. For developer workflows (A ↔ B), it also loads the project dictionary from `./לעקסיקאָן.yaml`. The `.gikh` files are the source of truth. If SwiftPM's plugin API supports it, the transpiler pipes generated Swift directly to the compiler without writing intermediate files to disk. Otherwise, Mode C output in `.gikh/generated/` is regenerated on every build and gitignored. Mode A output is never persisted.
