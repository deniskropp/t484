import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#202020"

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
            font.bold: true
            font.pointSize: 14
            color: "white"
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: 12
            rowSpacing: 6

            Label { text: "Active Sections:"; color: "#8b949e" }
            Label { text: String(root.sectionCount); color: "white"; font.family: "monospace" }

            Label { text: "GenAI Calls:"; color: "#8b949e" }
            Label { text: String(root.genaiCallCount); color: "white"; font.family: "monospace" }

            Label { text: "Last Response:"; color: "#8b949e" }
            Label { text: root.lastResponseSeconds.toFixed(2) + " s"; color: "white"; font.family: "monospace" }

            Label { text: "Avg Response:"; color: "#8b949e" }
            Label { text: root.avgResponseTime.toFixed(2) + " s"; color: "white"; font.family: "monospace" }

            Label { text: "Errors:"; color: "#8b949e" }
            Label { text: String(root.errorCount); color: root.errorCount > 0 ? "#f85149" : "white"; font.family: "monospace" }

            Label { text: "TAS steps:"; color: "#8b949e" }
            Label { text: String(root.tasActiveSteps); color: "white"; font.family: "monospace" }

            Label { text: "Coherence:"; color: "#8b949e" }
            Label { text: Math.round(root.coherence * 100) + " %"; color: "white"; font.family: "monospace" }
        }

        Label {
            text: "Live meters (no extra chart dependency)"
            color: "#6e7681"
            font.pixelSize: 11
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { label: "coherence", value: root.coherence, color: "#7ee787" },
                    { label: "busy", value: root.busy ? 1 : 0, color: "#d2a8ff" },
                    { label: "errors", value: Math.min(1, root.errorCount / 5.0), color: "#f85149" },
                    { label: "sections", value: Math.min(1, root.sectionCount / 24.0), color: "#58a6ff" }
                ]
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: modelData.label
                        color: "#8b949e"
                        font.family: "monospace"
                        font.pixelSize: 11
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 10
                        radius: 4
                        color: "#333333"
                        Rectangle {
                            width: Math.max(2, parent.width * modelData.value)
                            height: parent.height
                            radius: 4
                            color: modelData.color
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Label {
            text: root.busy ? "KickFlow in flight" : "idle"
            color: root.busy ? "#d2a8ff" : "#6e7681"
            font.family: "monospace"
            font.pixelSize: 11
        }
    }
}
