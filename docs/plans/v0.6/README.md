# t484 v0.6 — OCS/Node Nexus (plan)

Status: **plan only**. Shipped product remains **v0.4** (chat + protocol console + OCS Slate).
This folder is the living plan for the next major surface: **OCS/Node Nexus**.

Source conversation: [OCS/Node Nexus Export](https://grok.com/share/c2hhcmQtMi1jb3B5_b5705408-6076-4c2c-b701-4a8ffd17ce60)
Canonical repo: `deniskropp/t484` @ `main`.
Skill: `ocs-node-engine`.

The one-file KickLang export is not a chat snippet and not an incidental log.
It is the **living protocol snapshot** of the engine, written in the language the engine itself parses.

## Why v0.6

| Version | What shipped |
|---|---|
| v0.2 | STL protocol core, QML views, engine bindings |
| v0.3 | Interactive OCS chat, `flow/chat`, Google GenAI Interactions API |
| v0.4 | `t484-console` three-pane dashboard, EventLog, OCS Slate theme |
| **v0.5** (bridge, not this folder) | Phase E UI: KickLangEditor, TasBoard, ConsentGateDialog |
| **v0.6** (this plan) | Volumetric Coherence Nexus + lossless one-file export/import |

v0.4 already has a living document (`std::vector<Section>` + `emitText()`).
v0.6 makes that document a **versioned Nexus artifact**: architecture + session + agent turns + coherence axes in one `.ocs` file that `ProtocolEngine::loadText` can ingest without a second store.

## Objective

Evolve the C++20 / Qt6-QML engine (`ProtocolEngine` + QML chat/console) into a **volumetric Coherence Nexus** while keeping the current session (objective, TAS, architecture, three-agent turns) as the source of truth.

```
⫻data/obj:
Make t484 a Nexus whose entire operator state is one KickLang/OCS file — exportable, re-ingestible, consent-gated.
```

## Non-goals

- Do not invent new section families beyond the frozen surface in `docs/ARCHITECTURE.md`.
- Do not put API keys into the export.
- Do not replace `flow/chat` with a parallel message store.
- Do not claim v0.6 shipped until export/import round-trips in `ocsnode_protocol_tests`.
- Do not reuse C++ identifiers for QML files (`KickLangEditor` vs `KickLangEditorView.qml`).

## Deliverables

1. **Export format** — `docs/plans/v0.6/NEXUS-EXPORT.md` + fixture `src/assets/nexus-v0.6.ocs`.
2. **Commands** — map onto existing `cmd/exec` only:
   - `cmd/exec:nexus-export` writes the current document (+ header version).
   - `cmd/exec:nexus-import` is `loadText` of a `protocol/ocs` document (already implemented).
3. **Volumetric coherence** — replace the scalar `deriveCoherence` heuristic with named axes (see below). Hook point remains `CoherenceState`; later `CoherenceMonitorBridge`.
4. **Phase E surfaces** (may land in v0.5, required for v0.6 operator use):
   - `KickLangEditorView.qml` — edit/export the living document.
   - `TasBoardView.qml` — TAS/PTAS board bound to `TasStatusModel`.
   - `ConsentGateDialog.qml` — modal over halt; resume still = load without `cmd/halt`.
5. **Version stamp** — `protocol/ocs` qualifier includes `[version=0.6.0]`.
6. **Tests** — parse/emit round-trip of `nexus-v0.6.ocs`; export does not leak secrets; halt still gates mutation.

## Volumetric coherence axes

Scalar `coherence ∈ [0,1]` stays for the status bar. v0.6 *adds* named axes derived only from existing sections:

| Axis | Source sections | Meaning |
|---|---|---|
| `protocol` | `protocol/ocs` | document identity present |
| `klmx` | `context/klmx` | molecule / space bound |
| `objective` | `data/obj` | living objective present |
| `tas` | `data/tas`, `data/ptas` | active steps > 0 |
| `consent` | absence of `cmd/halt` | not gated |
| `dialogue` | `flow/chat` count | host + triad turns |
| `genai` | Qt-only: `genaiReady && !busy` | transport healthy (never in STL export body as a secret) |

Export records axis scores in `display/meta` (human) and keeps `deriveCoherence` compatible so v0.4 shells still render.

## TAS (v0.6)

```
⫻data/tas:
N0 Freeze export grammar (NEXUS-EXPORT.md) and check fixture nexus-v0.6.ocs parses today
N1 Stamp protocol/ocs with [version=0.6.0] [repo=deniskropp/t484] [ref=main]
N2 cmd/exec:nexus-export → emitText() + header; no key material
N3 Volumetric axes on CoherenceState (additive fields; scalar kept)
N4 KickLangEditorView + TasBoardView + ConsentGateDialog (Phase E)
N5 CoherenceMonitorBridge adapter behind deriveCoherence
N6 Round-trip tests + console “Export Nexus” action bound to emitText
N7 Berlin Node / EmbodiedPipe optional grounding — out of critical path
```

## Consent

Halt remains first-class. Export is allowed while gated (read). Import that contains `cmd/halt` stays gated. Resume = load a document without `cmd/halt`. No invented `cmd/resume`.

## Files in this folder

| Path | Role |
|---|---|
| [README.md](README.md) | this roadmap |
| [NEXUS-EXPORT.md](NEXUS-EXPORT.md) | one-file KickLang / `.ocs` grammar |
| [TAS.md](TAS.md) | purified steps + acceptance |

Fixture living next to seed: `src/assets/nexus-v0.6.ocs`.
