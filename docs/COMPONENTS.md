# t484 component and interface overview

Source of truth: this repository. Companion to [ARCHITECTURE.md](ARCHITECTURE.md).  
This document catalogs every shipped component, the interface it exposes, and how those interfaces compose. It does not invent families or QML identifiers.

**Naming freeze (repeat):** a C++ type and a QML file never share an identifier. C++ models are `*Model` / `*Item`. QML surfaces are `*View.qml` (plus `ProtocolStatusBar.qml`, which is chrome, not a typed model).

---

## 1. Layers

```
┌─────────────────────────────────────────────────────────────────┐
│  QML  OcsNode 1.0   main.qml  (ApplicationWindow id: appWindow) │
│  views bind protocol: appWindow.protocol  — never engine:engine │
└───────────────────────────────┬─────────────────────────────────┘
                                │ context properties
                                │   engine  → ProtocolEngineQt
                                │   tasModel → TasStatusModel
                                │   klmxItem → KlmxMoleculeItem
┌───────────────────────────────▼─────────────────────────────────┐
│  Qt façade   ProtocolEngineQt  +  GenAiClient  +  SectionListModel│
│  (QObject / QAbstractListModel; Qt6 Core, Qml, Network)         │
└───────────────────────────────┬─────────────────────────────────┘
                                │ NodeEngine.protocol()
┌───────────────────────────────▼─────────────────────────────────┐
│  STL core   ProtocolEngine  ChatSession  Parser  Emitter  Section│
│  (C++20, no Qt; tests link only this layer)                     │
└─────────────────────────────────────────────────────────────────┘
                                │ HTTP (only from GenAiClient)
                                ▼
              Google GenAI Interactions API  /v1beta/interactions
```

The living document is `std::vector<Section>` inside `ProtocolEngine`. There is no parallel chat store. The transcript ListView is `engine.sections`.

---

## 2. Protocol core (STL)

Headers: `include/ocsnode/*.h` (except `qt/`).  
Implementation: `src/protocol/`, `src/engine/ProtocolEngine.cpp`.

### 2.1 `Section` / `ParseError` / `ParseResult`

| Field / method | Type | Meaning |
|---|---|---|
| `family` | `string` | `protocol`, `cmd`, `data`, `flow`, `query`, `display`, `context`, … |
| `path` | `string` | rest after `/` (`chat`, `halt`, `obj`, …) |
| `qualifier` | `string` | text after `:` on the sigil line (`host`, `KickFlow`, `Hybrid`, …) |
| `body` | `string` | lines until the next sigil |
| `line` | `int` | 1-based source line of the header |
| `type()` | `string` | `family` or `family/path` |
| `empty()` | `bool` | all string fields empty |

`ParseError`: `{ line, message }`.  
`ParseResult`: `{ sections, errors }` with `ok()` iff `errors.empty()`.

### 2.2 `ProtocolParser`

| Method | Contract |
|---|---|
| `parse(text)` | UTF-8, line-oriented. A section starts on `U+2AFB` (`⫻`, UTF-8 `e2 ab bb`) and runs to the next sigil or EOF. |
| `startsWithSigil(line, bytes*)` | Detects the three-byte sigil. |
| `kSigilUtf8` | `"\xE2\xAB\xBB"` |

Empty input is silent (no sections, no errors). Non-empty input with no sigil is an error (`no sections found`). Nested `⫻end/` is recognized as a header, not expanded.

### 2.3 `ProtocolEmitter`

Named `emitText` (not `emit`) so Qt’s `emit` macro cannot eat the identifier.

| Method | Contract |
|---|---|
| `emitText(section)` | `⫻family/path:qualifier\nbody\n` |
| `emitText(sections)` | concatenated with a blank line between sections |

Round-trip: `parse(emitText(parse(x)))` preserves count, qualifier, and body (see `tests/test_protocol.cpp`).

### 2.4 `CoherenceState` / `deriveCoherence`

