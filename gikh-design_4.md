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

- **Tests first.** Write all tests before writing a line of implementation code. Once a test is written, it must not be substantially modified except to fix bugs in the test itself. The test suite is the spec.
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
5. **A Gikh code viewer** — a document-based macOS app that opens `.gikh` files. Renders code RTL with syntax highlighting. File tree sidebar and multi-file tiling in a single window.

The ביבליאָטעק wrappers only need to cover enough framework surface for these example apps to be written 100% in Yiddish. Comprehensive framework coverage is a future goal, not a requirement for this initial version.

Every example app must be:
- **Entirely in Yiddish** — all `.gikh` source files are RTL, no English identifiers anywhere. No exceptions.
- **An Xcode project** — generated via xcodegen (`project.yml` in each example directory).
- **A proper .app** — GUI apps compile into `.app` packages; the CLI tool compiles into an executable.
- **Fully functional** — builds without warnings, passes all tests.

### Development Phases

The agent should approach the build in this order:

1. **Phase 1: Compiler integration (stub)** — Wire the full pipeline into the Swift toolchain before writing any transpilation logic. The stub passes `.gikh` input through unchanged (meaning Phase 1 code is Mode C — valid Swift with Yiddish identifiers). This proves the end-to-end integration: build plugin accepts `.gikh` files, feeds content to the compiler, compiles and links ביבליאָטעק object code into the final binary. Everything works before any B→C conversion exists.
2. **Phase 2: Core transpiler** — Scanner, Translator, BiDi Annotator, BiMap, Lexicon loader, CLI. Dictionary files (starting with keywords, then expanding). Round-trip tests. Once complete, the Phase 1 stub is replaced with real B→C transpilation — `.gikh` files can now contain actual Mode B (RTL Yiddish) code.
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

Standard Swift. Already legible to any English-speaking developer. This is either source code to be converted into a Gikh project, or standard Swift code that needs no further processing. Not stored in version control or distributed as part of a Gikh project.

- **Extension:** `.swift`
- **Base direction:** LTR
- **Keywords:** English
- **Identifiers:** English
- **BiDi markers:** None
- **Purpose:** Source to be imported into Gikh, or rendered output for English-speaking readers

### Mode B: Full Yiddish

The human-readable, distributable source of truth. Optimized for the Yiddish-reading developer — every design decision in this mode prioritizes human legibility over mechanical simplicity. RTL base direction. Yiddish keywords and identifiers. Mirrored characters (brackets, braces, parens) render naturally via Unicode's RTL mirroring. Slashes are flipped so they lean correctly in RTL. The transpiler uses syntactically-aware conversion (not string find-and-replace) to handle slashes, BiDi annotations, and other RTL concerns correctly in context, leaving strings, comments, and regex literals untouched.

- **Extension:** `.gikh`
- **Base direction:** RTL
- **Keywords:** Yiddish
- **Identifiers:** Yiddish
- **BiDi markers:** Yes (isolates around tokens as needed)
- **Slash handling:** `/` and `\` flipped vs Mode C so they lean correctly in RTL (see below)
- **Purpose:** Reading, writing, distributing Yiddish source code

### Mode C: Hybrid (Compilation Format)

Meant for the compiler, not humans. Shares all keywords, operators, and syntactic characters with standard Swift — the only difference from Mode A is that identifiers are in Yiddish. This keeps the conversion rules as simple as possible: swap keywords, strip BiDi markers, flip slashes back. No complex logic needed. The Yiddish identifiers survive into compiler diagnostics, so error messages reference the same names the developer uses in Mode B.

- **Extension:** `.swift` (transient, in-memory only)
- **Base direction:** LTR
- **Keywords:** English
- **Identifiers:** Yiddish
- **BiDi markers:** None
- **Purpose:** Compiler input (generated in memory from Mode B, never written to disk during builds)

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

In Mode B (RTL), slashes are flipped — `/` becomes `\` and `\` becomes `/` — because they visually lean the wrong way in right-to-left rendering. The transpiler flips all slashes in code tokens during mode conversion. String literal text content, comments, and regex literals are opaque and never modified. However, string interpolation delimiters (`\(...)`) are syntactic — the backslash in them is flipped like any other slash, so `\(expr)` becomes `/(expr)` in Mode B.

### How it looks in RTL

Division operator — the `/` in Mode C becomes `\` in Mode B so it leans correctly in RTL:

**Mode B:**

<div dir="rtl">

```gikh
לאָז תּוצאָה = א \ ב
```

</div>

**Mode C:**
```swift
let תּוצאָה = א / ב
```

**Mode A:**
```swift
let result = a / b
```

Keypath prefix — the `\` in Mode C becomes `/` in Mode B:

**Mode B:**

<div dir="rtl">

```gikh
לאָז וועג = /מענטש.נאָמען
```

</div>

**Mode C:**
```swift
let וועג = \מענטש.נאָמען
```

**Mode A:**
```swift
let path = \Person.name
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

