# OCS v2.1 integration

How the Node engine participates in the Orion Collective System without
becoming a second protocol.

## Source of truth

| Artifact | Role |
|---|---|
| `deniskropp/t484` | product — parser, engine, shells |
| skill `ocs-node-engine` | forge — scaffolding, catalogs, `generated/` staging |
| skill `ocs-protocol-export` | broader command/payload/state schema |
| skill `ocs-protocol-enforcer` | runtime validation against that schema |
| skill `berlin-node-ocs-participant` | physical machine as consenting participant |
| skill `orchestrator` | three-agent-core coordination across repos |

If skill staging and t484 disagree, **t484 wins**. Move generated types into
`src/` + `include/` and register them in CMake / `qmldir` before calling them shipped.

## Placement

```
Denis / OCS/Display  --sections-->  t484 ProtocolEngine
                                          |
                    +---------------------+---------------------+
                    v                     v                     v
             protocol-export        protocol-enforcer     Flow Nexus / KickLang
             (schemas, MCP)         (state machine)       (spaces, TAS graphs)
                    |
                    v
             Berlin Node (optional local TAS, EmbodiedPipe ground)
```

t484 implements the **document + gate + display** slice of OCS, plus one-file
Nexus export/import. It does not implement RTA descent, swarm joins, or
KickLang module compilation.

## Command overlap

Implemented in the Node today:

- `cmd/exec` (including `ocs-node-engine`, `genai`, `nexus-export`)
- `cmd/halt`
- `cmd/mode`
- `cmd/lang` (stateful type; composer has no `/lang` yet)
- `query/clarify`
- `data/obj` `data/tas` `data/ptas`
- `flow/chat`
- `display/*`
- `context/klmx`
- `protocol/ocs`

Listed in `ocs_core_schema.json` but **not** Node families yet:

- `cmd/broadcast`
- `flow/new` `flow/continue` `flow/halt` (as distinct types)
- `rta/synthesize` `rta/traverse`
- extra payload types (`data/spec`, `data/conflict`, `data/rta`, ...)
- full lifecycle states (`TAS_EXTRACTING`, `RTA_TRAVERSING`, ...)

Do not emit those from t484 until ARCHITECTURE.md is updated and a protocol test exists.

## Three-agent-core mapping

| Agent | In OCS generally | In t484 specifically |
|---|---|---|
| KickForge | TAS extract / purify | `flow/chat:KickForge` on structured input |
| KickFlow | structure / delegate / transfer | default `NodeEngine` actor; GenAI reply |
| KickGuard | ethics / halt / coherence | halt gate, consent clarify, drop in-flight LLM |

Orchestrator and Dima live outside this process. The Node records their
turns if they arrive as sections. It does not spawn them.

## Berlin Node

Hardware anchor: Fujitsu ESPRIMO P420, KDE neon Wayland, 12 GiB, i3-4130, HD 4400.

t484 can *run on* that machine. The Berlin skill registers the machine as an
OCS participant with its own consent matrix (green / yellow / red halt on load).

N7 grounding (optional path, now specified): map identity and EmbodiedPipe onto
**frozen families only**. See `docs/plans/v0.6/N7-BERLIN.md` and fixture
`src/assets/nexus-v0.6-berlin.ocs`.

| Concern | Family |
|---|---|
| identity | `protocol/ocs` `[node=Berlin]` |
| activation | `cmd/exec:ocs-node-engine` |
| pipe + fingerprint | `context/klmx` + `display/meta` |
| consent question | `query/clarify:consent` |
| overload | `cmd/halt` (resume = halt-free load) |

Do not add `flow/berlin`, `data/hardware`, or `cmd/resume`.

Operator rule on modest hardware: build protocol-core tests first; treat the
Qt shells as the display, not as a local LLM host.

## MCP / CLI

`ocs-protocol-export` describes `ocs-ctl` and MCP tools (`ocs_cmd_exec`, ...).
t484 does not ship that CLI. Bridge work belongs in `mcp-bridge-nexus` /
`ocs-mcp-core`, calling `loadText` / `emitText` / `exportNexus` / halt — not a second parser.

## Activation line

```
cmd/exec:ocs-node-engine
```

That qualifier is how OCS documents name this product. Keep it in seed and
Nexus fixtures.