| Field | Values / meaning |
|---|---|
| `mode` | `Fluid` \| `Swarm` \| `Predictive` \| `Hybrid` (from `cmd/mode` qualifier) |
| `status` | `idle` \| `running` \| `gated` \| `complete` \| `error` |
| `coherence` | `0…1`, heuristic from presence of protocol/klmx/obj/tas minus halt |
| `gated` | true iff a `cmd/halt` section exists |
| `haltReason` | halt qualifier or body |
| `currentTasId` | first TAS step id scraped from `data/tas` / `data/ptas` |
| `activeSteps` | counted TAS/PTAS lines |

Deterministic v0.3 heuristic. Later replacement: CoherenceMonitorBridge.

### 2.5 `ProtocolEngine`

Qt-free document + state machine.

| Method | Mutates | Notes |
|---|---|---|
| `loadText(text)` | replaces `m_sections` | parse + `refreshState()` |
| `emitText()` | no | emitter over current sections |
| `sections()` / `state()` / `errors()` | no | |
| `setMode(mode)` | `cmd/mode` | submit-or-replace |
| `submit(section)` | first matching `type()` | **replace** (stateful) |
| `append(section)` | always push_back | **conversation** |
| `requestHalt(reason)` | `cmd/halt` via submit | calls `HaltHandler` |
| `setHaltHandler(fn)` | | |
| `sectionsByFamily(family)` | no | |
| `findByType(type)` | no | first match or `nullptr` |

Stateful types (replace): `protocol/ocs`, `cmd/mode`, `cmd/halt`, `cmd/lang`, `data/obj`, `data/tas`, `data/ptas`, `context/klmx`.  
Append types: `flow/chat`, `query/clarify`, `cmd/exec`, `display/*`.

### 2.6 `NodeEngine`

Thin façade for three-agent-core labeling.

| Method | Contract |
|---|---|
| `protocol()` | `ProtocolEngine&` |
| `setActor` / `actor` | last actor label (`KickForge` / `KickFlow` / `KickGuard`) |
| `ingest(text)` | `protocol().loadText(text)` |

Default actor: `KickFlow`.

### 2.7 `ChatSession` / `ChatTurnResult`

One host turn against the living document. No new command families.

`ChatTurnResult`:

| Field | Meaning |
|---|---|
| `ingested` | sections parsed or mapped from the raw turn |
| `replies` | KickForge / KickFlow / KickGuard sections appended this turn |
| `ok` | parse / empty-turn success |
| `gated` | engine gated after the turn |
| `requestLlm` | Qt should call GenAI (false for empty, parse error, document load, `/halt`, `/mode`) |
| `error` | human string for parse / empty |

`ChatSession::send(text)`:

1. Empty → `query/clarify:empty`, `ok=false`, no LLM.
2. Any `⫻` line → parse. Failure → host bubble + `query/clarify:parse`.
3. Slash map: `/halt` `/mode` `/exec` `/obj` `/tas` onto existing families.
4. Else wrap as `flow/chat:host`.
5. If ingested contains `protocol/ocs` → **load** the document (replace).
6. Else append `flow/chat:host` with the raw text, then apply ingested (`submit` vs `append` vs halt/mode).
7. While already gated, skip mutations other than halt/mode.
8. `replyAfter` emits KickGuard/KickForge/KickFlow sections; sets `requestLlm` for natural language / `/exec` / `/obj` / `/tas` / non-load sigil pastes.

Static helpers: `containsSigil`, `isStatefulType`.

---

## 3. Qt façade and models

Headers: `include/ocsnode/qt/`. Implementation: `src/engine/*Qt*`, `src/engine/GenAiClient.cpp`, `src/components/`.  
Linked only when Qt6 is found (`Core Gui Qml Quick QuickControls2 Network`).

### 3.1 Context properties (`src/main.cpp`)

| Name | C++ type | Lifetime |
|---|---|---|
| `engine` | `ProtocolEngineQt*` | process |
| `tasModel` | `TasStatusModel*` | process |
| `klmxItem` | `KlmxMoleculeItem*` | process |

QML module: `OcsNode 1.0` (`URI OcsNode`, resource prefix `/qt/qml`).  
`main.qml` aliases `readonly property var protocol: engine` on `ApplicationWindow` (`id: appWindow`) and **must** pass `protocol: appWindow.protocol` into child views. A child `property var engine` plus `engine: engine` is a self-binding to `null` (Send becomes a no-op; the window title still works).

