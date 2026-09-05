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
| N7 | Berlin / EmbodiedPipe | freeze mapping + halt-free fixture + round-trip; no new families | N0 |

## Current cycle (v0.6.0 shipped + N7 grounding)

- [x] N0 grammar + fixture landed as plan artifacts
- [x] N1 stamp written into fixture header
- [x] N2 cmd/exec:nexus-export implemented via exportNexus()
- [x] N3 volumetric coherence axes on CoherenceState
- [x] N4 Phase E views: KickLangEditorView, TasBoardView, ConsentGateDialog
- [x] N5 CoherenceMonitorBridge adapter behind deriveCoherence
- [x] N6 Round-trip tests + console / editor / board actions
- [x] N7 Berlin Node / EmbodiedPipe mapped onto frozen families (`docs/plans/v0.6/N7-BERLIN.md`, `src/assets/nexus-v0.6-berlin.ocs`)

## Halt / consent

Halt remains first-class. ConsentGateDialog enables inspection and clean un-gating (`resumeFromHalt()`) by loading the living document without `cmd/halt`. No invented `cmd/resume`.

N7 Berlin snapshots stay halt-free. Red-band hardware or unclear consent still uses `cmd/halt`, not a new family.
