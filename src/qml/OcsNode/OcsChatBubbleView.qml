import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Item {
    id: root

    property string family: "flow"
    property string sectionType: "flow/chat"
    property string qualifier: ""
    property string sectionBody: ""
    property int fontPointSize: 13
    property string themeName: "Dark"

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
    readonly property color accent: Theme.roleAccent(qualifier, family, isHost)
    readonly property color bodyColor: Theme.text
    readonly property color bubbleFill: Theme.roleFill(qualifier, family, isHost)

    width: parent ? parent.width : 640
    implicitHeight: row.implicitHeight

    onThemeNameChanged: Theme.apply(themeName)

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
            border.width: Theme.glowWidth
            radius: Theme.radius

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
                    font.family: Theme.fontMono
                    font.pixelSize: Math.max(10, root.fontPointSize - 2)
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    visible: root.sectionBody.length > 0
                    text: root.sectionBody
                    color: root.bodyColor
                    font.family: Theme.fontMono
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
