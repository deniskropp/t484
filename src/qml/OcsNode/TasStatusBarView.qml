import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var model: null
    readonly property string status: model ? model.status : "idle"
    readonly property string mode: model ? model.mode : "Hybrid"
    readonly property real coherence: model ? model.coherence : 0
    readonly property int activeSteps: model ? model.activeSteps : 0
    readonly property string currentTasId: model ? model.currentTasId : ""
    readonly property bool gated: model ? model.gated : false
    signal haltRequested(string reason)

    color: gated ? "#3a1f1f" : "#1a1f2e"
    border.color: coherence > 0.85 ? "#2ecc71" : (coherence > 0.6 ? "#f1c40f" : "#e74c3c")
    border.width: 1
    radius: 4
    implicitHeight: 48

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 12
        Rectangle {
            width: 10; height: 10; radius: 5
            color: {
                switch (root.status) {
                case "running": return "#2ecc71"
                case "gated": return "#e67e22"
                case "complete": return "#3498db"
                case "error": return "#e74c3c"
                default: return "#95a5a6"
                }
            }
        }
        Label { text: "TAS"; font.bold: true; font.pixelSize: 12; color: "#ecf0f1" }
        Label {
            text: root.currentTasId.length ? root.currentTasId : "—"
            font.pixelSize: 11; color: "#bdc3c7"; elide: Text.ElideRight; Layout.fillWidth: true
        }
        Rectangle {
            radius: 3; color: "#2c3e50"
            implicitWidth: modeLabel.implicitWidth + 10; implicitHeight: 20
            Label { id: modeLabel; anchors.centerIn: parent; text: root.mode; font.pixelSize: 10; color: "#ecf0f1" }
        }
        ProgressBar { from: 0; to: 1; value: root.coherence; implicitWidth: 80; implicitHeight: 8 }
        Label { text: Math.round(root.coherence * 100) + "%"; font.pixelSize: 10; color: "#bdc3c7" }
        Label { text: root.activeSteps + " steps"; font.pixelSize: 10; color: "#95a5a6" }
        ToolButton {
            visible: root.gated; text: "HALT"; font.pixelSize: 10
            onClicked: root.haltRequested("user-gate-from-status-bar")
        }
    }
}
