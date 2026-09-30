# TAS — t484 v0.7 Kirigami chassis

```
⫻data/tas:
K0 Name freeze: QML import org.kde.kirigami as Kirigami (KF6). No KF5 Kirigami2 dep.
K1 Third shell src/qml/kirigami.qml. Do not rewrite main.qml / console.qml.
K2 Binary t484-kirigami (T484_SHELL_KIRIGAMI) + flag t484 --kirigami.
K3 Kirigami.Action maps onto existing families only (/halt /mode nexus I/O).
K4 ConsentGateDialog stays the halt overlay. No cmd/resume family.
K5 CMake: kirigami.qml joins OcsNode 1.0. KF6 is runtime, not REQUIRED.
K6 Docs: KIRIGAMI.md + INDEX / ARCHITECTURE / BUILD / OPERATOR / PANELS.
K7 Berlin Node: prefer this shell on neon 6; HD 4400 / 12 GiB — no extra inference.
```

## Acceptance

| Id | Done when |
|---|---|
| K0 | no `Kirigami2` / KF5 package name in CMake |
| K1 | `main.qml` and `console.qml` unchanged as default shells |
| K2 | `./build/t484-kirigami` and `./build/t484 --kirigami` resolve `kirigami.qml` |
| K3 | drawer Halt / Mode / Export call existing `ProtocolEngineQt` invokables |
| K4 | gated session still blocks GenAI; export remains a read |
| K5 | Qt6-missing still builds protocol core only |
| K6 | INDEX links this plan and `docs/KIRIGAMI.md` |

## Halt / consent

Export while gated is allowed. Import that contains `cmd/halt` stays gated.
Resume = load a `protocol/ocs` document without `cmd/halt`, or `resumeFromHalt()`.
