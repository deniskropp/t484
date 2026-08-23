import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string sectionType: "data/tas"
    property string sectionBody: ""

    color: "#161b22"
    border.color: "#30363d"
    border.width: 1
    radius: 8

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Label {
                text: "⫻" + root.sectionType
                color: "#7ee787"
                font.family: "monospace"
                font.pixelSize: 14
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "▼"
                color: "#8b949e"
                font.pixelSize: 12
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: body
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
