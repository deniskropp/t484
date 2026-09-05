import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Item {
    id: root
    anchors.fill: parent

    property var protocol: null
    property bool dismissed: false
    readonly property bool isGated: protocol ? protocol.gated : false
    visible: isGated && !dismissed

    signal exportNexusRequested()

    onIsGatedChanged: {
        if (!isGated)
            dismissed = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgChrome
        opacity: 0.75
        MouseArea { anchors.fill: parent } // block background clicks
    }

    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 560)
        implicitHeight: modalCol.implicitHeight + 32
        radius: Theme.radius
        color: Theme.bgRaised
        border.color: Theme.danger
        border.width: 2

        ColumnLayout {
            id: modalCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.danger
                }

                Label {
                    text: "KickGuard \u00b7 Consent Gate Active"
                    font.family: Theme.fontUi
                    font.bold: true
                    font.pixelSize: 15
                    color: Theme.danger
                }

                Item { Layout.fillWidth: true }

                ToolButton {
                    text: "\u2715"
                    onClicked: root.dismissed = true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            Label {
                text: "Halt Reason"
                font.family: Theme.fontUi
                font.bold: true
                font.pixelSize: 12
                color: Theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: reasonText.implicitHeight + 16
                radius: Theme.radiusSm
                color: Theme.gateFill
                border.color: Theme.danger
                border.width: Theme.borderWidth

                Label {
                    id: reasonText
                    anchors.fill: parent
                    anchors.margins: 8
                    text: (root.protocol && root.protocol.haltReason.length)
                          ? root.protocol.haltReason
                          : "Gated without specific reason"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.danger
                    wrapMode: Text.Wrap
                }
            }

            Label {
                Layout.fillWidth: true
                text: "While gated, KickGuard blocks mutation and GenAI transport. Local commands (/mode, /halt) and Nexus snapshot export remain open. Resuming un-gates by loading the living protocol document without cmd/halt."
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Theme.text
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Export Snapshot"
                    onClicked: root.exportNexusRequested()
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Dismiss (Stay Gated)"
                    onClicked: root.dismissed = true
                }

                Button {
                    text: "Resume / Remove Gate"
                    highlighted: true
                    onClicked: {
                        if (root.protocol) {
                            root.protocol.resumeFromHalt()
                            root.dismissed = false
                        }
                    }
                }
            }
        }
    }
}
