import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

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

    color: gated ? Theme.gateFill : Theme.bgRaised
    border.color: Theme.coherenceColor(coherence)
    border.width: Theme.borderWidth
    radius: Theme.radiusSm
    implicitHeight: 48

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 12
        Rectangle {
            width: 10; height: 10; radius: 5
            color: Theme.statusColor(root.status)
        }
        Label {
            text: "TAS"
            font.family: Theme.fontUi
            font.bold: true
            font.pixelSize: 12
            color: Theme.text
        }
        Label {
            text: root.currentTasId.length ? root.currentTasId : "\u2014"
            font.family: Theme.fontMono
            font.pixelSize: 11
            color: Theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Rectangle {
            radius: Theme.radiusSm
            color: Theme.bgPanel
            implicitWidth: modeLabel.implicitWidth + 10
            implicitHeight: 20
            Label {
                id: modeLabel
                anchors.centerIn: parent
                text: root.mode
                font.family: Theme.fontUi
                font.pixelSize: 10
                color: Theme.cyan
            }
        }
        ProgressBar {
            from: 0
            to: 1
            value: root.coherence
            implicitWidth: 80
            implicitHeight: 8
        }
        Label {
            text: Math.round(root.coherence * 100) + "%"
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: Theme.textMuted
        }
        Label {
            text: root.activeSteps + " steps"
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: Theme.textFaint
        }
        ToolButton {
            visible: root.gated
            text: "HALT"
            font.pixelSize: 10
            onClicked: root.haltRequested("user-gate-from-status-bar")
        }
    }
}
