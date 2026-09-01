# Protocol engine and coherence

STL core lives in `include/ocsnode/` + `src/protocol/` + `src/engine/ProtocolEngine.cpp`.
Qt does not exist at this layer. Tests link only `ocsnode_protocol`.

## Objects

```
ChatSession  --uses-->  ProtocolEngine  --owns-->  vector<Section>
                              |                         |
                              | refreshState()          |
                              v                         v
                        CoherenceState           ProtocolParser
                        (deriveCoherence)        ProtocolEmitter

NodeEngine wraps ProtocolEngine + actor label (default KickFlow)
ProtocolEngineQt wraps NodeEngine + SectionListModel + GenAiClient
```

## `ProtocolEngine`

| Method | Effect |
|---|---|
| `loadText(text)` | parse, replace `m_sections`, `refreshState()` |
| `emitText()` | serialize current document |
| `exportNexus(genaiAxis=0.5)` | stamp `protocol/ocs [version=0.6.0]`, write axes into `display/meta`, scrub secrets, return text |
| `importNexus(text)` | `loadText` of a `protocol/ocs` document. No second store |
| `submit(section)` | replace first section of the same `type()` |
| `append(section)` | always push |
| `setMode(mode)` | submit `cmd/mode` |
| `requestHalt(reason)` | submit `cmd/halt`, fire `HaltHandler` |
| `resumeFromHalt()` | remove all `cmd/halt` sections, `refreshState()` (un-gate) |
| `sectionsByFamily` / `findByType` | lookup |

`refreshState()` runs `deriveCoherence(m_sections)` after every mutation.

`exportNexus` is allowed while gated (read + export metadata). `genaiAxis` is a Qt-only overlay (`ready && !busy` -> 1.0, else 0.5). Secrets never enter the file.

Operator bindings already on main:

- `/exec nexus-export` -> `exportNexus()` (ChatSession, no LLM)
- console Export / Import / Copy actions
- round-trip tests for seed + nexus fixtures

## Halt gate

`CoherenceState.gated == true` iff a `cmd/halt` section exists.

While gated:

- ChatSession skips mutations other than halt/mode.
- `ProtocolEngineQt` must not call GenAI.
- KickGuard replies with `flow/chat:KickGuard` + `query/clarify:consent`.
- `exportNexus` remains legal. Import of a halted document stays gated.

Resume = `loadText` / `importNexus` of a `protocol/ocs` document that does not contain `cmd/halt`.

## Coherence heuristic

`deriveCoherence` in `CoherenceState.h`. Deterministic. Base `0.45`, clamp `[0,1]`.

| Signal | Scalar delta |
|---|---|
| `protocol/ocs` present | +0.12 |
| `context/klmx` present | +0.12 |
| `data/obj` present | +0.10 |
| `data/tas` or `data/ptas` present | +0.16 |
| `cmd/halt` present | -0.20 |

TAS body lines that are not empty after stripping leading space/tabs/`-` increment `activeSteps`.
The first such line (truncated to 32 chars) becomes `currentTasId`.
`cmd/mode` qualifier overwrites `mode`.
Status: `gated` if halt, else `running` if TAS, else `idle`.

### Volumetric axes (additive)

`CoherenceState.axes` (`VolumetricAxes`). Status bar still shows the scalar.

| Axis | Source | Score |
|---|---|---|
| `protocol` | `protocol/ocs` | 1 or 0 |
| `klmx` | `context/klmx` | 1 or 0 |
| `objective` | `data/obj` | 1 or 0 |
| `tas` | TAS/PTAS step count | `min(1, steps/5)` |
| `consent` | absence of `cmd/halt` | 1 or 0 |
| `dialogue` | `flow/chat` host/replies | `min(1, host*0.25 + replies*0.15)` |
| `genai` | STL default 0.5; Qt overlays ready && !busy | never a secret |

Export records axes in `display/meta`. `CoherenceMonitorBridge` routes `deriveCoherence` through `ICoherenceMonitorBridge` (defaulting to `DefaultCoherenceMonitorBridge`).

## `NodeEngine`

Thin three-agent-core facade.

- `protocol()` -> the `ProtocolEngine`
- `actor()` last label: `KickForge` / `KickFlow` / `KickGuard`
- `ingest(text)` -> `loadText`

No extra store. No second state machine.

## Qt facade (boundary)

`ProtocolEngineQt` is the only object QML should see as `engine` /
`appWindow.protocol`. It:

1. Forwards load/emit/halt/submit/mode/exportNexus/importNexus.
2. Resets `SectionListModel` from `sections()`.
3. Runs `ChatSession::send` on `sendChat`.
4. Optionally calls `GenAiClient` when `requestLlm && !gated && genaiReady`.
5. Exposes `busy`, `genaiReady`, `genaiModel`, `genaiSource` (source label only).

Do not invent chrome properties on the engine (`genaiCallCount`, `avgResponseTime`,
`logsModel`). Derive those in QML from `turnCompleted` / `busy` edges / `EventLogModel`.
See [CONSOLE.md](CONSOLE.md).
