# t484 — OCS/Node Engine

**OCS/Node Engine for OCS/Display**  
C++20 protocol core + optional Qt 6 / QML **interactive chat** and **protocol console**.

Part of the Orion Collective System (OCS v2.1).  
Canonical product repo for the `ocs-node-engine` skill.

The chat transcript **is** the living protocol document. Host turns are `⫻flow/chat:host`; KickForge / KickFlow / KickGuard reply as first-class sections. Halt remains a first-class command.

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
| `t484` chat shell (`src/qml/main.qml`) | shipped |
| `t484-console` dashboard (`src/qml/console.qml`) | shipped |
| KickLangEditor / TasBoard / ConsentGateDialog | planned (Phase E) |

## Layout

```
include/ocsnode/          Section, parser, emitter, engine, coherence
include/ocsnode/qt/       QObject wrappers (Model / Item)
src/protocol/             STL parser + emitter
src/engine/               ProtocolEngine + Qt façade
src/components/           TasStatusModel, KlmxMoleculeItem
src/qml/main.qml          chat shell
src/qml/console.qml       protocol console shell
src/qml/OcsNode/          *View.qml + qmldir
src/assets/seed.ocs       startup protocol document (welcome turn)
tests/                    protocol round-trip
docs/ARCHITECTURE.md      module + naming freeze
docs/COMPONENTS.md        C++ / QML / protocol interface catalog
docs/CONSOLE.md           console layout and binding notes
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

## Chat (OCS)

Composer accepts:

- natural language → `⫻flow/chat:host` then Google GenAI **Interactions API** (`gemini-3.7-flash` unless `GEMINI_MODEL` is set)
- raw `⫻` sections (a `protocol/ocs` block replaces the document)
- `/mode` `/halt` `/exec` `/obj` `/tas` — `/halt` and `/mode` stay local (no LLM)

KickGuard blocks mutation **and** genai transport while gated except `/halt` and `/mode`. Resume by pasting a `⫻protocol/ocs` document without `⫻cmd/halt`.

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
⫻cmd/exec:ocs-node-engine
```

This repository is the source of truth. Skill `generated/` is staging only.

## License

To be determined. Active co-agency development by Denis Oliver Kropp / Exit.
