import QtQuick
import QtQuick.Controls
import OcsNode 1.0

// Protocol document beside the display frame. Same ProtocolEngine, no new family.
SplitView {
    id: root
    orientation: Qt.Horizontal

    property var protocol: null

    ProtocolRichTextView {
        SplitView.fillWidth: true
        SplitView.minimumWidth: 320
        protocol: root.protocol
    }

    GenerativeWidgetView {
        SplitView.preferredWidth: 480
        SplitView.minimumWidth: 280
        protocol: root.protocol
    }
}
