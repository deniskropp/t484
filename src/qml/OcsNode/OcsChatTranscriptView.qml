import QtQuick
import QtQuick.Controls

ListView {
    id: root

    property var protocol: null
    clip: true
    spacing: 10
    boundsBehavior: Flickable.StopAtBounds
    model: protocol ? protocol.sections : null

    delegate: OcsChatBubbleView {
        width: root.width
        height: implicitHeight
        family: model.family
        sectionType: model.type
        qualifier: model.qualifier
        sectionBody: model.body
    }

    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    onCountChanged: Qt.callLater(function () {
        if (count > 0)
            positionViewAtEnd()
    })
}
