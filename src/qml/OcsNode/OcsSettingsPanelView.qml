import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#222222"

    property var protocol: null
    property string themeName: "Dark"
    property int fontPointSize: 12
    property bool autoScrollTranscript: true
    property bool tasStripVisible: true
    property bool moleculeVisible: true
    property bool showRawSections: false
    property bool verboseLogging: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Label {
            text: "Settings"
            color: "#c9d1d9"
            font.bold: true
            font.pixelSize: 14
        }

        TabBar {
            id: settingsTabs
            Layout.fillWidth: true
            TabButton { text: "General" }
            TabButton { text: "GenAI" }
            TabButton { text: "Interface" }
            TabButton { text: "Developer" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: settingsTabs.currentIndex

            Flickable {
                clip: true
                contentHeight: generalCol.implicitHeight
                Column {
                    id: generalCol
                    width: parent.width
                    spacing: 8
                    Label { text: "Theme"; color: "#8b949e" }
                    ComboBox {
                        model: ["Dark", "Light"]
                        currentIndex: root.themeName === "Light" ? 1 : 0
                        onActivated: root.themeName = model[index]
                    }
                    Label { text: "Font Size: " + root.fontPointSize; color: "#8b949e" }
                    Slider {
                        from: 10
                        to: 22
                        value: root.fontPointSize
                        onMoved: root.fontPointSize = Math.round(value)
                        width: parent.width
                    }
                    CheckBox {
                        text: "Auto-scroll transcript"
                        checked: root.autoScrollTranscript
                        onToggled: root.autoScrollTranscript = checked
                    }
                }
            }

            Flickable {
                clip: true
                contentHeight: genaiCol.implicitHeight
                Column {
                    id: genaiCol
                    width: parent.width
                    spacing: 8
                    Label {
                        text: "Key source (read-only — never written into the protocol document)"
                        color: "#8b949e"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    TextField {
                        width: parent.width
                        readOnly: true
                        text: root.protocol && root.protocol.genaiReady
                              ? root.protocol.genaiSource
                              : "NO KEY in this process"
                    }
                    Label { text: "Model"; color: "#8b949e" }
                    TextField {
                        width: parent.width
                        readOnly: true
                        text: root.protocol ? root.protocol.genaiModel : "gemini-3.7-flash"
                    }
                    Label {
                        text: "Set GEMINI_API_KEY / GEMINI_MODEL in the process env or .env. Fallback chain is engine-side (3.7 → 3.6 → 3.5)."
                        color: "#6e7681"
                        wrapMode: Text.Wrap
                        width: parent.width
                        font.pixelSize: 11
                    }
                }
            }

            Flickable {
                clip: true
                contentHeight: ifaceCol.implicitHeight
                Column {
                    id: ifaceCol
                    width: parent.width
                    spacing: 8
                    CheckBox {
                        text: "Enable TAS strip"
                        checked: root.tasStripVisible
                        onToggled: root.tasStripVisible = checked
                    }
                    CheckBox {
                        text: "Enable molecule inspector"
                        checked: root.moleculeVisible
                        onToggled: root.moleculeVisible = checked
                    }
                }
            }

            Flickable {
                clip: true
                contentHeight: devCol.implicitHeight
                Column {
                    id: devCol
                    width: parent.width
                    spacing: 8
                    CheckBox {
                        text: "Show raw sections"
                        checked: root.showRawSections
                        onToggled: root.showRawSections = checked
                    }
                    CheckBox {
                        text: "Verbose logging"
                        checked: root.verboseLogging
                        onToggled: root.verboseLogging = checked
                    }
                    Label {
                        text: "Actor: " + (root.protocol ? root.protocol.actor : "—")
                        color: "#c9d1d9"
                        font.family: "monospace"
                    }
                    Label {
                        text: "Coherence: "
                              + (root.protocol ? Math.round(root.protocol.coherence * 100) + "%" : "—")
                        color: "#c9d1d9"
                        font.family: "monospace"
                    }
                }
            }
        }
    }
}
