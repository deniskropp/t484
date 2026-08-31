import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root
    color: Theme.bg

    property var protocol: null
    property var logModel: eventLogModel
    property string filter: "all"

    function matches(level) {
        if (root.filter === "all")
            return true
        return level === root.filter
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Label {
            text: "Event log"
            color: Theme.text
            font.family: Theme.fontUi
            font.bold: true
            font.pixelSize: 14
        }

        RowLayout {
            spacing: 6
            Repeater {
                model: ["all", "info", "warning", "error", "genai", "protocol"]
                Button {
                    text: modelData
                    highlighted: root.filter === modelData
                    onClicked: root.filter = modelData
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Clear"
                onClicked: {
                    if (root.logModel)
                        root.logModel.clear()
                }
            }
        }

        ListView {
            id: logsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.logModel
            delegate: Rectangle {
                visible: root.matches(level)
                width: logsList.width
                height: visible ? 28 : 0
                color: index % 2 === 0 ? Theme.stripeEven : Theme.stripeOdd
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10
                    Label {
                        text: time
                        color: Theme.textMuted
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        Layout.preferredWidth: 72
                    }
                    Label {
                        text: level
                        color: Theme.levelColor(level)
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        Layout.preferredWidth: 78
                    }
                    Label {
                        text: event
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        Layout.preferredWidth: 120
                    }
                    Label {
                        text: details
                        color: Theme.textMuted
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
