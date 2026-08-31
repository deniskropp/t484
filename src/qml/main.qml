import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 860
    title: qsTr("OCS/Node Engine — t484")
    color: "#0d1117"

    header: ProtocolStatusBar {
        id: statusBar
        height: 40
        mode: engine.mode
        status: engine.status
        coherence: engine.coherence
        gated: engine.gated
        actor: engine.actor
        sectionCount: engine.sections.count
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        TasStatusBarView {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            model: tasModel
            onHaltRequested: function (reason) { engine.requestHalt(reason) }
        }

        KlmxMoleculeSpaceView {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            model: klmxItem
            coherence: engine.coherence
            mode: engine.mode
            onAccepted: function (payload) { engine.submitMap(payload) }
        }

        Label {
            text: "protocol/ocs:  [" + engine.sections.count + " sections, errors=" + engine.errorCount + "]"
            color: "#58a6ff"
            font.family: "monospace"
            font.pixelSize: 14
            font.bold: true
        }

        ListView {
            id: sectionList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: engine.sections
            delegate: OcsSectionView {
                width: sectionList.width
                height: 120
                sectionType: model.type
                qualifier: model.qualifier
                sectionBody: model.body
            }
        }
    }

    Binding { target: tasModel; property: "status"; value: engine.status }
    Binding { target: tasModel; property: "mode"; value: engine.mode }
    Binding { target: tasModel; property: "coherence"; value: engine.coherence }
    Binding { target: tasModel; property: "activeSteps"; value: engine.activeSteps }
    Binding { target: tasModel; property: "currentTasId"; value: engine.currentTasId }
    Binding { target: tasModel; property: "gated"; value: engine.gated }
    Binding { target: klmxItem; property: "coherence"; value: engine.coherence }
    Binding { target: klmxItem; property: "mode"; value: engine.mode }
}
