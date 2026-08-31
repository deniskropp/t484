import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string family: "flow"
    property string sectionType: "flow/chat"
    property string qualifier: ""
    property string sectionBody: ""

    readonly property bool isHost: family === "flow"
                                   && (qualifier === "host" || qualifier === "user")
    readonly property string speaker: {
        if (qualifier.length)
            return qualifier
        if (family === "query")
            return "KickForge"
        if (family === "cmd")
            return "cmd"
        return family
    }
    readonly property color accent: {
        switch (family) {
        case "flow": return isHost ? "#58a6ff" : "#d2a8ff"
        case "display": return "#7ee787"
        case "query": return "#d29922"
        case "cmd": return "#f78166"
        case "data": return "#79c0ff"
        case "context": return "#39d0d6"
        case "protocol": return "#8b949e"
        default: return "#8b949e"
        }
    }

    width: parent ? parent.width : 640
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        Item {
            visible: root.isHost
            Layout.fillWidth: true
            Layout.minimumWidth: 48
        }

        Rectangle {
            id: bubble
            Layout.maximumWidth: row.width * 0.78
            Layout.preferredWidth: Math.min(row.width * 0.78, col.implicitWidth + 24)
            Layout.fillWidth: !root.isHost
            implicitHeight: col.implicitHeight + 20
            color: root.isHost ? "#161b22" : "#12161c"
            border.color: root.accent
            border.width: 1
            radius: 10

            ColumnLayout {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 4

                Label {
                    text: "\u2afb" + root.sectionType + (root.qualifier.length ? (":" + root.qualifier) : "")
                    color: root.accent
                    font.family: "monospace"
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    visible: root.sectionBody.length > 0
                    text: root.sectionBody
                    color: "#c9d1d9"
                    font.family: "monospace"
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        Item {
            visible: !root.isHost
            Layout.fillWidth: true
            Layout.minimumWidth: 48
        }
    }
}
