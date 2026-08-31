import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root

    property string sectionType: "data/tas"
    property string qualifier: ""
    property string sectionBody: ""
    property bool collapsed: false

    color: Theme.bgRaised
    border.color: Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius
    implicitHeight: collapsed ? headerRow.implicitHeight + 24 : 160

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            id: headerRow
            Layout.fillWidth: true

            Label {
                text: "\u2afb" + root.sectionType + (root.qualifier.length ? (":" + root.qualifier) : "")
                color: Theme.emerald
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: root.collapsed ? "\u25b6" : "\u25bc"
                color: Theme.textMuted
                font.pixelSize: 12
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.collapsed = !root.collapsed
                }
            }
        }

        ScrollView {
            visible: !root.collapsed
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            TextArea {
                text: root.sectionBody
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 13
                wrapMode: Text.Wrap
                readOnly: true
                background: null
                selectByMouse: true
            }
        }
    }
}
