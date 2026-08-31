import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string mode: "Hybrid"
    property string status: "idle"
    property real coherence: 0.5
    property bool gated: false
    property string actor: "KickFlow"
    property int sectionCount: 0

    color: "#010409"
    border.color: "#21262d"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 20

        Label { text: "OCS/Node"; color: "#58a6ff"; font.family: "monospace"; font.pixelSize: 13; font.bold: true }
        Label { text: "t484"; color: "#8b949e"; font.family: "monospace"; font.pixelSize: 12 }
        Label { text: root.actor; color: "#d2a8ff"; font.family: "monospace"; font.pixelSize: 12 }
        Item { Layout.fillWidth: true }
        Label { text: "mode: " + root.mode; color: "#7ee787"; font.family: "monospace"; font.pixelSize: 12 }
        Label {
            text: "coherence: " + Math.round(root.coherence * 100) + "%"
            color: root.coherence > 0.85 ? "#7ee787" : (root.coherence > 0.6 ? "#d29922" : "#f85149")
            font.family: "monospace"; font.pixelSize: 12
        }
        Label {
            text: root.gated ? "GATED" : root.status.toUpperCase()
            color: root.gated ? "#f85149" : "#f78166"
            font.family: "monospace"; font.pixelSize: 12; font.bold: true
        }
        Label { text: root.sectionCount + " sec"; color: "#8b949e"; font.family: "monospace"; font.pixelSize: 12 }
    }
}
