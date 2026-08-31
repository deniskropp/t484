# TAS / PTAS — t484 v0.6 Nexus

Purified from the living objective: *push relevant v0.6 plans to GitHub and define the Nexus export*.

## PTAS

| ID | Step | Acceptance | Depends |
|---|---|---|---|
| N0 | Freeze export grammar | `NEXUS-EXPORT.md` merged; fixture parses with current parser | — |
| N1 | Version stamp | seed-compatible header `[version=0.6.0] [repo=deniskropp/t484] [ref=main]` documented | N0 |
| N2 | Export command mapping | `cmd/exec:nexus-export` documented as `emitText()`; no new family | N0 |
| N3 | Volumetric axes | axes table in plan; `CoherenceState` fields listed as additive | N0 |
| N4 | Phase E views | KickLangEditorView, TasBoardView, ConsentGateDialog named; identifiers not colliding | — |
| N5 | Bridge hook | `deriveCoherence` remains; replacement noted as CoherenceMonitorBridge | N3 |
| N6 | Tests + console action | listed; implementation is post-plan | N0 N2 |
| N7 | Berlin / EmbodiedPipe | optional, not critical path | — |

## Current cycle (this commit)

- [x] N0 grammar + fixture landed as plan artifacts
- [x] N1 stamp written into fixture header
- [x] N2 / N3 / N4 / N5 specified, not implemented in C++
- [ ] N6 implementation
- [ ] N7 optional grounding

## Halt / consent

Implementation work that mutates `src/` still requires an explicit operator go (KickGuard). This commit only writes `docs/plans/v0.6/*` and `src/assets/nexus-v0.6.ocs`.
