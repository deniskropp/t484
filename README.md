# t484 — OCS/Node Engine

**OCS/Node Engine for OCS/Display**  
C++20 protocol core + optional Qt 6 / QML **interactive chat** and **protocol console**.

Part of the Orion Collective System (OCS v2.1).  
Canonical product repo for the `ocs-node-engine` skill.

The chat transcript **is** the living protocol document. Host turns are `flow/chat:host`; KickForge / KickFlow / KickGuard reply as first-class sections. Halt remains a first-class command.

**Docs:** [docs/INDEX.md](docs/INDEX.md) — architecture, protocol grammar, engine, chat turns, operator runbook, build, OCS integration, glossary.

Visual system: [docs/THEME.md](docs/THEME.md). Every QML surface as a plate: [docs/PANELS.md](docs/PANELS.md).

Next surface (plan only): [docs/plans/v0.6/](docs/plans/v0.6/) — OCS/Node Nexus + one-file KickLang export. Fixture: [`src/assets/nexus-v0.6.ocs`](src/assets/nexus-v0.6.ocs).

## Status (v0.4 — chat + protocol console)

| Piece | State |
|---|---|
| `src/protocol/` parser + emitter | shipped |
| `ProtocolEngine` / `NodeEngine` | shipped |
| `ChatSession` (append-only turns) | shipped |
| protocol tests (no Qt) | shipped |
| `ProtocolEngineQt` + `SectionListModel` | shipped (needs Qt6) |
| `TasStatusModel` + `TasStatusBarView` | shipped |
| `KlmxMoleculeItem` + `KlmxMoleculeSpaceView` | shipped |
| `OcsChatTranscriptView` + `OcsComposerView` | shipped |
| `OcsSectionView` bound to engine model | shipped |
| `Theme` singleton (OCS Slate) | shipped |
| `t484` chat shell (`src/qml/main.qml`) | shipped |
| `t484-console` dashboard (`src/qml/console.qml`) | shipped |
| KickLangEditor / TasBoard / ConsentGateDialog | planned (Phase E / v0.5) |
| OCS/Node Nexus one-file export | planned ([v0.6](docs/plans/v0.6/)) |

## Layout

```
include/ocsnode/          Section, parser, emitter, engine, coherence
include/ocsnode/qt/       QObject wrappers (Model / Item)
src/protocol/             STL parser + emitter
src/engine/               ProtocolEngine + Qt façade
src/components/           TasStatusModel, KlmxMoleculeItem
src/qml/main.qml          chat shell
src/qml/console.qml       protocol console shell
src/qml/OcsNode/          Theme.qml + *View.qml + qmldir
src/assets/seed.ocs       startup protocol document (welcome turn)
src/assets/nexus-v0.6.ocs v0.6 Nexus snapshot (plan fixture)
tests/                    protocol round-trip
docs/INDEX.md             documentation map
docs/ARCHITECTURE.md      module + naming freeze
docs/PROTOCOL.md          ⫻ grammar as implemented
docs/ENGINE.md            document engine, halt, coherence
docs/CHAT.md              ChatSession turn machine
docs/OPERATOR.md          run chat / console / GenAI
docs/BUILD.md             CMake targets and tests
docs/OCS-INTEGRATION.md   Node inside OCS v2.1
docs/GLOSSARY.md          terms
docs/COMPONENTS.md        C++ / QML / protocol interface catalog
docs/CONSOLE.md           console layout and binding notes
docs/THEME.md             OCS Slate tokens
docs/PANELS.md            every surface rendered
docs/plans/v0.6/          Nexus export + volumetric coherence plan
docs/images/              SVG plates
```

C++ type and QML file never share an identifier.

## Build

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
./build/ocsnode_protocol_tests src/assets/seed.ocs
```

Qt 6 display (when Qt6 is on `CMAKE_PREFIX_PATH`):

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build build
./build/t484              # compact chat
./build/t484-console      # three-pane protocol console
./build/t484 --console    # same console from the chat binary
```

Full operator notes: [docs/OPERATOR.md](docs/OPERATOR.md). Full CMake map: [docs/BUILD.md](docs/BUILD.md).

## Chat (OCS)

Composer accepts:

- natural language → host turn then Google GenAI **Interactions API** (`gemini-3.7-flash` unless `GEMINI_MODEL` is set)
- raw protocol sections (a `protocol/ocs` block replaces the document)
- `/mode` `/halt` `/exec` `/obj` `/tas` — `/halt` and `/mode` stay local (no LLM)

KickGuard blocks mutation **and** genai transport while gated except `/halt` and `/mode`. Resume by pasting a protocol document without halt.

```bash
export GEMINI_API_KEY="…"    # https://aistudio.google.com/apikey
# optional:
export GEMINI_MODEL="gemini-3.7-flash"   # falls back to 3.6 then 3.5 on high demand
./build/t484
./build/t484 --genai-status   # prints ready/source/model (never the key)
./build/t484 --genai-debug    # lists every env name and .env path checked
```

A KDE/Grok GUI launch **does not inherit** an interactive-shell `export`. t484 looks up, in order:

1. Process env: `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `GOOGLE_GENAI_API_KEY`, `GOOGLE_AI_API_KEY`
2. `.env` in the working directory, next to the binary, `../.env`, `~/.config/t484/.env`, `$XDG_RUNTIME_DIR/t484.env`

The key is never written into the protocol document. Calls use `POST https://generativelanguage.googleapis.com/v1beta/interactions` with `x-goog-api-key` and chain turns via `previous_interaction_id`.

## OCS Integration

```
cmd/exec:ocs-node-engine
```

This repository is the source of truth. Skill `generated/` is staging only.
How the Node sits next to protocol-export, enforcer, Berlin Node, and Flow Nexus: [docs/OCS-INTEGRATION.md](docs/OCS-INTEGRATION.md).

## License

To be determined. Active co-agency development by Denis Oliver Kropp / Exit.
