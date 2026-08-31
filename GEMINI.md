# t484 — OCS/Node Engine

C++20 canonical protocol core plus optional Qt 6 / QML **interactive chat** and **protocol console** for Orion Collective System (OCS v2.1). Canonical product repo for `ocs-node-engine`.

The chat transcript **is** the living protocol document (`flow/chat` turns + three-agent replies). There is no parallel message store. Halt is first-class. Natural-language Send uses the Google GenAI **Interactions API** (`POST /v1beta/interactions`, default model `gemini-3.7-flash`) with `GEMINI_API_KEY`.

**Shipped product: v0.4** (CMake `0.4.0`). Next major surface is **v0.6 OCS/Node Nexus** — plan only, see [docs/plans/v0.6/](docs/plans/v0.6/).

## Status

| Version | What |
|---|---|
| v0.2 | STL protocol core, QML views, engine bindings |
| v0.3 | OCS chat, `flow/chat`, GenAI Interactions API |
| **v0.4 (shipped)** | `t484-console` three-pane dashboard, `EventLogModel`, OCS Slate theme, shared `OcsNode` QML module |
| **v0.5 (planned)** | Phase E UI: KickLangEditorView, TasBoardView, ConsentGateDialog |
| **v0.6 (plan only)** | Volumetric Coherence Nexus + lossless one-file KickLang export/import |

Do not claim v0.6 shipped until `nexus-v0.6.ocs` round-trips in `ocsnode_protocol_tests` and export/import is wired. `src/assets/seed-nexus.ocs` is a **loadable v0.6.0-pre** fixture; it does **not** replace `seed.ocs`.

| Piece | State |
|---|---|
| `src/protocol/` parser + emitter | shipped |
| `ProtocolEngine` / `NodeEngine` / `ChatSession` | shipped |
| protocol tests (no Qt) | shipped |
| `ProtocolEngineQt` + `SectionListModel` + `GenAiClient` | shipped (needs Qt6) |
| `TasStatusModel` + `KlmxMoleculeItem` + `EventLogModel` | shipped |
| Chat views + `t484` (`main.qml`) | shipped |
| Console views + `t484-console` (`console.qml`) | shipped |
| `Theme` singleton (OCS Slate Dark / Light) | shipped |
| KickLangEditorView / TasBoardView / ConsentGateDialog | planned (Phase E / v0.5) |
| `cmd/exec:nexus-export` + one-file import | implemented; full v0.6 Nexus (Phase E + bridge) still planned |

## Project structure

```
include/ocsnode/          Section, parser, emitter, engine, coherence, ChatSession
include/ocsnode/qt/       QObject wrappers (Model / Item) + GenAiClient
src/protocol/             STL parser, emitter, ChatSession
src/engine/               ProtocolEngine, ProtocolEngineQt, SectionListModel, GenAiClient
src/components/           TasStatusModel, KlmxMoleculeItem, EventLogModel
src/qml/main.qml          compact chat shell
src/qml/console.qml       three-pane protocol console
src/qml/OcsNode/          Theme.qml + *View.qml + qmldir
src/assets/seed.ocs       startup protocol document (welcome turn)
src/assets/seed-nexus.ocs loadable v0.6.0-pre Nexus seed (halt-free)
src/assets/nexus-v0.6.ocs v0.6 plan fixture (one-file KickLang export)
tests/                    protocol round-trip + GenAI parse (no network)
docs/ARCHITECTURE.md      module + naming freeze
docs/COMPONENTS.md        C++ / QML / protocol interface catalog
docs/CONSOLE.md           console layout and binding notes
docs/THEME.md             OCS Slate tokens
docs/PANELS.md            every surface as a plate
docs/plans/v0.6/          Nexus export + volumetric coherence plan
```

CMake layout (Qt present): static `ocsnode_protocol` → `ocsnode_engine` → `ocsnode_qml` (`URI OcsNode` **once**). `t484` and `t484-console` both link `ocsnode_qml`. `qt_add_qml_module` cannot write URI `OcsNode` twice into the same output directory.

## Building and running

Requires CMake and a C++20 compiler. Qt 6 is optional (`Core`, `Gui`, `Qml`, `Quick`, `QuickControls2`, `Network`).

### Protocol core (no Qt)

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
./build/ocsnode_protocol_tests src/assets/seed.ocs
```

### Full Qt 6 display

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build build
./build/t484                 # compact chat
./build/t484-console         # three-pane protocol console
./build/t484 --console       # console from the chat binary
./build/t484-console --chat  # compact shell from the console binary
./build/t484 --genai-status  # ready/source/model (never the key)
./build/t484 --genai-debug   # env names and .env paths checked
```

Tests: `ocsnode_protocol_tests` (STL only) and `ocsnode_genai_tests` (Qt Core+Network, parse/dotenv only). No test talks to the network.

## Chat (OCS)

Composer accepts:

- natural language → `flow/chat:host` then GenAI (`gemini-3.7-flash` unless `GEMINI_MODEL` is set)
- raw protocol sections (a `protocol/ocs` block **loads** / replaces the document)
- `/mode` `/halt` `/exec` `/obj` `/tas` — `/halt` and `/mode` stay local (no LLM)