CLI:

| Flag | Effect |
|---|---|
| *(none)* | load seed, run GUI |
| `--genai-status` | print `ready` / `source` / `model` (never the key), exit |
| `--genai-debug` | list env names and `.env` paths checked, exit |

Seed load order: qrc `:/qt/qml/OcsNode/seed.ocs`, then relative `src/assets/seed.ocs`.

### 3.2 `ProtocolEngineQt` — QML engine object

QObject wrapper around `NodeEngine` + `SectionListModel` + `GenAiClient`.

**Properties**

| Property | Type | Notify | Notes |
|---|---|---|---|
| `mode` | `QString` | `modeChanged` | writable |
| `status` | `QString` | `stateChanged` | |
| `coherence` | `double` | `stateChanged` | |
| `gated` | `bool` | `stateChanged` | |
| `haltReason` | `QString` | `stateChanged` | |
| `currentTasId` | `QString` | `stateChanged` | |
| `activeSteps` | `int` | `stateChanged` | |
| `actor` | `QString` | `actorChanged` | writable |
| `sourceText` | `QString` | `sourceChanged` | last emit |
| `sections` | `SectionListModel*` | CONSTANT | transcript model |
| `errorCount` | `int` | `stateChanged` | |
| `busy` | `bool` | `busyChanged` | GenAI in flight |
| `genaiReady` | `bool` | `genaiReadyChanged` | key resolved |
| `genaiModel` | `QString` | `genaiReadyChanged` | default `gemini-3.7-flash` |
| `genaiSource` | `QString` | `genaiReadyChanged` | `env:NAME` or `file:path` |

**Invokables**

| Method | Contract |
|---|---|
| `loadText(text)` | ingest; sync model |
| `emitText()` | current document |
| `requestHalt(reason)` | abort GenAI + `cmd/halt` |
| `submitMap(payload)` | map `sectionType` / `qualifier` / `body` (aliases `molecule`, `formula`) → `submit` |
| `sectionBody(type)` | first matching body or `""` |
| `sendChat(text)` | `ChatSession::send`; if `requestLlm` then `requestGenAi` |

**Signals:** `haltRequested(reason)`, `accepted(payload)`, `turnCompleted(ok)`, plus property notifiers.

`sendChat` path: local protocol mutation → `syncFromCore` → optional `cmd/exec:genai` + `flow/chat:KickFlow` pending → `GenAiClient::create` with protocol snapshot + host text + system instruction + `previous_interaction_id`. On finish, append `flow/chat:KickFlow` (or `query/clarify:genai` / KickGuard drop if gated mid-flight).

### 3.3 `SectionListModel`

`QAbstractListModel` of `Section`. Role names (QML):

| Role | QML name |
|---|---|
| FamilyRole | `family` |
| PathRole | `path` |
| TypeRole | `type` |
| QualifierRole | `qualifier` |
| BodyRole | `body` |
| LineRole | `line` |

`count` property = `rowCount`. `resetFrom(vector<Section>)` on every engine sync.

### 3.4 `TasStatusModel`

Telemetry for TAS chrome. Bound from `main.qml` via `Binding` on `engine.*`.

| Property | Default |
|---|---|
| `sectionType` | `display/tas-status` |
| `status` | `idle` |
| `mode` | `Hybrid` |
| `coherence` | `1.0` |
| `activeSteps` | `0` |
| `currentTasId` | `""` |
| `tasModel` | `[]` |
| `gated` | `false` |

Slots: `applyFromEngine(...)`, `submitStatusUpdate(payload)`.  
Signals: property notifiers, `accepted`, `haltRequested`.

### 3.5 `KlmxMoleculeItem`

Editable KLMX molecule for `context/klmx`.

| Property | Default |
|---|---|
| `sectionType` | `context/klmx` |
| `molecule` | `Kick/Lang` |
| `formula` | *(from seed `context/klmx` body)* |
| `modelName` | `OCS/Node Engine` |
| `space` | `OCS/Node` |
| `scope` | `global` |
| `reference` | `deniskropp/t484` |
| `mode` | `Hybrid` |
| `coherence` | `1.0` |
| `editable` | `true` |
| `validationStatus` | `idle` |

