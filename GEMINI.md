# t484 — OCS/Node Engine

This project is the C++20 canonical protocol core and optional Qt6/QML **interactive chat** plus **protocol console** for the Orion Collective System (OCS v2.1). It provides the `ocs-node-engine` functionality. The chat transcript is the living protocol document (`flow/chat` turns + three-agent replies). Natural-language Send calls the Google GenAI **Interactions API** (`POST /v1beta/interactions`, model `gemini-3.7-flash`) using `GEMINI_API_KEY`.

## Project Structure

- `include/ocsnode/`: Public headers, including core `Section`, `ProtocolParser`, `ProtocolEmitter`, and `ProtocolEngine`. The `qt/` subdirectory contains QObject wrappers (models/items).
- `src/protocol/`: Core implementation of protocol parsing, emission, and `ChatSession` (STL-only).
- `src/engine/`: `ProtocolEngine` (Qt facade) and `SectionListModel`.
- `src/components/`: QObject implementations (`TasStatusModel`, `KlmxMoleculeItem`).
- `src/qml/`: QML views and the OcsNode module. `main.qml` is the chat shell; `console.qml` is the three-pane protocol console.
- `tests/`: Protocol round-trip tests and fixtures.
- `docs/`: Architectural documentation (`CONSOLE.md` for the dashboard shell).

## Building and Running

The project requires CMake and a C++20 compliant compiler.

### Protocol Core (No Qt Required)
```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
./build/ocsnode_protocol_tests src/assets/seed.ocs
```

### Full Qt 6 Display Engine
Requires Qt6 (`Core`, `Gui`, `Qml`, `Quick`, `QuickControls2`).

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build build
./build/t484
./build/t484-console
```

## Development Conventions

- **Naming:**
  - C++ models: `*Model` or `*Item` (e.g., `TasStatusModel`).
  - QML views: `*View.qml` (e.g., `TasStatusBarView.qml`).
- **Identifier Separation:** A C++ type and a QML file must **never** share an identifier.
- **Protocol:** The parser is line-oriented, based on `⫻` sigils (U+2AFB). A section runs until the next sigil or EOF.
- **Source of Truth:** This repository is the source of truth; any generated code is strictly staging.
- **Shells:** Do not invent ProtocolEngineQt properties for console chrome. Derive call counts / latency / logs in QML from existing signals.
