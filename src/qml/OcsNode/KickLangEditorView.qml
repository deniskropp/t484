import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root
    color: Theme.bg

    property var protocol: null
    property string editorText: ""
    property bool isDirty: false
    property string statusMessage: ""

    signal exportNexusRequested()
    signal importNexusRequested()
    signal copySnapshotRequested()

    onProtocolChanged: syncFromEngine()

    function syncFromEngine() {
        if (!protocol)
            return
        editorText = protocol.sourceText.length > 0 ? protocol.sourceText : protocol.emitText()
        isDirty = false
        statusMessage = "Synced with living document"
    }

    function applyToEngine() {
        if (!protocol)
            return
        const ok = protocol.loadText(editorText)
        if (ok) {
            isDirty = false
            statusMessage = "Applied document (" + protocol.sections.count + " sections)"
        } else {
            statusMessage = "Parse errors: " + protocol.errorCount
        }
    }

    function reEmitEngine() {
        if (!protocol)
            return
        editorText = protocol.emitText()
        isDirty = false
        statusMessage = "Re-emitted canonical document"
    }

    function formatNexus() {
        if (!protocol)
            return
        editorText = protocol.exportNexus()
        isDirty = true
        statusMessage = "Export snapshot generated"
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
                    text: "KickLang Editor"
                    font.family: Theme.fontUi
                    font.bold: true
                    font.pixelSize: 13
                    color: Theme.text
                }

                Rectangle {
                    radius: Theme.radiusSm
                    color: root.isDirty ? Theme.amber : Theme.emerald
                    implicitWidth: dirtyLabel.implicitWidth + 8
                    implicitHeight: 18
                    Label {
                        id: dirtyLabel
                        anchors.centerIn: parent
                        text: root.isDirty ? "MODIFIED" : "SYNCED"
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

                Item { Layout.fillWidth: true }

                Label {
                    text: root.statusMessage
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.cyan
                    elide: Text.ElideRight
                    Layout.maximumWidth: 300
                }

                Button {
                    text: "Apply / Ingest"
                    enabled: root.isDirty && root.protocol !== null
                    onClicked: root.applyToEngine()
                }

                Button {
                    text: "Re-emit"
                    enabled: root.protocol !== null
                    onClicked: root.reEmitEngine()
                }

                Button {
                    text: "Format Nexus"
                    enabled: root.protocol !== null
                    onClicked: root.formatNexus()
                }

                Button {
                    text: "Export"
                    onClicked: root.exportNexusRequested()
                }

                Button {
                    text: "Copy"
                    onClicked: root.copySnapshotRequested()
                }
            }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            Rectangle {
                SplitView.preferredWidth: 260
                SplitView.minimumWidth: 180
                SplitView.maximumWidth: 400
                SplitView.fillHeight: true
                color: Theme.bgRaised
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radiusSm

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    Label {
                        text: "Sections Navigator"
                        font.family: Theme.fontUi
                        font.bold: true
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }

                    ListView {
                        id: sectionNavList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.protocol ? root.protocol.sections : null
                        spacing: 2

                        delegate: Rectangle {
                            width: sectionNavList.width
                            height: 28
                            radius: Theme.radiusSm
                            color: navMouse.containsMouse ? Theme.bgHover : Theme.bgSunken
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
                                    Layout.preferredWidth: 90
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
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    const query = "⫻" + model.type
                                    const idx = codeArea.text.indexOf(query)
                                    if (idx >= 0) {
                                        codeArea.cursorPosition = idx
                                        codeArea.select(idx, idx + query.length)
                                        codeArea.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                SplitView.fillWidth: true
                SplitView.fillHeight: true
                color: Theme.bgSunken
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radiusSm

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true

                    TextArea {
                        id: codeArea
                        text: root.editorText
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        wrapMode: Text.NoWrap
                        selectByMouse: true
                        tabStopDistance: 32
                        background: null
                        onTextChanged: {
                            if (root.editorText !== text) {
                                root.editorText = text
                                root.isDirty = true
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
                    text: "UTF-8 \u2014 \u2AFB line-oriented syntax"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "Chars: " + root.editorText.length
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textMuted
                }

                Label {
                    text: "Coherence: " + (root.protocol ? Math.round(root.protocol.coherence * 100) + "%" : "\u2014")
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.cyan
                }

                Label {
                    text: "Errors: " + (root.protocol ? root.protocol.errorCount : 0)
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: (root.protocol && root.protocol.errorCount > 0) ? Theme.danger : Theme.emerald
                }
            }
        }
    }
}
