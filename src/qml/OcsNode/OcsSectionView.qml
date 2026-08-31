import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string sectionType: "data/tas"
    property string qualifier: ""
    property string sectionBody: ""
    property bool collapsed: false

    color: "#161b22"
    border.color: "#30363d"
    border.width: 1
    radius: 8
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
                color: "#7ee787"
                font.family: "monospace"
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: root.collapsed ? "\u25b6" : "\u25bc"
                color: "#8b949e"
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
                color: "#c9d1d9"
                font.family: "monospace"
                font.pixelSize: 13
                wrapMode: Text.Wrap
                readOnly: true
                background: null
                selectByMouse: true
            }
        }
    }
}
