import QtQuick
import QtQuick.Controls

ListView {
    id: root

    property var protocol: null
    property bool autoScroll: true
    property int fontPointSize: 13
    property string themeName: "Dark"

    readonly property bool light: themeName === "Light"

    clip: true
    spacing: 10
    boundsBehavior: Flickable.StopAtBounds
    model: protocol ? protocol.sections : null

    Rectangle {
        anchors.fill: parent
        z: -1
        color: root.light ? "#f6f8fa" : "#0d1117"
    }

    delegate: OcsChatBubbleView {
        width: root.width
        height: implicitHeight
        family: model.family
        sectionType: model.type
        qualifier: model.qualifier
        sectionBody: model.body
        fontPointSize: root.fontPointSize
        themeName: root.themeName
    }

    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    onCountChanged: Qt.callLater(function () {
        if (root.autoScroll && count > 0)
            positionViewAtEnd()
    })
}
