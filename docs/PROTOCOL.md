# OCS/Node protocol grammar (as implemented in t484)

This is the grammar `ProtocolParser` / `ProtocolEmitter` actually accept.
Broader OCS export schemas (`ocs-protocol-export`) may list extra commands
(`⫻cmd/broadcast`, `⫻rta/traverse`, …). Those are **not** Node families until
they appear in `docs/ARCHITECTURE.md` and have a test.

Companion: [ENGINE.md](ENGINE.md), [CHAT.md](CHAT.md), [COMPONENTS.md](COMPONENTS.md).

## Sigil

Section headers begin with **U+2AFB** TRIPLE SOLIDUS BINARY RELATION
(`⫻`, UTF-8 `e2 ab bb`). Constant: `ProtocolParser::kSigilUtf8`.

A section starts on a sigil line and runs until the next sigil or EOF.

```
⫻family/path:qualifier
body line 1
body line 2
```

- UTF-8 input. CR is stripped from line endings.
- The first `:` on the header line splits **head** from **qualifier**.
- Head without `/` → `family` only, empty `path`.
- Head with `/` → `family` = before slash, `path` = after slash (may contain further slashes).
- Qualifier is the trimmed rest of the header (may contain spaces and `[key=value]` lists).
- Body leading/trailing newlines and trailing whitespace are trimmed on flush.
- Empty input → no sections, no errors.
- Non-empty input with no sigil → `ParseError{1, "no sections found"}`.
- Empty header after the sigil → `empty section header after sigil`.
- Nested `⫻end/` is parsed as a normal header, not expanded.

## C++ atom

```cpp
struct Section {
    std::string family;
    std::string path;
    std::string qualifier;
    std::string body;
    int line = 1;
    std::string type() const; // family or family/path
};
```

`type()` is the stable key for submit-vs-append.

## Frozen families (v0.4)

| Family / type | Qualifier (typical) | Body | Mutate |
|---|---|---|---|
| `protocol/ocs` | `[node=…] [repo=…] [version=…]` | optional notes | **submit** (identity) |
| `context/klmx` | `Kick/Lang` | molecule / space text | **submit** |
| `cmd/exec` | `ocs-node-engine`, `genai`, `nexus-export` | command payload | **append** |
| `cmd/halt` | reason | optional detail | **submit** (gates) |
| `cmd/mode` | `Fluid` \| `Swarm` \| `Predictive` \| `Hybrid` | unused | **submit** |
| `cmd/lang` | `EN`, `DE`, `KickLang` | unused | **submit** |
| `data/obj` | — | living objective | **submit** |
| `data/tas` | — | one step per line | **submit** |
| `data/ptas` | — | purified steps | **submit** |
| `flow/chat` | `host`, `user`, `KickForge`, `KickFlow`, `KickGuard` | turn text | **append** |
| `query/clarify` | `consent`, `parse`, `empty`, `genai`, `mode` | question | **append** |
| `display/header` | — | banner | **append** |
| `display/meta` | — | operator notes / axes | **append** |
| `display/content` | — | free display | **append** |

**Submit** = replace the first section of the same `type()`.
**Append** = always `push_back`.

There is **no** `cmd/resume`. Resume is `loadText` of a document that does not contain `cmd/halt`.

## Emitter

`ProtocolEmitter::emitText` is named that way so Qt’s `emit` macro cannot eat the identifier.

```
⫻family/path:qualifier
body
```

Multiple sections are joined with a blank line. Round-trip contract:

```
parse(emitText(parse(x)))
```

preserves section count, `family/path`, qualifier, and body
(`tests/test_protocol.cpp`).

## Seed and Nexus documents

- Startup: `src/assets/seed.ocs`
- Loadable v0.6.0-pre: `src/assets/seed-nexus.ocs` (does not replace seed)
- Plan fixture: `src/assets/nexus-v0.6.ocs`
- N7 Berlin / EmbodiedPipe fixture: `src/assets/nexus-v0.6-berlin.ocs` (halt-free; `[node=Berlin]`)

`exportNexus()` stamps `protocol/ocs` with `[version=0.6.0]` and writes axes into `display/meta`. Qualifier attributes are opaque text to the v0.4 parser.

## What this Node does *not* parse specially

- JSON sidecars
- Binary attachments
- Invented families (`data/nexus-blob`, `cmd/resume`)
- KickLang v4.1 module graphs (those belong to KickLang parser-core; Node transports sections)

A paste that contains a `protocol/ocs` section **replaces** the living document.
Any other sigil paste is ingested section-by-section on top of the current document
(plus a `flow/chat:host` recording of the raw text). See [CHAT.md](CHAT.md).
