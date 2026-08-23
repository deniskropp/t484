import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 800
    title: qsTr("OCS/Node Engine — t484")

    color: "#0d1117"

    header: ProtocolStatusBar {
        id: statusBar
        height: 40
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: "⫻protocol/ocs:"
            color: "#58a6ff"
            font.family: "monospace"
            font.pixelSize: 16
            font.bold: true
        }

        OcsSectionView {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            sectionType: "context/klmx"
            sectionBody: "Kick/Lang — OCS/Node Engine active\nProject: deniskropp/t484\nMode: Hybrid"
        }

        OcsSectionView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sectionType: "data/tas"
            sectionBody: "- register engine\n- create repository (done)\n- seed CMake + QML skeleton (in progress)\n- await next component"
        }
    }
}
