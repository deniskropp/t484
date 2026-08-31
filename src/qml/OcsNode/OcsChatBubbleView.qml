import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string family: "flow"
    property string sectionType: "flow/chat"
    property string qualifier: ""
    property string sectionBody: ""
    property int fontPointSize: 13
    property string themeName: "Dark"

    readonly property bool light: themeName === "Light"
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
        case "flow": return isHost ? (light ? "#0969da" : "#58a6ff") : (light ? "#8250df" : "#d2a8ff")
        case "display": return light ? "#1a7f37" : "#7ee787"
        case "query": return light ? "#9a6700" : "#d29922"
        case "cmd": return light ? "#cf222e" : "#f78166"
        case "data": return light ? "#0550ae" : "#79c0ff"
        case "context": return light ? "#0a7d83" : "#39d0d6"
        case "protocol": return light ? "#656d76" : "#8b949e"
        default: return light ? "#656d76" : "#8b949e"
        }
    }
    readonly property color bodyColor: light ? "#1f2328" : "#c9d1d9"
    readonly property color bubbleFill: {
        if (light)
            return isHost ? "#ffffff" : "#eef2f6"
        return isHost ? "#161b22" : "#12161c"
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
            color: root.bubbleFill
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
                    font.pixelSize: Math.max(10, root.fontPointSize - 2)
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    visible: root.sectionBody.length > 0
                    text: root.sectionBody
                    color: root.bodyColor
                    font.family: "monospace"
                    font.pixelSize: root.fontPointSize
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
