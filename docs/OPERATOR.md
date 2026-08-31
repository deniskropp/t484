# Operator runbook

How to run t484 as an OCS/Node operator. Architecture stays in
[ARCHITECTURE.md](ARCHITECTURE.md). Interfaces stay in [COMPONENTS.md](COMPONENTS.md).

## Binaries

| Binary | QML | Default job |
|---|---|---|
| `t484` | `src/qml/main.qml` | compact chat |
| `t484-console` | `src/qml/console.qml` | three-pane dashboard |
| `ocsnode_protocol_tests` | - | STL protocol tests |
| `ocsnode_genai_tests` | - | GenAI parse tests (no network) |

```bash
./build/t484              # chat
./build/t484 --console    # same console from the chat binary
./build/t484-console
./build/t484-console --chat
./build/t484 --genai-status   # ready / source / model — never the key
./build/t484 --genai-debug    # env names and .env paths checked
```

A KDE/Grok GUI launch does **not** inherit an interactive-shell `export`.
Put the key where the process can see it (see below).

## Build (short)

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

Qt 6 (`Core Gui Qml Quick QuickControls2 Network`) is optional.
Without it, only `ocsnode_protocol` + `ocsnode_protocol_tests` build.
Full steps: [BUILD.md](BUILD.md).

## GenAI key lookup (order)

Process environment, first hit wins:

1. `GEMINI_API_KEY`
2. `GOOGLE_API_KEY`
3. `GOOGLE_GENAI_API_KEY`
4. `GOOGLE_AI_API_KEY`

Then `.env` files, first readable hit wins:

- `T484_SOURCE_DIR/.env` (compile definition = repo root)
- working directory `.env`
- next to the binary
- `../.env`
- `~/.config/t484/.env`
- `~/.config/Exit/t484/.env`
- `$XDG_RUNTIME_DIR/t484.env`

Supported line forms: `KEY=value`, `export KEY=value`, `KEY: value`.
Quotes and BOM stripped. The value is never logged; `--genai-debug` prints lengths and HIT/MISS.

Optional: `GEMINI_MODEL` / `GOOGLE_GENAI_MODEL` (default `gemini-3.7-flash`).

Get a key: https://aistudio.google.com/apikey

## Composer language

- Natural language -> `flow/chat:host` then GenAI (if ready and not gated).
- Raw protocol sections -> parse. A `protocol/ocs` block **loads** a new document.
- Slash: `/mode` `/halt` `/exec` `/obj` `/tas`.
- `/exec nexus-export` -> `exportNexus()` (local, no LLM).
- `/halt` and `/mode` stay local. No LLM.

## Consent

| Situation | Node behavior |
|---|---|
| `/halt reason` | submit `cmd/halt`, gated chrome, KickGuard consent query |
| Gated + NL / `/exec` / `/obj` / `/tas` | mutation skipped, no GenAI |
| Gated + `/mode` or `/halt` | allowed |
| Resume | paste or load a `protocol/ocs` document **without** `cmd/halt` |
| Export while gated | `exportNexus()` / `emitText()` is a read — allowed |

Do not type API keys into the composer. They will become protocol text and leak into `emitText`.

## Console vs chat

Same engine, same models, same views.

Chat: status bar -> TAS strip -> transcript + composer | KLMX + raw `sourceText`.

Console: status + view-mode strip -> transcript + composer + TAS/KLMX | settings + event log | metrics.

View-mode combo (`chat|inspect|dev`) is **shell chrome**. Protocol mode stays
`Hybrid|Fluid|Swarm|Predictive`.

Settings -> General writes `Theme.name` (`Dark` / `Light`).
GenAI fields are read-only source/model labels.
Console Export / Import / Copy bind to `exportNexus` / `importNexus` / clipboard.

## Seed and fixtures

| File | Role |
|---|---|
| `src/assets/seed.ocs` | startup document (qrc + disk fallback) |
| `src/assets/seed-nexus.ocs` | loadable v0.6.0-pre (does not replace seed) |
| `src/assets/nexus-v0.6.ocs` | Nexus fixture |
| `tests/fixtures/halt.ocs` | halt gate test |

Seed load order in the GUI: qrc `:/qt/qml/OcsNode/seed.ocs`, then relative `src/assets/seed.ocs`.

## Failure checklist

| Symptom | Check |
|---|---|
| Send does nothing | child view bound `engine: engine` instead of `protocol: appWindow.protocol` |
| Title says `NO GENAI KEY` | env / `.env` path; `--genai-debug` |
| Stays gated after resume | loaded document still contains `cmd/halt` |
| Console meters look empty | expected — counts derived from signals, no process RSS |
| Protocol tests fail on UTF-8 | fixture must start with the three-byte sigil, not a lookalike slash |
