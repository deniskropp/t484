# Build and test

Project version in CMake: **0.4.0**. C++20 required. CMake ≥ 3.16.

## Targets

| Target | Qt? | What |
|---|---|---|
| `ocsnode_protocol` (STATIC) | no | parser, emitter, ChatSession, ProtocolEngine |
| `ocsnode_protocol_tests` | no | `tests/test_protocol.cpp` |
| `ocsnode_engine` (STATIC) | yes | ProtocolEngineQt, GenAiClient, models |
| `ocsnode_qml` (STATIC module `OcsNode 1.0`) | yes | QML + `seed.ocs` resource |
| `t484` | yes | chat shell (`src/main.cpp`) |
| `t484-console` (`t484_console` target) | yes | `T484_SHELL_CONSOLE` |
| `ocsnode_genai_tests` | Core+Network | `tests/test_genai.cpp` — no GUI, no network |

Qt components: `Core Gui Qml Quick QuickControls2 Network`.
If `find_package(Qt6 QUIET …)` fails, CMake prints
`Qt6 not found — building protocol core + tests only`.

`qt_add_qml_module` is shared once (`URI OcsNode`) so chat and console do not
fight over the same output directory. Apps set `QT_QML_MODULE_NO_IMPORT_SCAN TRUE`
so missing Debian plugin CMake targets do not warn.

`T484_SOURCE_DIR` is compiled into the engine as the repo root (`.env` walk).

## Commands

Protocol core only:

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
./build/ocsnode_protocol_tests src/assets/seed.ocs
```

With Qt 6:

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build build
./build/t484
./build/t484-console
```

On Debian/KDE neon the prefix is often the distro Qt. Berlin Node
(Fujitsu ESPRIMO P420, KDE neon Wayland) should prefer distro Qt6 and
the protocol-core-only path when RAM is tight. Heavy local inference is
out of scope for this binary.

## Tests

| Name | Covers |
|---|---|
| `protocol_core` | parse/emit round-trip, halt/mode, append chat, ChatSession slash/gate/`requestLlm`, seed fixture |
| `genai_parse` | `extractOutputText`, `parseDotEnv` |

No test calls the network. Do not add a test that requires `GEMINI_API_KEY`.

v0.6 acceptance (not yet wired): round-trip `src/assets/nexus-v0.6.ocs`
and prove export does not leak secrets. Spec: [plans/v0.6/TAS.md](plans/v0.6/TAS.md).

## Layout the build expects

```
include/ocsnode/          public STL headers
include/ocsnode/qt/       QObject headers
src/protocol/             STL sources
src/engine/               ProtocolEngine + Qt façade
src/components/           TasStatusModel, KlmxMoleculeItem, EventLogModel
src/qml/main.qml
src/qml/console.qml
src/qml/OcsNode/          Theme + *View.qml + qmldir
src/assets/*.ocs
tests/
```

QML files are flattened to the module root via `QT_RESOURCE_ALIAS`.
`Theme.qml` is a singleton (`QT_QML_SINGLETON_TYPE TRUE`).
