import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#010409"
    border.color: "#21262d"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 24

        Label {
            text: "OCS/Node"
            color: "#58a6ff"
            font.family: "monospace"
            font.pixelSize: 13
            font.bold: true
        }

        Label {
            text: "t484"
            color: "#8b949e"
            font.family: "monospace"
            font.pixelSize: 12
        }

        Item { Layout.fillWidth: true }

        Label {
            text: "mode: Hybrid"
            color: "#7ee787"
            font.family: "monospace"
            font.pixelSize: 12
        }

        Label {
            text: "coherence: STABLE"
            color: "#7ee787"
            font.family: "monospace"
            font.pixelSize: 12
        }

        Label {
            text: "engine: ACTIVE"
            color: "#f78166"
            font.family: "monospace"
            font.pixelSize: 12
            font.bold: true
        }
    }
}
