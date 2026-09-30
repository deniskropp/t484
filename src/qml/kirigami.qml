import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import OcsNode 1.0

// Third shell: Kirigami chassis over the same ProtocolEngineQt + OcsNode views.
// Do not invent protocol families. Transcript remains engine.sections.
Kirigami.ApplicationWindow {
    id: appWindow
    visible: true
    width: 1280
    height: 860
    readonly property var protocol: engine
    title: protocol && protocol.genaiReady
           ? qsTr("OCS/Node — Kirigami · ") + protocol.genaiSource
           : qsTr("OCS/Node — Kirigami · NO GENAI KEY")

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar

    globalDrawer: Kirigami.GlobalDrawer {
        title: qsTr("OCS/Display")
        subtitle: appWindow.protocol
                  ? (appWindow.protocol.mode + " · " + appWindow.protocol.status
                     + (appWindow.protocol.gated ? " · GATED" : ""))
                  : ""
        actions: [
            Kirigami.Action {
                text: qsTr("Chat")
                onTriggered: appWindow.pageStack.replace(chatPage)
            },
            Kirigami.Action {
                text: qsTr("TAS board")
                onTriggered: appWindow.pageStack.replace(tasPage)
            },
            Kirigami.Action {
                text: qsTr("KickLang editor")
                onTriggered: appWindow.pageStack.replace(editorPage)
            },
            Kirigami.Action {
                text: qsTr("Metrics")
                onTriggered: appWindow.pageStack.replace(metricsPage)
            },
            Kirigami.Action {
                text: qsTr("Molecule")
                onTriggered: appWindow.pageStack.replace(moleculePage)
            },
            Kirigami.Action { separator: true },
            Kirigami.Action {
                text: qsTr("Mode Hybrid")
                onTriggered: if (appWindow.protocol) appWindow.protocol.setMode("Hybrid")
            },
            Kirigami.Action {
                text: qsTr("Mode Fluid")
                onTriggered: if (appWindow.protocol) appWindow.protocol.setMode("Fluid")
            },
            Kirigami.Action {
                text: qsTr("Halt")
                onTriggered: if (appWindow.protocol) appWindow.protocol.requestHalt("kirigami")
            },
            Kirigami.Action {
                text: qsTr("Export Nexus")
                onTriggered: exportDialog.open()
            },
            Kirigami.Action {
                text: qsTr("Import Nexus")
                onTriggered: importDialog.open()
            }
        ]
    }

    contextDrawer: Kirigami.ContextDrawer { id: contextDrawer }

    pageStack.initialPage: chatPage

    Component {
        id: chatPage
        Kirigami.Page {
            title: qsTr("Chat")
            actions: [
                Kirigami.Action {
                    text: qsTr("Halt")
                    onTriggered: if (appWindow.protocol) appWindow.protocol.requestHalt("kirigami")
                }
            ]
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                ProtocolStatusBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
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
                TasStatusBarView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    model: tasModel
                    onHaltRequested: function (reason) { appWindow.protocol.requestHalt(reason) }
                }
                OcsChatTranscriptView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    protocol: appWindow.protocol
                }
                OcsComposerView {
                    Layout.fillWidth: true
                    protocol: appWindow.protocol
                    inspectorVisible: false
                }
            }
        }
    }

    Component {
        id: tasPage
        Kirigami.Page {
            title: qsTr("TAS")
            TasBoardView {
                anchors.fill: parent
                protocol: appWindow.protocol
                model: tasModel
            }
        }
    }

    Component {
        id: editorPage
        Kirigami.Page {
            title: qsTr("KickLang")
            KickLangEditorView {
                anchors.fill: parent
                protocol: appWindow.protocol
                onExportNexusRequested: exportDialog.open()
                onImportNexusRequested: importDialog.open()
            }
        }
    }

    Component {
        id: metricsPage
        Kirigami.Page {
            title: qsTr("Metrics")
            OcsMetricsPanelView {
                anchors.fill: parent
                protocol: appWindow.protocol
            }
        }
    }

    Component {
        id: moleculePage
        Kirigami.Page {
            title: qsTr("KLMx")
            KlmxMoleculeSpaceView {
                anchors.fill: parent
                model: klmxItem
                coherence: appWindow.protocol.coherence
                mode: appWindow.protocol.mode
                onAccepted: function (payload) { appWindow.protocol.submitMap(payload) }
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

    FileDialog {
        id: exportDialog
        title: qsTr("Export Nexus")
        fileMode: FileDialog.SaveFile
        nameFilters: ["OCS protocol (*.ocs)", "All files (*)"]
        defaultSuffix: "ocs"
        onAccepted: {
            if (appWindow.protocol)
                appWindow.protocol.saveNexusToFile(selectedFile)
        }
    }

    FileDialog {
        id: importDialog
        title: qsTr("Import Nexus")
        fileMode: FileDialog.OpenFile
        nameFilters: ["OCS protocol (*.ocs)", "All files (*)"]
        onAccepted: {
            if (appWindow.protocol)
                appWindow.protocol.loadNexusFromFile(selectedFile)
        }
    }

    ConsentGateDialog {
        id: consentGate
        protocol: appWindow.protocol
        onExportNexusRequested: exportDialog.open()
    }
}