Slots: `submitMolecule(payload)`, `validateFormula()`.  
Signals: `accepted`, `validationRequested`, plus property notifiers.  
Inspector Submit → `engine.submitMap(payload)`.

### 3.6 `GenAiClient`

Sole network component. Not registered as a QML type; owned by `ProtocolEngineQt`.

| Method | Contract |
|---|---|
| `apiKey()` / `apiKeySource()` / `ready()` | resolve without logging the secret |
| `model()` | `GEMINI_MODEL` / `GOOGLE_GENAI_MODEL` or `gemini-3.7-flash` |
| `create(input, systemInstruction, previousId)` | `POST https://generativelanguage.googleapis.com/v1beta/interactions` |
| `abort()` | cancel in-flight reply |
| `parseDotEnv(raw)` | `KEY=value` / `export KEY=` / `KEY: value`; strips quotes and BOM |
| `extractOutputText(json, …)` | `steps[].type==model_output` text parts |
| `debugReport()` | env HIT/MISS and file paths; lengths only |

Auth header: `x-goog-api-key`. Also `Api-Revision: 2026-05-20`.  
Key lookup order: process env (`GEMINI_API_KEY`, `GOOGLE_API_KEY`, `GOOGLE_GENAI_API_KEY`, `GOOGLE_AI_API_KEY`), then `.env` walk from `T484_SOURCE_DIR`, cwd, application dir, `~/.config/t484/.env`, `~/.config/Exit/t484/.env`, `$XDG_RUNTIME_DIR/t484.env`.  
Capacity fallback model chain: requested → `gemini-3.6-flash` → `gemini-3.5-flash`.  
Signal `finished(ok, text, interactionId, error, usedModel)`.

The key is never written into a `Section`.

---

## 4. QML surfaces (`OcsNode 1.0`)

`src/qml/OcsNode/` + `src/qml/main.qml`. Module registered in `qmldir` and `qt_add_qml_module`.

### 4.1 Shell — `main.qml`

`ApplicationWindow` (`id: appWindow`).

| Binding | Source |
|---|---|
| `protocol` | context `engine` (`ProtocolEngineQt`) |
| `header` | `ProtocolStatusBar` |
| TAS strip | `TasStatusBarView { model: tasModel }` |
| transcript | `OcsChatTranscriptView { protocol: appWindow.protocol }` |
| composer | `OcsComposerView { protocol: appWindow.protocol }` |
| inspector | `KlmxMoleculeSpaceView { model: klmxItem }` + read-only `sourceText` |
| title | `protocol.genaiSource` or `NO GENAI KEY` |

Inspector visibility is `appWindow.inspectorVisible`, toggled from the composer.

### 4.2 View contracts

**`ProtocolStatusBar.qml`** (chrome, not `*View`)

| Property | Typical source |
|---|---|
| `mode`, `status`, `coherence`, `gated`, `actor`, `sectionCount` | `protocol.*` |
| `busy`, `genaiReady`, `genaiModel`, `genaiSource` | `protocol.*` |

**`TasStatusBarView.qml`**

| Property / signal | |
|---|---|
| `model` | `TasStatusModel` |
| `haltRequested(reason)` | → `protocol.requestHalt` |

**`OcsChatTranscriptView.qml`**

| Property | |
|---|---|
| `protocol` | `ProtocolEngineQt` |
| `model` | `protocol.sections` |

Delegate: `OcsChatBubbleView` (`family`, `sectionType`, `qualifier`, `sectionBody`). Host turns (`flow` + qualifier `host`/`user`) align right.

**`OcsComposerView.qml`**

| Property / signal | |
|---|---|
| `protocol` | `ProtocolEngineQt` (required; null ⇒ Send no-op) |
| `inspectorVisible` | bool |
| `inspectorToggled()` | |
| Enter | send; Shift+Enter newline |
| Send | `protocol.sendChat(text)` |

Shows GenAI source when `protocol.genaiReady`; otherwise the missing-key note.

**`KlmxMoleculeSpaceView.qml`**

| Property / signal | |
|---|---|
| `model` | `KlmxMoleculeItem` |
| `accepted(payload)` | → `protocol.submitMap` |
| `validationRequested(formula)` | |

