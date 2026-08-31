# t484 Architecture (v0.2 refactor)

Source of truth: this repository. The `ocs-node-engine` skill is the forge, not a second product tree.

## Modules

| Module | Path | Depends on | Role |
|---|---|---|---|
| protocol | `include/ocsnode/*` + `src/protocol/` | C++20 STL only | Parse / emit ⫻ sections |
| engine | `src/engine/` | protocol + Qt6 Core | `ProtocolEngine` QObject, halt gate, coherence |
| components | `src/components/` | Qt6 Core | QObject models (`*Model` / `*Item`) |
| qml | `src/qml/OcsNode/` | engine + components | `*View` surfaces + shell |
| tests | `tests/` | protocol | Round-trip fixtures, no Qt required |

## Naming (frozen)

| Kind | Pattern | Example |
|---|---|---|
| C++ model | `*Model` or `*Item` | `TasStatusModel`, `KlmxMoleculeItem` |
| QML view | `*View.qml` | `TasStatusBarView.qml` |
| Engine | `ProtocolEngine`, `NodeEngine` | exposed to QML as `engine` |
| Section type string | `family/path` | `data/tas`, `context/klmx` |

Never register a C++ type and a QML file under the same identifier.

## Protocol surface (subset implemented in v0.2)

```
⫻protocol/ocs:
⫻context/...
⫻cmd/exec: | ⫻cmd/halt: | ⫻cmd/mode: | ⫻cmd/lang:
⫻data/obj: | ⫻data/tas: | ⫻data/ptas:
⫻flow/...
⫻display/...
```

Parser is line-oriented. A section starts on a sigil line (`U+2AFB`) and runs until the next sigil or EOF. Nested `⫻end/` is recognized but not expanded in v0.2.

## Build

```bash
cmake -S . -B build
cmake --build build
./build/ocsnode_protocol_tests
# Qt app (when Qt6 is available):
./build/t484
```
