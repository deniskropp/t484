# t484 — OCS/Node Engine

**OCS/Node Engine for OCS/Display**  
C++/QML protocol handler with rich input/output components.

Part of the Orion Collective System (OCS v2.1).  
Implements the living protocol surface that renders `⫻` sections, KickLang transport, TAS/PTAS boards, and interactive consent gates.

## Status

- Repository: public
- Language: C++20 + Qt 6 / QML
- Skill: `ocs-node-engine` (Flow Nexus participant)
- Berlin Node grounding: available via `berlin-node-ocs-participant`

## Architecture (high-level)

```
src/
├── protocol/          # ⫻ section parser / emitter (KickLang v4.1 hooks)
├── engine/            # OCS/Node core + three-agent-core bridges
├── qml/OcsNode/       # Rich I/O components (OcsSectionView, KickLangEditor, TasBoard, ProtocolStatusBar…)
└── main.cpp
```

## Build (Qt 6)

```bash
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt6
cmake --build .
./t484
```

## Quick Start Components

- `OcsSectionView` — syntax-highlighted collapsible ⫻ section
- `KickLangEditor` — live validation editor
- `TasBoard` — drag-reorder TAS/PTAS cards
- `ProtocolStatusBar` — coherence / mode / participant indicators
- `ConsentGateDialog` — human-in-the-loop gate

## OCS Integration

This repository is the canonical source for the `ocs-node-engine` skill.  
All scaffolding, protocol schema, and QML component generation flows through the skill.

```
ϫcmd/exec:ocs-node-engine
```

## License

To be determined. Currently under active co-agency development by Denis Oliver Kropp / Exit.
