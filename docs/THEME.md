# t484 visual system — OCS Slate

Source of truth for color and type on every QML surface. Implemented as the
`Theme` singleton (`src/qml/OcsNode/Theme.qml`, `OcsNode 1.0`).

Dark is the product theme. Light is the accessibility twin. Settings → General
writes `Theme.name`. No view should introduce a new hex.

Panel plates for every shipped surface: [`PANELS.md`](PANELS.md).

## Palette (Dark / product)

| Token | Hex | Use |
|---|---|---|
| `bg` | `#0f172a` | window, transcript |
| `bgRaised` | `#111827` | cards, composer field |
| `bgSunken` | `#0b1220` | raw-source well |
| `bgPanel` | `#1e293b` | settings, metrics |
| `bgChrome` | `#020617` | protocol status bar |
| `border` | `#334155` | 1px rules |
| `text` | `#e2e8f0` | Inter / Fira Code body |
| `textMuted` | `#94a3b8` | labels |
| `cyan` | `#22d3ee` | Hybrid chrome, KickFlow |
| `violet` | `#a78bfa` | KickGuard, GenAI |
| `teal` / `hostFill` | `#14b8a6` / `#134e4a` | host cards |
| `amber` | `#f59e0b` | KickForge, query |
| `emerald` | `#34d399` | coherence high, display |
| `danger` | `#f43f5e` | halt / gated |

## Role borders

| Speaker | Fill | Border |
|---|---|---|
| host / user | `#134e4a` | `#2dd4bf` |
| KickForge | `#1c1408` | `#f59e0b` |
| KickFlow | `#042f2e` | `#22d3ee` |
| KickGuard | `#1e1033` | `#a78bfa` |

Resolved by `Theme.roleAccent(qualifier, family, isHost)` and `Theme.roleFill(...)`.

## Type

- UI labels: Inter (`Theme.fontUi`)
- Protocol, code, transcript: Fira Code (`Theme.fontMono`)
- Radius 8 / 4 / pill 12

## Wiring

`qmldir` registers `singleton Theme 1.0 Theme.qml`.
CMake marks `QT_QML_SINGLETON_TYPE TRUE` and aliases the file to the module root.
`main.qml` / `console.qml` bind `ApplicationWindow.color` and `palette.*` to Theme.
`OcsSettingsPanelView` writes `Theme.name` when the user picks Dark or Light.

## Gallery

![ProtocolStatusBar](images/protocol-status-bar.svg)

![TasStatusBarView](images/tas-status-bar.svg)

![Role-coded bubbles](images/chat-bubbles.svg)

![Composer](images/composer.svg)
