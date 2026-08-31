# t484 Architecture (v0.4 chat + protocol console)

Source of truth: this repository. The `ocs-node-engine` skill is the forge, not a second product tree.  
Component and QML/C++ interface catalog: [COMPONENTS.md](COMPONENTS.md).  
Console shell notes: [CONSOLE.md](CONSOLE.md).

The Qt shell is an **OCS-compliant chat**: the transcript is the protocol section list. No parallel message store. The protocol console is a second ApplicationWindow over the **same** engine, models, and views.

## Modules

| Module | Path | Depends on | Role |
|---|---|---|---|
| protocol | `include/ocsnode/*` + `src/protocol/` | C++20 STL only | Parse / emit ⫻ sections, `ChatSession` |
| engine | `src/engine/` | protocol + Qt6 Core | `ProtocolEngine` QObject, halt gate, coherence, `sendChat` |
| components | `src/components/` | Qt6 Core | QObject models (`*Model` / `*Item`) |
| qml | `src/qml/OcsNode/` + `main.qml` + `console.qml` | engine + components | Chat + console shells |
| tests | `tests/` | protocol | Round-trip + chat-turn fixtures, no Qt required |

## Naming (frozen)

| Kind | Pattern | Example |
|---|---|---|
| C++ model | `*Model` or `*Item` | `TasStatusModel`, `KlmxMoleculeItem` |
| QML view | `*View.qml` | `OcsChatTranscriptView.qml`, `TasStatusBarView.qml` |
| Engine | `ProtocolEngine`, `NodeEngine` | context property `engine`; shell alias `appWindow.protocol` |
| Section type string | `family/path` | `data/tas`, `context/klmx` |

Never register a C++ type and a QML file under the same identifier.

## Protocol surface (subset implemented)

```
⫻protocol/ocs:
⫻context/...
⫻cmd/exec: | ⫻cmd/halt: | ⫻cmd/mode: | ⫻cmd/lang:
⫻data/obj: | ⫻data/tas: | ⫻data/ptas:
⫻flow/chat:<host|KickForge|KickFlow|KickGuard>
⫻query/clarify:
⫻display/...
```

`submit` replaces the first section of the same type (state: mode, halt, obj, tas, klmx).  
`append` always pushes (conversation: `flow/chat`, `query/clarify`, `cmd/exec`, `display/content`).

Parser is line-oriented. A section starts on a sigil line (`U+2AFB`) and runs until the next sigil or EOF. Nested `⫻end/` is recognized but not expanded.

## Chat turn rules

1. Host input always records `⫻flow/chat:host` with the raw text (unless the paste contains `protocol/ocs`, which **loads** a new document).
2. Slash commands map onto existing families only (`cmd/mode`, `cmd/halt`, `cmd/exec`, `data/obj`, `data/tas`).
3. While gated, KickGuard replies with `flow/chat:KickGuard` + `query/clarify:consent`. Mutations other than halt/mode are skipped.
4. Resume is loading a `protocol/ocs` document that does not contain `cmd/halt`. No invented `cmd/resume`.
5. Natural-language turns request Google GenAI (Interactions API, `gemini-3.7-flash`). KickGuard forbids the call while gated. `/halt` and `/mode` do not call the model.
6. Qt `GenAiClient` is the only network path. Protocol core stays offline. API key from `GEMINI_API_KEY` / `GOOGLE_API_KEY` only.

## Shells

| Binary | QML entry | Default |
|---|---|---|
| `t484` | `src/qml/main.qml` | compact chat; `--console` loads the dashboard |
| `t484-console` | `src/qml/console.qml` | three-pane operator dashboard; `--chat` loads the compact shell |

Both binaries share `ProtocolEngineQt`, `TasStatusModel`, `KlmxMoleculeItem`, and the OcsNode views.

## Build

```bash
cmake -S . -B build
cmake --build build
./build/ocsnode_protocol_tests
# Qt apps (when Qt6 is available):
./build/t484
./build/t484-console
```
