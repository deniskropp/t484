# t484 — OCS/Node Engine

**OCS/Node Engine for OCS/Display**  
C++20 protocol core + optional Qt 6 / QML display.

Part of the Orion Collective System (OCS v2.1).  
Canonical product repo for the `ocs-node-engine` skill.

## Status (v0.2 — refactor/layout-v0.2)

| Piece | State |
|---|---|
| `src/protocol/` parser + emitter | shipped |
| `ProtocolEngine` / `NodeEngine` | shipped |
| protocol tests (no Qt) | shipped |
| `ProtocolEngineQt` + `SectionListModel` | shipped (needs Qt6) |
| `TasStatusModel` + `TasStatusBarView` | shipped |
| `KlmxMoleculeItem` + `KlmxMoleculeSpaceView` | shipped |
| `OcsSectionView` bound to engine model | shipped |
| KickLangEditor / TasBoard / ConsentGateDialog | planned (Phase E) |

## Layout

```
include/ocsnode/          Section, parser, emitter, engine, coherence
include/ocsnode/qt/       QObject wrappers (Model / Item)
src/protocol/             STL parser + emitter
src/engine/               ProtocolEngine + Qt façade
src/components/           TasStatusModel, KlmxMoleculeItem
src/qml/OcsNode/          *View.qml + qmldir
src/assets/seed.ocs       startup protocol document
tests/                    protocol round-trip
docs/ARCHITECTURE.md      module + naming freeze
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
./build/t484
```

## OCS Integration

```
⫻cmd/exec:ocs-node-engine
```

This repository is the source of truth. Skill `generated/` is staging only.

## License

To be determined. Active co-agency development by Denis Oliver Kropp / Exit.