KickGuard blocks mutation **and** GenAI transport while gated except `/halt` and `/mode`. Resume by loading a protocol document **without** `cmd/halt`. No invented `cmd/resume`.

```bash
export GEMINI_API_KEY="…"    # https://aistudio.google.com/apikey
# optional:
export GEMINI_MODEL="gemini-3.7-flash"   # falls back to 3.6 then 3.5 on high demand
```

A KDE/Grok GUI launch does **not** inherit an interactive-shell `export`. Key lookup order:

1. Process env: `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `GOOGLE_GENAI_API_KEY`, `GOOGLE_AI_API_KEY`
2. `.env` walk: `T484_SOURCE_DIR`, cwd, next to the binary, `../.env`, `~/.config/t484/.env`, `~/.config/Exit/t484/.env`, `$XDG_RUNTIME_DIR/t484.env`

The key is never written into a `Section`. Calls use `POST https://generativelanguage.googleapis.com/v1beta/interactions` with `x-goog-api-key` and chain turns via `previous_interaction_id`.

QML shells must bind children with `protocol: appWindow.protocol` (alias of context `engine`). A child `property var engine` plus `engine: engine` self-binds to `null` (Send becomes a no-op).

## Protocol surface (implemented subset)

```
⫻protocol/ocs:
⫻context/...
⫻cmd/exec: | ⫻cmd/halt: | ⫻cmd/mode: | ⫻cmd/lang:
⫻data/obj: | ⫻data/tas: | ⫻data/ptas:
⫻flow/chat:<host|KickForge|KickFlow|KickGuard>
⫻query/clarify:
⫻display/...
```

Parser is line-oriented (`⫻` U+2AFB). A section runs until the next sigil or EOF. Nested `⫻end/` is recognized but not expanded.

- **submit** replaces the first section of the same type (state: mode, halt, obj, tas, klmx).
- **append** always pushes (conversation: `flow/chat`, `query/clarify`, `cmd/exec`, `display/content`).

## Development conventions

- **Naming (frozen):** C++ models `*Model` / `*Item`; QML views `*View.qml`. A C++ type and a QML file must **never** share an identifier (`KickLangEditor` vs `KickLangEditorView.qml`).
- **Source of truth:** this repository. Skill `generated/` is staging only.
- **Shells:** do not invent `ProtocolEngineQt` properties for console chrome. Derive call counts / latency in QML from existing signals (`turnCompleted`, `busy`). Logs go through `EventLogModel` (context `eventLogModel`).
- **Theme:** every QML color comes from the `Theme` singleton (`docs/THEME.md`). Dark is product; Light is the accessibility twin. No ad-hoc hex in views.
- **API freeze:** treat `include/ocsnode/*.h` as the public surface unless the operator explicitly opens it.

## Planning (v0.5 / v0.6)

Roadmap: [docs/plans/v0.6/README.md](docs/plans/v0.6/README.md). Grammar: [NEXUS-EXPORT.md](docs/plans/v0.6/NEXUS-EXPORT.md). TAS: [TAS.md](docs/plans/v0.6/TAS.md).

Living objective:

```
⫻data/obj:
Make t484 a Nexus whose entire operator state is one KickLang/OCS file — exportable, re-ingestible, consent-gated.
```

Non-goals: no new section families; no keys in the export; no parallel chat store; no `cmd/resume`.

| ID | Step | State |
|---|---|---|
| N0 | Freeze export grammar + fixture parses today | plan artifacts landed |
| N1 | `protocol/ocs` stamp `[version=0.6.0] [repo=deniskropp/t484] [ref=main]` | written into fixture |
| N2 | `cmd/exec:nexus-export` → `exportNexus()` + header; no key material | implemented (`/exec nexus-export`, `importNexus` = `loadText`) |
| N3 | Volumetric axes on `CoherenceState` (scalar kept) | axes fields filled; Qt genai overlay on export |
| N4 | KickLangEditorView + TasBoardView + ConsentGateDialog (Phase E / v0.5) | named; identifiers reserved |
| N5 | CoherenceMonitorBridge adapter behind `deriveCoherence` | noted; heuristic stays |
| N6 | Round-trip tests + console “Export Nexus” action | implemented |
| N7 | Berlin Node / EmbodiedPipe grounding | optional, not critical path |

Volumetric axes (additive; status bar still shows scalar `coherence ∈ [0,1]`): `protocol`, `klmx`, `objective`, `tas`, `consent`, `dialogue`, `genai` (Qt-only health, never a secret in the file). Export records axes in `display/meta`.

Import is existing behavior: paste or load a document that contains `protocol/ocs`. Export while gated is allowed (read). Import that contains `cmd/halt` stays gated.

Implementation that mutates `src/` still needs an explicit operator go (KickGuard). Plan files and fixtures may land without that gate.

## OCS integration

```
cmd/exec:ocs-node-engine
```

This repository is the source of truth.
