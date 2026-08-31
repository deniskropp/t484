# Protocol engine and coherence

STL core lives in `include/ocsnode/` + `src/protocol/` + `src/engine/ProtocolEngine.cpp`.
Qt does not exist at this layer. Tests link only `ocsnode_protocol`.

## Objects

```
ChatSession  ──uses──►  ProtocolEngine  ──owns──►  vector<Section>
                              │                         │
                              │ refreshState()          │
                              ▼                         ▼
                        CoherenceState           ProtocolParser
                        (deriveCoherence)        ProtocolEmitter
                              ▲
NodeEngine ──wraps── ProtocolEngine + actor label (default KickFlow)
ProtocolEngineQt ──wraps── NodeEngine + SectionListModel + GenAiClient
```

## `ProtocolEngine`

| Method | Effect |
|---|---|
| `loadText(text)` | parse, replace `m_sections`, `refreshState()` |
| `emitText()` | serialize current document |
| `submit(section)` | replace first section of the same `type()` |
| `append(section)` | always push |
| `setMode(mode)` | submit `cmd/mode` |
| `requestHalt(reason)` | submit `cmd/halt`, fire `HaltHandler` |
| `sectionsByFamily` / `findByType` | lookup |

`refreshState()` runs `deriveCoherence(m_sections)` after every mutation.

## Halt gate

`CoherenceState.gated == true` iff a `cmd/halt` section exists.

While gated:

- ChatSession skips mutations other than halt/mode.
- `ProtocolEngineQt` must not call GenAI.
- KickGuard replies with `flow/chat:KickGuard` + `query/clarify:consent`.
- Export (read `emitText`) remains legal. Import of a halted document stays gated.

Resume = `loadText` of a `protocol/ocs` document that does not contain `cmd/halt`.

## Coherence heuristic (v0.4)

`deriveCoherence` in `CoherenceState.h`. Deterministic. Base `0.45`, clamp `[0,1]`.

| Signal | Delta |
|---|---|
| `protocol/ocs` present | +0.12 |
| `context/klmx` present | +0.12 |
| `data/obj` present | +0.10 |
| `data/tas` or `data/ptas` present | +0.16 |
| `cmd/halt` present | −0.20 |

TAS body lines that are not empty after stripping leading space/tabs/`-` increment `activeSteps`.
The first such line (truncated to 32 chars) becomes `currentTasId`.
`cmd/mode` qualifier overwrites `mode`.
Status: `gated` if halt, else `running` if TAS, else `idle`.

This is **not** CoherenceMonitorBridge. v0.6 adds named axes on top of the scalar
(`protocol`, `klmx`, `objective`, `tas`, `consent`, `dialogue`, `genai`) and
records them in `display/meta`. See [plans/v0.6/README.md](plans/v0.6/README.md).

## `NodeEngine`

Thin three-agent-core façade.

- `protocol()` → the `ProtocolEngine`
- `actor()` last label: `KickForge` / `KickFlow` / `KickGuard`
- `ingest(text)` → `loadText`

No extra store. No second state machine.

## Qt façade (boundary)

`ProtocolEngineQt` is the only object QML should see as `engine` /
`appWindow.protocol`. It:

1. Forwards load/emit/halt/submit/mode.
2. Resets `SectionListModel` from `sections()`.
3. Runs `ChatSession::send` on `sendChat`.
4. Optionally calls `GenAiClient` when `requestLlm && !gated && genaiReady`.
5. Exposes `busy`, `genaiReady`, `genaiModel`, `genaiSource` (source label only).

Do not invent chrome properties on the engine (`genaiCallCount`, `avgResponseTime`,
`logsModel`). Derive those in QML from `turnCompleted` / `busy` edges / local models.
See [CONSOLE.md](CONSOLE.md).
