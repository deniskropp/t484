import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

// Plate over frozen display/* families only. No display/generative_widget.
Rectangle {
    id: root
    color: Theme.bg

    property var protocol: null
    property string headerText: ""
    property string contentText: ""
    property string metaText: ""

    readonly property bool hasDisplay: headerText.length > 0
                                       || contentText.length > 0
                                       || metaText.length > 0

    function refresh() {
        if (!protocol) {
            headerText = ""
            contentText = ""
            metaText = ""
            return
        }
        headerText = protocol.sectionBody("display/header")
        contentText = protocol.sectionBody("display/content")
        metaText = protocol.sectionBody("display/meta")
    }

    Connections {
        target: protocol ? protocol.sections : null
        function onCountChanged() { root.refresh() }
    }

    Connections {
        target: protocol
        function onStateChanged() { root.refresh() }
        function onSourceChanged() { root.refresh() }
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: Theme.bgRaised
            border.color: Theme.border
            border.width: Theme.borderWidth
            radius: Theme.radiusSm

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Label {
                    text: "Display"
                    font.family: Theme.fontUi
                    font.bold: true
                    font.pixelSize: 13
                    color: Theme.text
                }

                Label {
                    text: "display/header · display/content · display/meta"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Button {
                    text: "Refresh"
                    onClicked: root.refresh()
                }
            }
        }

        Label {
            visible: headerText.length > 0
            text: headerText
            wrapMode: Text.Wrap
            font.family: Theme.fontUi
            font.pixelSize: 14
            font.bold: true
            color: Theme.cyan
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgRaised
            border.color: Theme.borderSubtle
            border.width: Theme.borderWidth
            radius: Theme.radiusSm

            Label {
                visible: !root.hasDisplay
                anchors.centerIn: parent
                text: "No display/* sections in the living document"
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Theme.textFaint
            }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                visible: contentText.length > 0
                clip: true

                TextArea {
                    text: root.contentText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    color: Theme.text
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    background: null
                }
            }
        }

        Label {
            visible: metaText.length > 0
            text: metaText
            wrapMode: Text.Wrap
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: Theme.textFaint
            Layout.fillWidth: true
        }
    }
}
