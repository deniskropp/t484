import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

ApplicationWindow {
    id: appWindow
    visible: true
    width: 1280
    height: 860
    // Context property `engine` is ProtocolEngineQt. Child views must not
    // declare a property named `engine` and bind `engine: engine` — that is a
    // self-binding to null, which made Send a no-op while the title still worked.
    readonly property var protocol: engine
    title: protocol && protocol.genaiReady
           ? qsTr("OCS/Node Chat — t484 · ") + protocol.genaiSource
           : qsTr("OCS/Node Chat — t484 · NO GENAI KEY")
    color: "#0d1117"

    property bool inspectorVisible: true

    header: ProtocolStatusBar {
        id: statusBar
        height: 40
        mode: appWindow.protocol.mode
        status: appWindow.protocol.status
        coherence: appWindow.protocol.coherence
        gated: appWindow.protocol.gated
        actor: appWindow.protocol.actor
        sectionCount: appWindow.protocol.sections.count
        busy: appWindow.protocol.busy
        genaiReady: appWindow.protocol.genaiReady
        genaiModel: appWindow.protocol.genaiModel
        genaiSource: appWindow.protocol.genaiSource
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        TasStatusBarView {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            model: tasModel
            onHaltRequested: function (reason) { appWindow.protocol.requestHalt(reason) }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            ColumnLayout {
                SplitView.fillWidth: true
                SplitView.minimumWidth: 420
                spacing: 8

                OcsChatTranscriptView {
                    id: transcript
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    protocol: appWindow.protocol
                }

                OcsComposerView {
                    Layout.fillWidth: true
                    protocol: appWindow.protocol
                    inspectorVisible: appWindow.inspectorVisible
                    onInspectorToggled: appWindow.inspectorVisible = !appWindow.inspectorVisible
                }
            }

            ColumnLayout {
                visible: appWindow.inspectorVisible
                SplitView.preferredWidth: 400
                SplitView.minimumWidth: 280
                spacing: 8

                KlmxMoleculeSpaceView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    model: klmxItem
                    coherence: appWindow.protocol.coherence
                    mode: appWindow.protocol.mode
                    onAccepted: function (payload) { appWindow.protocol.submitMap(payload) }
                }

                Label {
                    text: "protocol/ocs  [" + appWindow.protocol.sections.count + " sections, errors=" + appWindow.protocol.errorCount + "]"
                    color: "#58a6ff"
                    font.family: "monospace"
                    font.pixelSize: 12
                    font.bold: true
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    TextArea {
                        text: appWindow.protocol.sourceText
                        readOnly: true
                        color: "#8b949e"
                        font.family: "monospace"
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        selectByMouse: true
                        background: Rectangle {
                            color: "#161b22"
                            border.color: "#30363d"
                            border.width: 1
                            radius: 6
                        }
                    }
                }
            }
        }
    }

    Binding { target: tasModel; property: "status"; value: appWindow.protocol.status }
    Binding { target: tasModel; property: "mode"; value: appWindow.protocol.mode }
    Binding { target: tasModel; property: "coherence"; value: appWindow.protocol.coherence }
    Binding { target: tasModel; property: "activeSteps"; value: appWindow.protocol.activeSteps }
    Binding { target: tasModel; property: "currentTasId"; value: appWindow.protocol.currentTasId }
    Binding { target: tasModel; property: "gated"; value: appWindow.protocol.gated }
    Binding { target: klmxItem; property: "coherence"; value: appWindow.protocol.coherence }
    Binding { target: klmxItem; property: "mode"; value: appWindow.protocol.mode }
}
