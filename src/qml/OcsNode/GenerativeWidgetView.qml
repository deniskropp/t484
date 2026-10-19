import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

// Display frame over frozen display/* only.
// display/content and display/body are the same card role. A frame that
// carries both is a gate: show them apart, never concatenate.
Rectangle {
    id: root
    color: Theme.bg

    property var protocol: null
    property string headerText: ""
    property string contentText: ""
    property string bodyText: ""
    property string footerText: ""
    property string metaText: ""

    readonly property bool frameConflict: contentText.length > 0 && bodyText.length > 0
    readonly property string workText: frameConflict
                                        ? ""
                                        : (contentText.length > 0 ? contentText : bodyText)
    readonly property string workToken: frameConflict
                                        ? ""
                                        : (contentText.length > 0
                                           ? "display/content"
                                           : (bodyText.length > 0 ? "display/body" : ""))
    readonly property bool hasDisplay: headerText.length > 0
                                       || contentText.length > 0
                                       || bodyText.length > 0
                                       || footerText.length > 0
                                       || metaText.length > 0

    function refresh() {
        if (!protocol) {
            headerText = ""
            contentText = ""
            bodyText = ""
            footerText = ""
            metaText = ""
            return
        }
        headerText = protocol.sectionBody("display/header")
        contentText = protocol.sectionBody("display/content")
        bodyText = protocol.sectionBody("display/body")
        footerText = protocol.sectionBody("display/footer")
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

    component Band: Rectangle {
        property alias text: bandLabel.text
        property color ink: Theme.text
        Layout.fillWidth: true
        implicitHeight: bandLabel.implicitHeight + 16
        color: Theme.bgRaised
        border.color: Theme.border
        border.width: Theme.borderWidth
        radius: Theme.radiusSm
        Label {
            id: bandLabel
            anchors.fill: parent
            anchors.margins: 8
            wrapMode: Text.Wrap
            font.family: Theme.fontUi
            font.pixelSize: 13
            color: parent.ink
        }
    }

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
                    text: "header · content|body · footer · meta"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Label {
            visible: root.frameConflict
            text: "Frame gate: display/body and display/content are both present. They are not combined."
            wrapMode: Text.Wrap
            font.family: Theme.fontUi
            font.pixelSize: 12
            color: Theme.danger
            Layout.fillWidth: true
        }

        Band {
            visible: root.headerText.length > 0
            text: root.headerText
            ink: Theme.cyan
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgRaised
            border.color: root.frameConflict ? Theme.danger : Theme.borderSubtle
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

            Label {
                visible: root.hasDisplay && !root.frameConflict && root.workText.length === 0
                anchors.centerIn: parent
                text: "No display/content or display/body"
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Theme.textFaint
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                visible: root.frameConflict || root.workText.length > 0

                Label {
                    visible: root.workToken.length > 0
                    text: root.workToken
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.emerald
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.workText.length > 0
                    clip: true
                    TextArea {
                        text: root.workText
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        background: null
                        selectByMouse: true
                    }
                }

                Label {
                    visible: root.frameConflict
                    text: "display/content"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.emerald
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.frameConflict
                    clip: true
                    TextArea {
                        text: root.contentText
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        background: null
                        selectByMouse: true
                    }
                }

                Label {
                    visible: root.frameConflict
                    text: "display/body"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.emerald
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.frameConflict
                    clip: true
                    TextArea {
                        text: root.bodyText
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        background: null
                        selectByMouse: true
                    }
                }
            }
        }

        Band {
            visible: root.footerText.length > 0
            text: root.footerText
            ink: Theme.textMuted
        }

        Label {
            visible: root.metaText.length > 0
            text: root.metaText
            wrapMode: Text.Wrap
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: Theme.textFaint
            Layout.fillWidth: true
        }
    }
}
