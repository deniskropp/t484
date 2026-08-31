# Glossary (t484 / OCS Node)

| Term | Meaning here |
|---|---|
| **OCS** | Orion Collective System v2.1 — the meta-protocol this engine displays and stores. |
| **Node** | This product: C++ protocol core + optional Qt shells. Repo `deniskropp/t484`. |
| **OCS/Display** | The operator-facing surface (chat + console) bound to the living document. |
| **Sigil** | U+2AFB. Starts every section header. |
| **Section** | `{family, path, qualifier, body, line}`. `type()` = `family/path`. |
| **Living document** | `std::vector<Section>` inside `ProtocolEngine`. The transcript. |
| **Submit** | Replace first section of the same type (state). |
| **Append** | Always push (conversation). |
| **Gate / gated** | A `cmd/halt` section is present. Mutations except halt/mode are skipped. |
| **Resume** | Load a `protocol/ocs` document that does not contain `cmd/halt`. Not a command. |
| **TAS** | Task-Agnostic Step. Stored as `data/tas` lines. |
| **PTAS** | Purified TAS. `data/ptas`. |
| **KLMX** | KickLang molecule / formula / model / space / scope / reference. `context/klmx`. |
| **KickForge / KickFlow / KickGuard** | Three-agent-core labels. Also `flow/chat` qualifiers. |
| **Coherence** | Scalar `0..1` from `deriveCoherence`. Status-bar meter. Axes are additive. |
| **Nexus** | One `.ocs` file that *is* the operator state. `exportNexus` / `importNexus`. |
| **Phase E** | Planned UI: KickLangEditor, TasBoard, ConsentGateDialog. |
| **OCS Slate** | Product theme (`Theme.qml`). Dark is default; Light is the accessibility twin. |
| **Forge skill** | `ocs-node-engine`. May scaffold; must not fork a second product tree. |
| **Berlin Node** | Physical participant machine in Berlin. Not a t484 compile flavor. |
| **GenAI source** | Label for where the key was found. Never the key itself. |
