# Kirigami shell

Third OCS/Display chassis. Same engine, models, and `OcsNode 1.0` views as
`main.qml` / `console.qml`. Protocol grammar is unchanged.

Plan: [plans/v0.7-kirigami/README.md](plans/v0.7-kirigami/README.md).

## Why Kirigami 6, not “Kirigami2”

Kirigami2 is the KF5 module name. t484 is Qt 6. On KDE neon 6 (Berlin Node)
the module is:

```qml
import org.kde.kirigami as Kirigami
```

CMake does **not** `find_package(KF6Kirigami REQUIRED)`. The QML plugin is
resolved at runtime from the system (neon / KDE Frameworks 6). If the import
is missing, the process exits on `objectCreationFailed`.

## Binaries

| Command | QML |
|---|---|
| `./build/t484-kirigami` | `src/qml/kirigami.qml` (default) |
| `./build/t484 --kirigami` | same |
| `./build/t484-kirigami --chat` | compact chat |
| `./build/t484-kirigami --console` | protocol console |

Flags: `--kirigami` wins over `--console` wins over `--chat` when several are passed.
Compile defaults: `T484_SHELL_KIRIGAMI` / `T484_SHELL_CONSOLE` / chat.

## Binding rules (same as other shells)

- Alias `readonly property var protocol: engine` on the window.
- Child views take `protocol: appWindow.protocol`. Never `engine: engine`.
- Transcript model is `protocol.sections`. No parallel Kirigami list model.
- Halt overlay is `ConsentGateDialog`. Export while gated is allowed.

## Pages

| Page | Content |
|---|---|
| Chat | `ProtocolStatusBar` + `TasStatusBarView` + transcript + composer |
| TAS | `TasBoardView` |
| KickLang | `KickLangEditorView` |
| Metrics | `OcsMetricsPanelView` |
| KLMx | `KlmxMoleculeSpaceView` |

Drawer actions call `setMode`, `requestHalt`, `saveNexusToFile`, `loadNexusFromFile`.

## Theme

First pass keeps OCS Slate (`Theme.qml`) inside the reused views.
Do not retokenize onto `Kirigami.Theme` until a dedicated theme-bridge TAS.

## Berlin Node

Prefer this shell on the Fujitsu ESPRIMO / neon Wayland box. Keep workloads
light: protocol + QML only. No local heavy inference from this binary.
