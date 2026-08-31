import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root
    color: Theme.bgPanel

    property var protocol: null
    property int genaiCallCount: 0
    property real avgResponseTime: 0
    property real lastResponseSeconds: 0
    property int tasActiveSteps: 0

    readonly property int sectionCount: protocol && protocol.sections ? protocol.sections.count : 0
    readonly property int errorCount: protocol ? protocol.errorCount : 0
    readonly property real coherence: protocol ? protocol.coherence : 0
    readonly property bool busy: protocol ? protocol.busy : false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Label {
            text: "Metrics"
            font.family: Theme.fontUi
            font.bold: true
            font.pointSize: 14
            color: Theme.text
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: 12
            rowSpacing: 6

            Label { text: "Active Sections:"; color: Theme.textMuted; font.family: Theme.fontUi }
            Label { text: String(root.sectionCount); color: Theme.text; font.family: Theme.fontMono }

            Label { text: "GenAI Calls:"; color: Theme.textMuted; font.family: Theme.fontUi }
            Label { text: String(root.genaiCallCount); color: Theme.text; font.family: Theme.fontMono }

            Label { text: "Last Response:"; color: Theme.textMuted; font.family: Theme.fontUi }
            Label { text: root.lastResponseSeconds.toFixed(2) + " s"; color: Theme.text; font.family: Theme.fontMono }

            Label { text: "Avg Response:"; color: Theme.textMuted; font.family: Theme.fontUi }
            Label { text: root.avgResponseTime.toFixed(2) + " s"; color: Theme.text; font.family: Theme.fontMono }

            Label { text: "Errors:"; color: Theme.textMuted; font.family: Theme.fontUi }
            Label { text: String(root.errorCount); color: root.errorCount > 0 ? Theme.danger : Theme.text; font.family: Theme.fontMono }

            Label { text: "TAS steps:"; color: Theme.textMuted; font.family: Theme.fontUi }
            Label { text: String(root.tasActiveSteps); color: Theme.text; font.family: Theme.fontMono }

            Label { text: "Coherence:"; color: Theme.textMuted; font.family: Theme.fontUi }
            Label { text: Math.round(root.coherence * 100) + " %"; color: Theme.coherenceColor(root.coherence); font.family: Theme.fontMono }
        }

        Label {
            text: "Live meters (no extra chart dependency)"
            color: Theme.textFaint
            font.family: Theme.fontUi
            font.pixelSize: 11
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { label: "coherence", value: root.coherence, color: Theme.emerald },
                    { label: "busy", value: root.busy ? 1 : 0, color: Theme.violet },
                    { label: "errors", value: Math.min(1, root.errorCount / 5.0), color: Theme.danger },
                    { label: "sections", value: Math.min(1, root.sectionCount / 24.0), color: Theme.cyan }
                ]
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: modelData.label
                        color: Theme.textMuted
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 10
                        radius: Theme.radiusSm
                        color: Theme.meterTrack
                        Rectangle {
                            width: Math.max(2, parent.width * modelData.value)
                            height: parent.height
                            radius: Theme.radiusSm
                            color: modelData.color
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Label {
            text: root.busy ? "KickFlow in flight" : "idle"
            color: root.busy ? Theme.violet : Theme.textFaint
            font.family: Theme.fontMono
            font.pixelSize: 11
        }
    }
}
