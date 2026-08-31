# Chat turn machine

`ChatSession` processes one host turn against the living document.
Implementation: `include/ocsnode/ChatSession.h`, `src/protocol/ChatSession.cpp`.
Qt calls it from `ProtocolEngineQt::sendChat`.

There is no parallel transcript. Host and Kick* replies are sections.

## Result

```cpp
struct ChatTurnResult {
    std::vector<Section> ingested;
    std::vector<Section> replies;
    bool ok = true;
    bool gated = false;
    bool requestLlm = false;
    std::string error;
};
```

`requestLlm` is the only signal the Qt layer needs to decide whether to touch the network.

## `send(text)` order

1. Empty text → `query/clarify:empty`, `ok=false`, no LLM.
2. Any line starting with the sigil → parse.
   - Parse failure → host bubble + `query/clarify:parse`, no LLM.
3. Slash map onto **existing** families only:

   | Input | Section |
   |---|---|
   | `/halt [reason]` | `cmd/halt` |
   | `/mode [name]` | `cmd/mode` |
   | `/exec [body]` | `cmd/exec:ocs-node-engine` |
   | `/obj [text]` | `data/obj` |
   | `/tas [lines]` | `data/tas` |

4. Otherwise wrap as `flow/chat:host` with the raw text.
5. If ingested contains `protocol/ocs` → **load** (replace the document). No LLM.
6. Else append `flow/chat:host` with the raw text, then apply ingested
   (`submit` for stateful types, `append` for conversation types, halt/mode special).
7. If the engine was already gated, skip mutations other than halt/mode.
8. `replyAfter` emits KickForge / KickFlow / KickGuard sections as needed.
   Sets `requestLlm` for natural language, `/exec`, `/obj`, `/tas`, and non-load sigil pastes.
   Does **not** set `requestLlm` for empty, parse error, document load, `/halt`, `/mode`.

## Kick* roles in the Node

| Actor | Typical section | Job in t484 |
|---|---|---|
| host / user | `flow/chat:host` | raw operator text |
| KickForge | `flow/chat:KickForge` | acknowledge structure / TAS-shaped input |
| KickFlow | `flow/chat:KickFlow` | default actor; GenAI reply lands here |
| KickGuard | `flow/chat:KickGuard` + `query/clarify:consent` | halt gate, refuse LLM while gated |

`NodeEngine.actor` defaults to `KickFlow`.

## GenAI path (Qt only)

```
Composer.send
  → ProtocolEngineQt.sendChat
      → ChatSession.send          // STL, offline
      → syncFromCore
      → if requestLlm && !gated && genaiReady:
            append cmd/exec:genai
            append flow/chat:KickFlow  "calling …"
            GenAiClient.create(snapshot + host + system + previous_interaction_id)
        else if requestLlm && !genaiReady:
            query/clarify:genai
  ← finished
      → append flow/chat:KickFlow  (model text)
        or query/clarify:genai
        or KickGuard drop if gated mid-flight
```

Transport: `POST https://generativelanguage.googleapis.com/v1beta/interactions`
with `x-goog-api-key`. Default model `gemini-3.7-flash` (`GEMINI_MODEL` override).
Capacity fallback: 3.7 → 3.6 → 3.5 flash. Turns chain via `previous_interaction_id`.

The key is never a section. `genaiSource` is a label (`env:GEMINI_API_KEY` or `file:…`).

## Composer UX

`OcsComposerView`: Enter sends, Shift+Enter newline.
`/halt` can also call `requestHalt` directly.
Inspector toggle is shell-local (`inspectorVisible`), not a protocol command.