**`OcsSectionView.qml`**

Card for a single section (`sectionType`, `qualifier`, `sectionBody`, `collapsed`). Shipped; not on the v0.3 chat layout (bubbles replaced the list of cards). Keep for inspector / Phase E.

---

## 5. Protocol families as UI

| Section `type` | Qualifier (typical) | Surface |
|---|---|---|
| `protocol/ocs` | `[node=…]` | transcript bubble; load-document trigger |
| `context/klmx` | `Kick/Lang` | inspector molecule + bubble |
| `cmd/mode` | `Hybrid`… | status bar mode |
| `cmd/halt` | reason | gated chrome; KickGuard |
| `cmd/exec` | `ocs-node-engine` / `genai` | audit in transcript |
| `data/obj` | | living objective |
| `data/tas` / `data/ptas` | | TAS strip (`activeSteps`, `currentTasId`) |
| `flow/chat` | `host` / `KickForge` / `KickFlow` / `KickGuard` | chat bubbles |
| `query/clarify` | `consent` / `parse` / `empty` / `genai` / `mode` | amber bubble |
| `display/header` | | green bubble / seed banner |

Slash → family map (composer text, not new syntax):

| Input | Section |
|---|---|
| `/halt [reason]` | `cmd/halt` |
| `/mode [name]` | `cmd/mode` |
| `/exec [body]` | `cmd/exec:ocs-node-engine` |
| `/obj [text]` | `data/obj` |
| `/tas [lines]` | `data/tas` |

---

## 6. One Send turn (sequence)

```
Composer.send
  → ProtocolEngineQt.sendChat(text)
      → ChatSession.send          // STL, offline
          append flow/chat:host
          apply slash / sigil / halt gate
          optional KickForge / KickGuard replies
          requestLlm?
      → syncFromCore (SectionListModel reset)
      → if requestLlm && !gated && genaiReady:
            append cmd/exec:genai
            append flow/chat:KickFlow  "calling …"
            GenAiClient.create(...)     // async HTTP
        else if !genaiReady:
            query/clarify:genai
  ← GenAiClient.finished
      → append flow/chat:KickFlow  (model text)
        or query/clarify:genai     (error)
        or KickGuard drop          (gated while waiting)
  → ListView countChanged → positionViewAtEnd
```

KickGuard conditions that skip GenAI: `gated`, `/halt`, `/mode`, empty turn, parse failure, full `protocol/ocs` load.

---

## 7. Tests

| Binary | Layer | Covers |
|---|---|---|
| `ocsnode_protocol_tests` | STL only | parse, emit round-trip, engine halt/mode, `append` chat turns, `ChatSession` slash/gate/`requestLlm`, seed fixture |
| `ocsnode_genai_tests` | Qt Core+Network, no GUI | `extractOutputText`, `parseDotEnv` |

No test talks to the network.

---

## 8. Planned (Phase E)

Not shipped. Do not reuse these identifiers for C++ types if a QML file of the same name exists.

- KickLangEditor
- TasBoard
- ConsentGateDialog (halt is currently chrome + `query/clarify:consent`, not a modal)

---

## 9. File map

| Path | Component |
|---|---|
| `include/ocsnode/Section.h` | `Section`, `ParseError`, `ParseResult` |
| `include/ocsnode/ProtocolParser.h` | parser |
| `include/ocsnode/ProtocolEmitter.h` | emitter |
| `include/ocsnode/CoherenceState.h` | `deriveCoherence` |
| `include/ocsnode/ProtocolEngine.h` | document engine |
| `include/ocsnode/NodeEngine.h` | actor façade |
| `include/ocsnode/ChatSession.h` | turn processor |
| `include/ocsnode/qt/ProtocolEngineQt.h` | QML engine |
| `include/ocsnode/qt/SectionListModel.h` | transcript model |
| `include/ocsnode/qt/GenAiClient.h` | Interactions API |
| `include/ocsnode/qt/TasStatusModel.h` | TAS model |
| `include/ocsnode/qt/KlmxMoleculeItem.h` | KLMX item |
| `src/qml/main.qml` | shell |
| `src/qml/OcsNode/*.qml` | views |
| `src/assets/seed.ocs` | startup document |
