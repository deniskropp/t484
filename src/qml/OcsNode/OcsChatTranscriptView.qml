import QtQuick
import QtQuick.Controls
import OcsNode 1.0

ListView {
    id: root

    property var protocol: null
    property bool autoScroll: true
    property int fontPointSize: 13
    property string themeName: "Dark"

    clip: true
    spacing: 10
    boundsBehavior: Flickable.StopAtBounds
    model: protocol ? protocol.sections : null

    onThemeNameChanged: Theme.apply(themeName)

    Rectangle {
        anchors.fill: parent
        z: -1
        color: Theme.bg
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
