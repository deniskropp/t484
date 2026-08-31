import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#1a1a1a"

    property var protocol: null
    property string filter: "all"
    property int maxRows: 200

    ListModel { id: logModel }

    function matches(level) {
        if (root.filter === "all")
            return true
        return level === root.filter
    }

    function appendEvent(level, event, details) {
        const row = {
            time: Qt.formatTime(new Date(), "hh:mm:ss"),
            event: event || "",
            details: details || "",
            level: level || "info"
        }
        logModel.insert(0, row)
        while (logModel.count > root.maxRows)
            logModel.remove(logModel.count - 1)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Label {
            text: "Event log"
            color: "#c9d1d9"
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
                onClicked: logModel.clear()
            }
        }

        ListView {
            id: logsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: logModel
            delegate: Rectangle {
                visible: root.matches(level)
                width: logsList.width
                height: visible ? 28 : 0
                color: index % 2 === 0 ? "#161b22" : "#1a1a1a"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10
                    Label {
                        text: time
                        color: "#8b949e"
                        font.family: "monospace"
                        font.pixelSize: 11
                        Layout.preferredWidth: 72
                    }
                    Label {
                        text: level
                        color: level === "error" ? "#f85149"
                             : level === "warning" ? "#d29922"
                             : level === "genai" ? "#d2a8ff"
                             : level === "protocol" ? "#58a6ff"
                             : "#7ee787"
                        font.family: "monospace"
                        font.pixelSize: 11
                        font.bold: true
                        Layout.preferredWidth: 78
                    }
                    Label {
                        text: event
                        color: "#c9d1d9"
                        font.family: "monospace"
                        font.pixelSize: 11
                        Layout.preferredWidth: 120
                    }
                    Label {
                        text: details
                        color: "#8b949e"
                        font.family: "monospace"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