Dictionary 2 has two sections:

1. **Core defaults** — baked into the pre-built object code that ships with the Gikh tool. These are the ביבליאָטעק source files in the main package.
2. **Project extensions** — optional `.swift` files in the project's own `ביבליאָטעק/` directory, providing wrappers for framework symbols not yet covered by core.

The union of both sections forms Dictionary 2. Not a hand-maintained YAML — derived from the source files. Every `typealias` and `@_transparent` wrapper implicitly defines a dictionary entry. A YAML equivalent can be derived where needed, but B ↔ C conversion does not require it — the `.swift` extension files provide all the Yiddish symbols natively in Swift.

Representative examples of what the source files define:

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
    /// Text content is opaque, but interpolation delimiters (\( and ))
    /// are syntactic — the backslash in \( is flipped during mode conversion.
    private mutating func scanStringLiteral(
        _ tokens: inout [Token]
    ) -> Bool {
        // Handles all four forms, tracks nesting for interpolations.
        // Returns text segments as opaque tokens, interpolation
        // delimiters as flippable tokens, interpolated expressions
        // as normal scannable code.
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

Every symbol is translated — type names, function names, parameter labels, property names. In Mode B, a developer never sees an English identifier.

```swift
// ביבליאָטעק/טיפּן/סטרינג.swift
import Foundation

public typealias סטרינג = String

extension String {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ עלעמענט: Character) { append(עלעמענט) }
    @_transparent public func מיט_פּרעפֿיקס(_ פּרעפֿיקס: סטרינג) -> Bool { hasPrefix(פּרעפֿיקס) }
    @_transparent public func מיט_סופֿיקס(_ סופֿיקס: סטרינג) -> Bool { hasSuffix(סופֿיקס) }
    @_transparent public func פֿאַרבינדן(טרענער: סטרינג) -> סטרינג { self }  // placeholder
}
```

```swift
// ביבליאָטעק/טיפּן/מאַסיוו.swift
public typealias מאַסיוו = Array

extension Array {
    @_transparent public var צאָל_פֿון: Int { count }
    @_transparent public var איז_ליידיק: Bool { isEmpty }
    @_transparent public mutating func צולייגן(_ נײַ_עלעמענט: Element) { append(נײַ_עלעמענט) }
    @_transparent public func פֿילטער(_ איז_אַרײַנגענומען: (Element) throws -> Bool) rethrows -> [Element] { try filter(איז_אַרײַנגענומען) }
    @_transparent public func מאַפּע<T>(_ איבערמאַכן: (Element) throws -> T) rethrows -> [T] { try map(איבערמאַכן) }
    @_transparent public func רעדוצירן<T>(_ אָנהייב_ווערט: T, _ קאָמבינירן: (T, Element) throws -> T) rethrows -> T { try reduce(אָנהייב_ווערט, קאָמבינירן) }
    @_transparent public func סאָרטירט(דורך זענען_אין_סדר: (Element, Element) throws -> Bool) rethrows -> [Element] { try sorted(by: זענען_אין_סדר) }
}
```

```swift
// ביבליאָטעק/נעץ/נעץ_זיצונג.swift
import Foundation

public struct נעץ_זיצונג {
    @usableFromInline internal let _session: URLSession

    @_transparent
    public init(קאָנפֿיגוראַציע: URLSessionConfiguration = .default) {
        _session = URLSession(configuration: קאָנפֿיגוראַציע)
    }

    @_transparent
    public func דאַטן(פֿון אַדרעס: URL) async throws -> (Data, URLResponse) {
        try await _session.data(from: אַדרעס)
    }

    @_transparent
    public func דאַטן(פֿאַר בקשה: URLRequest) async throws -> (Data, URLResponse) {
        try await _session.data(for: בקשה)
    }
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
    @_transparent public func פּאַדינג(_ זײַטן: Edge.Set = .all, _ לענג: CGFloat? = nil) -> some View { self.padding(זײַטן, לענג) }
    @_transparent public func אונטערלייג(_ סטיל: some ShapeStyle) -> some View { self.background(סטיל) }
    @_transparent public func פֿאָרגרונט_פֿאַרב(_ פֿאַרב: Color) -> some View { self.foregroundStyle(פֿאַרב) }
    @_transparent public func שריפֿט(_ שריפֿט: Font?) -> some View { self.font(שריפֿט) }
    @_transparent public func בלעטער_טיטל(_ טיטל: String) -> some View { self.navigationTitle(טיטל) }
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
public func דרוק(_ זאַכן: Any..., טרענער: String = " ", סוף: String = "\n") {
    print(זאַכן.map { "\($0)" }.joined(separator: טרענער), terminator: סוף)
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
│   │   ├── project.yml           # xcodegen spec
│   │   ├── Package.swift
│   │   └── Sources/              # .gikh files only (100% Yiddish)
│   ├── SwiftUIApp/               # Example: SwiftUI application
│   │   ├── לעקסיקאָן.yaml
│   │   ├── project.yml
│   │   ├── Package.swift
│   │   └── Sources/
│   ├── ChartsApp/                # Example: Swift Charts
│   │   ├── לעקסיקאָן.yaml
│   │   ├── project.yml
│   │   ├── Package.swift
│   │   └── Sources/
│   ├── DataApp/                  # Example: SwiftData
│   │   ├── לעקסיקאָן.yaml
│   │   ├── project.yml
│   │   ├── Package.swift
│   │   └── Sources/
│   └── CodeViewer/               # Example: document-based Gikh code viewer (macOS)
│       ├── לעקסיקאָן.yaml
│       ├── project.yml
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
├── project.yml                  # xcodegen spec
├── Sources/
│   ├── מענטש.gikh               # Mode B — source of truth
│   ├── אײַנשטעלונגען.gikh
│   └── ראַשי.gikh               # main
└── ביבליאָטעק/                   # Optional: project-local framework wrappers
    └── ...                      # typealiases/wrappers for symbols not yet in core
```

There is no `.gikh/generated/` directory. The compiler integration transpiles `.gikh` → Mode C in memory and feeds it directly to the Swift compiler. No intermediate `.swift` files are written to disk during compilation. Mode A or Mode C copies of the code exist only for human consumption — the `gikh to-english` and `gikh to-hybrid` CLI commands produce them on demand, not as build artifacts.

At build time, the build plugin uses keywords (compiled into the transpiler) and ביבליאָטעק mappings (derived from source files) to transpile `.gikh` → Mode C. It compiles and links core ביבליאָטעק (shipped as pre-built object code with the tool) into the final binary. If the project has a local `ביבליאָטעק/` directory, the compiler also builds and links those extensions. Tools accept `.gikh` files directly — no conversion step required.

---

## Pure Gikh Code Examples

Each example shows all three modes side by side: Mode B (what the Yiddish developer writes and reads), Mode C (what the compiler sees), and Mode A (full English).

**Note on string literals:** The transpiler treats the text content of string literals as opaque — it passes through unchanged in all three modes. The Mode A examples below show Yiddish text inside strings because that's what round-tripping from Mode B produces. In practice, Mode A code written by an English-speaking developer would have English strings.

However, string interpolation delimiters (`\(...)`) are syntactic, and the backslash in them is flipped like any other slash. In Mode B, `\(expr)` becomes `/(expr)`. The transpiler recognizes interpolation boundaries and flips the escape character while leaving the string content and the interpolated expression untouched.

### Hello World

**Mode B** (.gikh — source of truth, RTL):

<div dir="rtl">

```gikh
אימפּאָרט יסוד

דרוק("!שלום וועלט")
```

</div>

**Mode C** (compiler input — English keywords, Yiddish identifiers):
```swift
import Foundation

דרוק("!שלום וועלט")
```

**Mode A** (full English):
```swift
import Foundation

print("!שלום וועלט")
```

### A struct with methods

**Mode B:**

<div dir="rtl">

```gikh
סטרוקטור מענטש {
    לאָז נאָמען: סטרינג
    לאָז עלטער: צאָל

    פֿונקציע באַשרײַב() -> סטרינג {
        צוריק "/(נאָמען) איז /(עלטער) יאָר אַלט"
    }

    פֿונקציע איז_דערוואַקסן() -> באָאָל {
        צוריק עלטער >= 18
    }
}

לאָז יענקל = מענטש(נאָמען: "יענקל", עלטער: 30)
דרוק(יענקל.באַשרײַב())
```

</div>

**Mode C:**
```swift
struct מענטש {
    let נאָמען: סטרינג
    let עלטער: צאָל

    func באַשרײַב() -> סטרינג {
        return "\(נאָמען) איז \(עלטער) יאָר אַלט"
    }

    func איז_דערוואַקסן() -> באָאָל {
        return עלטער >= 18
    }
}

let יענקל = מענטש(נאָמען: "יענקל", עלטער: 30)
דרוק(יענקל.באַשרײַב())
```

**Mode A:**
```swift
struct Person {
    let name: String
    let age: Int

    func describe() -> String {
        return "\(name) איז \(age) יאָר אַלט"
    }

    func isAdult() -> Bool {
        return age >= 18
    }
}

let yankl = Person(name: "יענקל", age: 30)
print(yankl.describe())
```

### Array operations with closures (demonstrating slash flip)

**Mode B:**

<div dir="rtl">

```gikh
לאָז צאָלן = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

לאָז גראַדע = צאָלן.פֿילטער { $0 % 2 == 0 }
לאָז סכום = גראַדע.רעדוצירן(0) { $0 + $1 }

דרוק("סכום פֿון גראַדע צאָלן: /(סכום)")
```

</div>

**Mode C:**
```swift
let צאָלן = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

let גראַדע = צאָלן.פֿילטער { $0 % 2 == 0 }
let סכום = גראַדע.רעדוצירן(0) { $0 + $1 }

דרוק("סכום פֿון גראַדע צאָלן: \(סכום)")
```

**Mode A:**
```swift
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

let evens = numbers.filter { $0 % 2 == 0 }
let sum = evens.reduce(0) { $0 + $1 }

print("סכום פֿון גראַדע צאָלן: \(sum)")
```

### A SwiftUI view

**Mode B:**

<div dir="rtl">

```gikh
אימפּאָרט באַניצער_פֿלאַך

סטרוקטור באַגריסונג_בליק: בליק {
    @צושטאַנד פּריוואַט באַשטימען נאָמען = ""

    באַשטימען גוף: עטלעכע בליק {
        שטאַפּל_וו(אויסריכטונג: .צענטער, אָפּשטאַנד: 20) {
            טעקסט("!שלום וועלט")
                .שריפֿט(.טיטל)
                .פֿאָרגרונט_פֿאַרב(.בלוי)

            קנעפּל("דריק מיך") {
                דרוק("!געדריקט")
            }
            .פּאַדינג()
            .אונטערלייג(.ראָזע)
        }
    }
}
```

</div>

**Mode C:**
```swift
import SwiftUI

struct באַגריסונג_בליק: בליק {
    @צושטאַנד private var נאָמען = ""

    var גוף: some בליק {
        שטאַפּל_וו(אויסריכטונג: .צענטער, אָפּשטאַנד: 20) {
            טעקסט("!שלום וועלט")
                .שריפֿט(.טיטל)
                .פֿאָרגרונט_פֿאַרב(.בלוי)

            קנעפּל("דריק מיך") {
                דרוק("!געדריקט")
            }
            .פּאַדינג()
            .אונטערלייג(.ראָזע)
        }
    }
}
```

**Mode A:**
```swift
import SwiftUI

struct GreetingView: View {
    @State private var name = ""

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("!שלום וועלט")
                .font(.title)
                .foregroundStyle(.blue)

            Button("דריק מיך") {
                print("!געדריקט")
            }
            .padding()
            .background(.pink)
        }
    }
}
```

### Async networking (demonstrating slash flip on division)

**Mode B:**

<div dir="rtl">

```gikh
פֿונקציע הייבן_דאַטן(פֿון אַדרעס: סטרינג) אַסינכראָן וואַרפֿט -> דאַטן {
    לאָז זיצונג = נעץ_זיצונג()
    לאָז (דאַטן, _) = פּרובירן וואַרטן זיצונג.דאַטן(פֿון: URL(סטרינג: אַדרעס)!)
    לאָז גרייס = דאַטן.צאָל_פֿון \ 1024
    דרוק("באַקומען /(גרייס) קב")
    צוריק דאַטן
}
```

</div>

**Mode C:**
```swift
func הייבן_דאַטן(פֿון אַדרעס: סטרינג) async throws -> דאַטן {
    let זיצונג = נעץ_זיצונג()
    let (דאַטן, _) = try await זיצונג.דאַטן(פֿון: URL(סטרינג: אַדרעס)!)
    let גרייס = דאַטן.צאָל_פֿון / 1024
    דרוק("באַקומען \(גרייס) קב")
    return דאַטן
}
```

**Mode A:**
```swift
func fetchData(from address: String) async throws -> Data {
    let session = URLSession()
    let (data, _) = try await session.data(from: URL(string: address)!)
    let size = data.count / 1024
    print("באַקומען \(size) קב")
    return data
}
```

Note: in the networking example, the `\` in Mode B `דאַטן.צאָל_פֿון \ 1024` is the division operator — slashes are flipped in RTL. In Mode C and Mode A it's `/` as usual. Similarly, the string interpolation `/(גרייס)` in Mode B becomes `\(גרייס)` in Mode C and Mode A.

---

## Requirements

These requirements supplement the agent instructions at the top of this document.

### ביבליאָטעק completeness

Every symbol must be fully translated in Mode B. This means:
- Every function and method has every parameter label translated.
- Every class and struct has every stored property and computed property translated.
- Every enum has every case and associated value label translated.
- Every protocol has every requirement translated.
- No English identifiers appear in Mode B code. None.

### Compiler integration

The compiler integration performs two steps:

1. **Transpile** — convert `.gikh` (Mode B) to Mode C by swapping keywords and ביבליאָטעק symbols. This produces valid Swift code with Yiddish identifiers.
2. **Link** — link the pre-built ביבליאָטעק object code into the final binary so all Yiddish typealiases and wrappers resolve.

ביבליאָטעק must be compiled into object code as part of building the Gikh tool itself. This object code ships with the tool and is linked into every Gikh program's output.

When a project has its own `ביבליאָטעק/` extensions, the compiler integration must accept these as a parameter, build them into object code, and link them into the final result alongside core ביבליאָטעק.

The end result: `gikh compile main.gikh` produces a working program. No manual steps.

### No generated artifacts

There is no concept of keeping generated `.swift` files on disk as part of the build process. The transpiler produces Mode C in memory and passes it to the compiler. Mode A and Mode C copies exist only for human consumption, produced on demand by `gikh to-english` and `gikh to-hybrid`.

All tools must accept `.gikh` files as input without complaint.

### Example apps as Xcode projects

All example projects must also be Xcode projects, generated via xcodegen (`project.yml`). GUI apps must compile into `.app` packages. The CLI tool compiles into an executable.

### Test-first development

All tests must be written before any implementation code. Once a test is written, it must not be substantially modified except to fix bugs in the test itself. The test suite is the contract.

### 100% Yiddish in example apps

All example apps must be entirely RTL Yiddish in their `.gikh` source files. Every identifier, every parameter label, every string that represents a UI element — all in Yiddish. No exceptions. This is the proof that the system works end to end.

### Code viewer requirements

The code viewer example app must be:
- A document-based macOS app that opens `.gikh` files directly.
- Syntax highlighting of Gikh code (keywords, identifiers, strings, comments in distinct colors).
- Proper RTL rendering of all code content.
- File tree sidebar for browsing project directories.
- Multi-file tiling in a single window.
