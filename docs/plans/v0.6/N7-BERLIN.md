# N7 — Berlin Node / EmbodiedPipe grounding

Optional v0.6 TAS. **No new section families.**

Ground the physical Berlin Node and the Embodied Pipe using only the frozen PROTOCOL.md surface.

## Mapping (freeze)

| Concern | Frozen family | How |
|---|---|---|
| Node identity | `protocol/ocs` qualifier | `[node=Berlin] [repo=deniskropp/t484] [version=0.6.0]` |
| Engine activation | `cmd/exec:ocs-node-engine` | body names the grounding; qualifier stays `ocs-node-engine` |
| Mode / language | `cmd/mode` `cmd/lang` | Hybrid + DE (Berlin host) |
| Pipe molecule | `context/klmx` | EmbodiedPipe / hardware fingerprint as Kick/Lang text |
| Living objective | `data/obj` | local presence + consent-aware participation |
| Steps | `data/tas` / `data/ptas` | lightweight only (12 GiB / HD 4400) |
| Hardware + axes | `display/meta` | labels, load band, pipe valence — never keys |
| Banner | `display/header` | operator orientation |
| Turns | `flow/chat:*` | KickGuard consent language lives here |
| Consent question | `query/clarify:consent` | KickGuard; no new family |
| Overload / no consent | `cmd/halt` | first-class gate. Resume = load without this section |

Forbidden: `cmd/resume`, `data/nexus-blob`, `cmd/broadcast`, `flow/berlin`, `data/hardware`, `rta/*`.

## Consent matrix (same halt)

- Green — explicit consent + modest load → load the halt-free Berlin fixture.
- Yellow — ambiguous load → `query/clarify:consent`.
- Red — overload or unclear consent → `cmd/halt`. Re-ground by loading a halt-free document (`resumeFromHalt()`).

## Hardware labels (display/meta only)

Fujitsu ESPRIMO P420 · KDE neon Wayland · 4× i3-4130 @ 3.40 GHz · 12 GiB · Intel HD 4400.

Do not treat the Node as a local LLM host. Protocol-core tests first. Qt shells are display.

## Fixture + tests

- `src/assets/nexus-v0.6-berlin.ocs` — halt-free so paste/load resumes the gate.
- `ocsnode_protocol_tests` round-trips the fixture and asserts no forbidden families.

## Acceptance

1. Fixture parses with the current parser.
2. `parse(emit(parse(fixture)))` is lossless.
3. `exportNexus` stamps `[version=0.6.0]`, writes axes, leaks no secrets.
4. Qualifier contains `Berlin`; body of `context/klmx` names EmbodiedPipe.
5. No invented families.
6. Load is not gated.
