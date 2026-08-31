# t484 documentation index

Canonical product docs for the **OCS/Node Engine** (`deniskropp/t484`).
Shipped product is **v0.4** (chat + protocol console + OCS Slate).
Nexus **export/import + volumetric axes** are implemented on main; Phase E UI and CoherenceMonitorBridge are still planned.
The `ocs-node-engine` skill is the forge. This repository is the source of truth.

## Start here

| If you want… | Read |
|---|---|
| What the product is and how to build it | [../README.md](../README.md) |
| Module cut + naming freeze | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Every C++ / QML interface | [COMPONENTS.md](COMPONENTS.md) |
| `⫻` grammar as implemented | [PROTOCOL.md](PROTOCOL.md) |
| Document engine, halt gate, coherence, Nexus export | [ENGINE.md](ENGINE.md) |
| Chat turn machine | [CHAT.md](CHAT.md) |
| Run chat / console / GenAI | [OPERATOR.md](OPERATOR.md) |
| CMake targets and tests | [BUILD.md](BUILD.md) |
| How t484 sits in OCS v2.1 | [OCS-INTEGRATION.md](OCS-INTEGRATION.md) |
| Words used in this tree | [GLOSSARY.md](GLOSSARY.md) |
| Console shell layout | [CONSOLE.md](CONSOLE.md) |
| QML plates | [PANELS.md](PANELS.md) |
| Color / type tokens | [THEME.md](THEME.md) |
| Nexus plan (remaining Phase E / bridge) | [plans/v0.6/README.md](plans/v0.6/README.md) |

## Invariants (do not drift)

1. The chat transcript **is** the living protocol document. No parallel message store.
2. C++ type and QML file never share an identifier (`*Model`/`*Item` vs `*View.qml`).
3. Halt is first-class. There is no `cmd/resume`. Resume = load a document without `cmd/halt`.
4. Protocol core is C++20 STL and offline. The only network path is `GenAiClient`.
5. API keys never enter a `Section` (export scrubs secrets).
6. Do not invent section families beyond the frozen surface in `ARCHITECTURE.md`.
7. Skill `generated/` is staging. Product types live under `include/` + `src/`.

## Status snapshot

| Piece | State |
|---|---|
| Parser, emitter, `ProtocolEngine`, `ChatSession` | shipped |
| `t484` chat + `t484-console` | shipped |
| OCS Slate theme + panel plates | shipped |
| `exportNexus` / `importNexus` + console actions + axes | shipped |
| KickLangEditor / TasBoard / ConsentGateDialog | planned (Phase E / v0.5) |
| CoherenceMonitorBridge behind `deriveCoherence` | planned |

Generated 2026-09-01 from t484@main (including Nexus export commit `2c4be7b`).
The engine remains the authority if a sentence here and a header disagree — fix the sentence.
