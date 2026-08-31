# OCS/Node Nexus — one-file KickLang export (v0.6.0)

The export **is** a protocol document. `ProtocolParser` must accept it unchanged.
No wrapper format, no JSON sidecar, no second store.

## What the file is

| It is | It is not |
|---|---|
| Living protocol snapshot of `deniskropp/t484` | A chat snippet |
| State of the engine, in the language the engine parses | An incidental log |
| Source of truth for objective, TAS, architecture, agent turns | A substitute for git history |
| Re-ingestible via `ProtocolEngine::loadText` | A secret store |

Header used by the shared session:

```
⫻protocol/ocs: [node=OCS/Root] [repo=deniskropp/t484] [ref=main] [version=0.6.0]
⫻cmd/exec:ocs-node-engine
⫻cmd/mode:Hybrid
⫻cmd/lang:DE
⫻context/klmx:Kick/Lang
```

Qualifier on `protocol/ocs` is a bracket attribute list. Parser already treats the whole rest-of-line as `qualifier`. v0.6 does not change the parser; tools may split `[key=value]` later.

## Required sections (order recommended, not mandated)

1. `protocol/ocs` — identity + version stamp.
2. `cmd/exec` — `ocs-node-engine` (and optionally `nexus-export`).
3. `cmd/mode` — Fluid \| Swarm \| Predictive \| Hybrid.
4. `cmd/lang` — optional (`EN`, `DE`, `KickLang`, …).
5. `context/klmx` — molecule / formula / model / space / scope / reference.
6. `data/obj` — living objective.
7. `data/tas` and/or `data/ptas` — steps.
8. `display/header`, `display/meta` — human orientation + axis table.
9. `flow/chat:*` — host + KickForge / KickFlow / KickGuard turns that belong in the snapshot.
10. `cmd/halt` — only if the session is gated.

Optional: `query/clarify`, other `display/*`, `cmd/exec:genai` audit lines.

## Forbidden in the file

- API keys, `.env` paths that contain secrets, raw `x-goog-api-key` values.
- Invented families (`cmd/resume`, `data/nexus-blob`, …).
- Binary attachments. Point at git paths instead.

`genaiSource` may appear as a label (`env:GEMINI_API_KEY`) never as the key.

## Layer table (export meaning)

| Layer | Meaning in the file |
|---|---|
| `protocol/ocs` | Which node, repo, ref, version this snapshot claims |
| `context/klmx` | KickLang molecule the engine is bound to |
| `cmd/*` | Control plane (mode, halt, exec, lang) |
| `data/obj` + `data/tas` | Living objective and steps |
| `flow/chat` | Conversation that *is* the document |
| `display/meta` | Operator-facing axis / architecture notes |

## Round-trip contract

```
parse(emitText(parse(nexus-v0.6.ocs)))
```

must preserve section count, `family/path`, qualifier, and body for every section.
Already guaranteed by `tests/test_protocol.cpp` if the fixture is a valid `.ocs`.

Import path is existing behavior: a paste or file that contains `protocol/ocs` **loads** (replaces) the document.

## Operator actions (planned UI, v0.6)

| Action | Binding |
|---|---|
| Export Nexus | `engine.emitText()` → file `nexus-YYYYMMDD.ocs` |
| Import Nexus | `engine.loadText(file)` |
| Copy snapshot | clipboard → same text |
| Console button | `t484-console` toolbar; no new engine property |

Derive chrome from existing signals. Do not invent `ProtocolEngineQt` properties for the button.

## Compatibility

| Consumer | Requirement |
|---|---|
| t484 v0.4 chat/console | Must load the fixture as a document (version attr is opaque qualifier text) |
| `ocsnode_protocol_tests` | Fixture added to the seed-style test list |
| ocs-node-engine skill | Treat this folder as plan; repo remains source of truth |
