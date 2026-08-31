import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root
    color: Theme.bgPanel

    property var protocol: null
    property string themeName: "Dark"
    property int fontPointSize: 12
    property bool autoScrollTranscript: true
    property bool tasStripVisible: true
    property bool moleculeVisible: true
    property bool showRawSections: false
    property bool verboseLogging: false

    onThemeNameChanged: Theme.apply(themeName)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Label {
            text: "Settings"
            color: Theme.text
            font.family: Theme.fontUi
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
                    Label { text: "Theme"; color: Theme.textMuted; font.family: Theme.fontUi }
                    ComboBox {
                        model: ["Dark", "Light"]
                        currentIndex: root.themeName === "Light" ? 1 : 0
                        onActivated: root.themeName = model[index]
                    }
                    Label { text: "Font Size: " + root.fontPointSize; color: Theme.textMuted; font.family: Theme.fontUi }
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
                        color: Theme.textMuted
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
                    Label { text: "Model"; color: Theme.textMuted }
                    TextField {
                        width: parent.width
                        readOnly: true
                        text: root.protocol ? root.protocol.genaiModel : "gemini-3.7-flash"
                    }
                    Label {
                        text: "Set GEMINI_API_KEY / GEMINI_MODEL in the process env or .env. Fallback chain is engine-side (3.7 → 3.6 → 3.5)."
                        color: Theme.textFaint
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
                        text: "Actor: " + (root.protocol ? root.protocol.actor : "\u2014")
                        color: Theme.text
                        font.family: Theme.fontMono
                    }
                    Label {
                        text: "Coherence: "
                              + (root.protocol ? Math.round(root.protocol.coherence * 100) + "%" : "\u2014")
                        color: Theme.text
                        font.family: Theme.fontMono
                    }
                }
            }
        }
    }
}
