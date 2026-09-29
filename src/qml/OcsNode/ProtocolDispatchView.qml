import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

// ProtocolDispatchView — OcsNode 1.0 plate for frozen-family dispatch.
// Bind protocol: appWindow.protocol (never engine:engine).
// C++ authority remains ProtocolEngineQt + ChatSession.
// No C++ twin. Ungate is resumeFromHalt(), not a cmd/resume family.

Rectangle {
    id: root
    color: Theme.bg

    property var protocol: null
    property string lastResult: "idle"
    property string lastFamily: ""
    property string statusMessage: "Ready — frozen families only"

    readonly property var families: [
        { type: "cmd/mode", mutate: "submit", note: "Fluid | Swarm | Predictive | Hybrid" },
        { type: "cmd/halt", mutate: "submit", note: "gates document; no cmd/resume family" },
        { type: "cmd/lang", mutate: "submit", note: "EN | DE | KickLang" },
        { type: "cmd/exec", mutate: "append", note: "ocs-node-engine | genai | nexus-export" },
        { type: "data/obj", mutate: "submit", note: "living objective" },
        { type: "data/tas", mutate: "submit", note: "one step per line" },
        { type: "data/ptas", mutate: "submit", note: "purified steps" },
        { type: "context/klmx", mutate: "submit", note: "Kick/Lang molecule" },
        { type: "flow/chat", mutate: "append", note: "host turn via sendChat" },
        { type: "query/clarify", mutate: "append", note: "consent | parse | empty | genai | mode" },
        { type: "display/meta", mutate: "append", note: "axes / operator notes" }
    ]

    signal exportNexusRequested()
    signal importNexusRequested()
    signal copySnapshotRequested()
    signal dispatched(string sectionType, string qualifier, bool ok)

    function gatedBlocks(sectionType) {
        if (!protocol || !protocol.gated)
            return false
        // KickGuard: while gated skip mutations other than halt/mode. Export is read.
        return sectionType !== "cmd/halt" && sectionType !== "cmd/mode"
    }

    function dispatchSubmit(sectionType, qualifier, body) {
        if (!protocol) {
            statusMessage = "No protocol binding"
            lastResult = "error"
            return false
        }
        if (gatedBlocks(sectionType)) {
            statusMessage = "Gated — KickGuard blocks " + sectionType
            lastResult = "gated"
            lastFamily = sectionType
            dispatched(sectionType, qualifier, false)
            return false
        }

        if (sectionType === "cmd/halt") {
            protocol.requestHalt(qualifier && qualifier.length ? qualifier : body)
            lastResult = "halted"
            lastFamily = "cmd/halt"
            statusMessage = "Halt requested"
            dispatched(sectionType, qualifier, true)
            return true
        }
        if (sectionType === "cmd/mode") {
            protocol.setMode(qualifier && qualifier.length ? qualifier : "Hybrid")
            lastResult = "ok"
            lastFamily = "cmd/mode"
            statusMessage = "Mode → " + protocol.mode
            dispatched(sectionType, qualifier, true)
            return true
        }
        if (sectionType === "flow/chat") {
            const ok = protocol.sendChat(body)
            lastResult = ok ? "ok" : "error"
            lastFamily = "flow/chat"
            statusMessage = ok ? "sendChat accepted" : "sendChat rejected"
            dispatched(sectionType, qualifier, ok)
            return ok
        }
        if (sectionType === "cmd/exec" && qualifier === "nexus-export") {
            exportNexusRequested()
            lastResult = "ok"
            lastFamily = "cmd/exec"
            statusMessage = "Nexus export requested (read allowed while gated)"
            dispatched(sectionType, qualifier, true)
            return true
        }

        protocol.submitMap({
            "sectionType": sectionType,
            "qualifier": qualifier,
            "body": body
        })
        lastResult = "ok"
        lastFamily = sectionType
        statusMessage = "submitMap " + sectionType
        dispatched(sectionType, qualifier, true)
        return true
    }

    function dispatchSlash(text) {
        if (!protocol) {
            statusMessage = "No protocol binding"
            lastResult = "error"
            return false
        }
        const raw = text ? String(text).trim() : ""
        if (!raw.length) {
            statusMessage = "Empty dispatch"
            lastResult = "error"
            return false
        }
        // ChatSession slash map lives in C++. QML must not invent families.
        const ok = protocol.sendChat(raw)
        lastResult = ok ? "ok" : "error"
        lastFamily = raw.charAt(0) === "/" ? "slash" : "flow/chat"
        statusMessage = ok ? "Routed through ChatSession.send" : "ChatSession rejected"
        dispatched(lastFamily, "", ok)
        return ok
    }

    function ungate() {
        if (!protocol)
            return false
        const ok = protocol.resumeFromHalt()
        lastResult = ok ? "ok" : "error"
        lastFamily = "ungate"
        statusMessage = ok ? "Gate removed (load without cmd/halt)" : "Ungate failed"
        return ok
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.bgRaised
            border.color: Theme.border
            border.width: Theme.borderWidth
            radius: Theme.radiusSm

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Label {
                    text: "Protocol Dispatch"
                    font.family: Theme.fontUi
                    font.bold: true
                    font.pixelSize: 13
                    color: Theme.text
                }

                Rectangle {
                    radius: Theme.radiusSm
                    color: root.protocol && root.protocol.gated ? Theme.danger
                          : (root.lastResult === "error" ? Theme.amber : Theme.emerald)
                    implicitWidth: stateLabel.implicitWidth + 10
                    implicitHeight: 18
                    Label {
                        id: stateLabel
                        anchors.centerIn: parent
                        text: root.protocol && root.protocol.gated ? "GATED"
                              : (root.lastResult === "error" ? "ERROR" : "OPEN")
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.bgChrome
                    }
                }

                Label {
                    text: (root.protocol ? root.protocol.sections.count : 0) + " sections"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.textMuted
                }

                Label {
                    text: "actor " + (root.protocol ? root.protocol.actor : "—")
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.violet
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: root.statusMessage
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.cyan
                    elide: Text.ElideRight
                    Layout.maximumWidth: 360
                }

                Button {
                    text: "Export"
                    onClicked: root.exportNexusRequested()
                }
                Button {
                    text: "Import"
                    onClicked: root.importNexusRequested()
                }
                Button {
                    text: "Copy"
                    onClicked: root.copySnapshotRequested()
                }
                Button {
                    text: "Ungate"
                    enabled: root.protocol && root.protocol.gated
                    onClicked: root.ungate()
                }
            }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            Rectangle {
                SplitView.preferredWidth: 280
                SplitView.minimumWidth: 200
                color: Theme.bgRaised
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radiusSm

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    Label {
                        text: "Frozen families"
                        font.family: Theme.fontUi
                        font.bold: true
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }

                    ListView {
                        id: familyList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.families
                        spacing: 2
                        currentIndex: 0

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: familyList.width
                            height: 36
                            radius: Theme.radiusSm
                            color: familyList.currentIndex === index ? Theme.bgHover : Theme.bgSunken
                            border.color: familyList.currentIndex === index ? Theme.borderGlow : Theme.borderSubtle
                            border.width: Theme.borderWidth

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: Theme.roleAccent("", modelData.type.split("/")[0], false)
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true
                                    Label {
                                        text: "⫻" + modelData.type
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.text
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: modelData.mutate + " · " + modelData.note
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    familyList.currentIndex = index
                                    typeField.text = modelData.type
                                    if (modelData.type === "cmd/mode")
                                        qualifierField.text = root.protocol ? root.protocol.mode : "Hybrid"
                                    else if (modelData.type === "cmd/exec")
                                        qualifierField.text = "ocs-node-engine"
                                    else if (modelData.type === "context/klmx")
                                        qualifierField.text = "Kick/Lang"
                                    else if (modelData.type === "flow/chat")
                                        qualifierField.text = "host"
                                    else
                                        qualifierField.text = ""
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                SplitView.fillWidth: true
                color: Theme.bgSunken
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radiusSm

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 6

                        Label {
                            text: "type()"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                        TextField {
                            id: typeField
                            Layout.fillWidth: true
                            text: "cmd/exec"
                            font.family: Theme.fontMono
                            color: Theme.text
                            background: Rectangle {
                                color: Theme.bgRaised
                                border.color: Theme.border
                                radius: Theme.radiusSm
                            }
                        }

                        Label {
                            text: "qualifier"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                        TextField {
                            id: qualifierField
                            Layout.fillWidth: true
                            text: "ocs-node-engine"
                            font.family: Theme.fontMono
                            color: Theme.text
                            placeholderText: "Hybrid · genai · host · consent"
                            background: Rectangle {
                                color: Theme.bgRaised
                                border.color: Theme.border
                                radius: Theme.radiusSm
                            }
                        }
                    }

                    Label {
                        text: "body"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        TextArea {
                            id: bodyArea
                            placeholderText: "Section body. TAS: one step per line.\nSlash map also accepted below: /halt /mode /exec /obj /tas"
                            color: Theme.text
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            selectByMouse: true
                            background: null
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Button {
                            text: "Dispatch submitMap"
                            highlighted: true
                            enabled: root.protocol !== null
                            onClicked: root.dispatchSubmit(typeField.text.trim(),
                                                           qualifierField.text.trim(),
                                                           bodyArea.text)
                        }
                        Button {
                            text: "sendChat body"
                            enabled: root.protocol !== null
                            onClicked: root.dispatchSlash(bodyArea.text)
                        }
                        Button {
                            text: "/halt"
                            enabled: root.protocol !== null
                            onClicked: root.dispatchSubmit("cmd/halt",
                                                           qualifierField.text.length ? qualifierField.text : "operator",
                                                           bodyArea.text)
                        }
                        Button {
                            text: "setMode"
                            enabled: root.protocol !== null
                            onClicked: root.dispatchSubmit("cmd/mode",
                                                           qualifierField.text.length ? qualifierField.text : "Hybrid",
                                                           "")
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: root.protocol && root.protocol.gated
                                  ? ("halt: " + root.protocol.haltReason)
                                  : ("coherence " + (root.protocol ? Math.round(root.protocol.coherence * 100) + "%" : "—"))
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: root.protocol && root.protocol.gated ? Theme.danger : Theme.cyan
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Theme.bgChrome
                        radius: Theme.radiusSm
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            Label {
                                text: "slash"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.textMuted
                            }
                            TextField {
                                id: slashField
                                Layout.fillWidth: true
                                placeholderText: "/halt reason  ·  /mode Hybrid  ·  /exec body  ·  /obj text  ·  /tas lines"
                                font.family: Theme.fontMono
                                color: Theme.text
                                background: Rectangle {
                                    color: Theme.bgRaised
                                    border.color: Theme.borderSubtle
                                    radius: Theme.radiusSm
                                }
                                Keys.onReturnPressed: root.dispatchSlash(slashField.text)
                            }
                            Button {
                                text: "Route"
                                onClicked: root.dispatchSlash(slashField.text)
                            }
                        }
                    }
                }
            }

            Rectangle {
                SplitView.preferredWidth: 280
                SplitView.minimumWidth: 200
                color: Theme.bgRaised
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radiusSm

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    Label {
                        text: "Living sections"
                        font.family: Theme.fontUi
                        font.bold: true
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }

                    ListView {
                        id: sectionList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.protocol ? root.protocol.sections : null
                        spacing: 2

                        delegate: Rectangle {
                            width: sectionList.width
                            height: 28
                            radius: Theme.radiusSm
                            color: Theme.bgSunken
                            border.color: Theme.borderSubtle
                            border.width: Theme.borderWidth

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 6

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: Theme.roleAccent(model.qualifier, model.family, false)
                                }
                                Label {
                                    text: model.type
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    Layout.preferredWidth: 92
                                }
                                Label {
                                    text: model.qualifier ? ":" + model.qualifier : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    typeField.text = model.type
                                    qualifierField.text = model.qualifier
                                    bodyArea.text = model.body
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            color: Theme.bgChrome
            radius: Theme.radiusSm
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 16
                Label {
                    text: "U+2AFB · submit vs append by type() · no invented families"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textMuted
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: "last " + (root.lastFamily.length ? root.lastFamily : "—") + " · " + root.lastResult
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.cyan
                }
                Label {
                    text: "errors " + (root.protocol ? root.protocol.errorCount : 0)
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: (root.protocol && root.protocol.errorCount > 0) ? Theme.danger : Theme.emerald
                }
            }
        }
    }
}
