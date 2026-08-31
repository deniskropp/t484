import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root

    property string mode: "Hybrid"
    property string status: "idle"
    property real coherence: 0.5
    property bool gated: false
    property string actor: "KickFlow"
    property int sectionCount: 0
    property bool busy: false
    property bool genaiReady: false
    property string genaiModel: ""
    property string genaiSource: ""

    color: Theme.bgChrome
    border.color: Theme.borderSubtle
    border.width: Theme.borderWidth

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Label {
            text: "OCS/Node"
            color: Theme.cyan
            font.family: Theme.fontUi
            font.pixelSize: 13
            font.bold: true
        }
        Label {
            text: "t484"
            color: Theme.textMuted
            font.family: Theme.fontMono
            font.pixelSize: 12
        }
        Label {
            text: root.actor
            color: Theme.roleAccent(root.actor, "flow", false)
            font.family: Theme.fontMono
            font.pixelSize: 12
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            radius: Theme.radiusPill
            color: Theme.violetDeep
            implicitWidth: modeLabel.implicitWidth + 18
            implicitHeight: 22
            Label {
                id: modeLabel
                anchors.centerIn: parent
                text: root.mode
                color: "#ffffff"
                font.family: Theme.fontUi
                font.pixelSize: 11
                font.bold: true
            }
        }

        Item {
            implicitWidth: 72
            implicitHeight: 22
            Rectangle {
                anchors.fill: parent
                radius: 11
                color: "transparent"
                border.color: Theme.coherenceColor(root.coherence)
                border.width: 2
            }
            Label {
                anchors.centerIn: parent
                text: root.coherence.toFixed(2)
                color: Theme.coherenceColor(root.coherence)
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }

        Rectangle {
            radius: Theme.radiusPill
            color: "transparent"
            border.color: root.gated ? Theme.danger : Theme.cyan
            border.width: 1
            implicitWidth: statusLabel.implicitWidth + 18
            implicitHeight: 22
            Label {
                id: statusLabel
                anchors.centerIn: parent
                text: root.gated ? "GATED" : root.status.toUpperCase()
                color: root.gated ? Theme.danger : Theme.cyan
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
            }
        }

        Label {
            text: root.busy ? (root.genaiModel + " …")
                  : (root.genaiReady ? root.genaiModel
                     : "no key in this process")
            color: root.busy ? Theme.violet : (root.genaiReady ? Theme.textMuted : Theme.warning)
            font.family: Theme.fontMono
            font.pixelSize: 12
        }
        Label {
            text: root.sectionCount + " sec"
            color: Theme.textMuted
            font.family: Theme.fontMono
            font.pixelSize: 12
        }
    }
}
