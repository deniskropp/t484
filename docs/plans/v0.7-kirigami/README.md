# t484 v0.7 — Kirigami display chassis

Status: **landed as optional third shell** (plan + scaffold on `main`).
Canonical repo: `deniskropp/t484`.
Skill: `ocs-node-engine`.

Kirigami is **display only**. KickLang / OCS families stay frozen.
The living document remains `std::vector<Section>` inside `ProtocolEngine`.

## Why v0.7

| Version | What shipped |
|---|---|
| v0.4 | chat + protocol console on Qt Quick Controls 2 `ApplicationWindow` |
| v0.6 | Nexus export/import, Phase E views, CoherenceMonitorBridge |
| **v0.7** | Kirigami 6 (`org.kde.kirigami`) chassis wrapping the same views |

Berlin Node runs KDE neon 6 / Qt6 / Wayland. “Kirigami2” is the KF5-era name.
This tree pins **KF6 Kirigami** (`import org.kde.kirigami as Kirigami`).
Do not add a KF5 Kirigami2 CMake dependency.

## Objective

```
⫻data/obj:
Give t484 a KDE-native page/action/drawer shell so KickLang pages
(Chat, TAS, Editor, Metrics, KLMx) sit in Kirigami.ApplicationWindow
without a second protocol store.
```

## Non-goals

- Do not invent section families.
- Do not rewrite `main.qml` / `console.qml` in place.
- Do not put API keys in drawers or OverlaySheets.
- Do not replace OCS Slate `Theme.qml` with `Kirigami.Theme` on first pass.
- Do not require KF6 at CMake configure time. Missing Kirigami is a **runtime** QML import failure.

## Mapping (frozen families → chrome)

| KickLang family | Kirigami surface | Reused view |
|---|---|---|
| `protocol/ocs` | `Kirigami.ApplicationWindow` | document load |
| `display/header` | `globalDrawer` + page toolbar | `ProtocolStatusBar` |
| `data/tas` / `data/ptas` | page “TAS” | `TasBoardView` + `TasStatusBarView` |
| `context/klmx` | page “KLMx” | `KlmxMoleculeSpaceView` |
| `flow/chat:*` | page “Chat” | `OcsChatTranscriptView` + `OcsComposerView` |
| `cmd/halt` | `ConsentGateDialog` overlay | existing modal |
| `cmd/mode` | drawer actions | `protocol.setMode` |
| Nexus `.ocs` | drawer Export / Import | `saveNexusToFile` / `loadNexusFromFile` |

## Files

| Path | Role |
|---|---|
| `src/qml/kirigami.qml` | third shell |
| `docs/KIRIGAMI.md` | operator + binding notes |
| `docs/plans/v0.7-kirigami/TAS.md` | acceptance |
| `t484-kirigami` | binary defaulting to this shell |
| `t484 --kirigami` | same QML from the chat binary |

Resume is still load-without-`cmd/halt` (or `resumeFromHalt()`). No `cmd/resume` family.
