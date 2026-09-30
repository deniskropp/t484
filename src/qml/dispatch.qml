import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import OcsNode 1.0

ApplicationWindow {
    id: appWindow
    visible: true
    width: 1280
    height: 860
    // Context property `engine` is ProtocolEngineQt. Child views must not
    // declare a property named `engine` and bind `engine: engine`.
    readonly property var protocol: engine
    title: protocol && protocol.genaiReady
           ? qsTr("t484 Protocol Dispatch \u00b7 ") + protocol.genaiSource
           : qsTr("t484 Protocol Dispatch \u00b7 NO GENAI KEY")
    color: Theme.bg
    palette.window: Theme.bg
    palette.windowText: Theme.text
    palette.base: Theme.bgRaised
    palette.text: Theme.text
    palette.button: Theme.bgPanel
    palette.buttonText: Theme.text
    palette.highlight: Theme.violetDeep
    palette.highlightedText: "#ffffff"

    header: ProtocolStatusBar {
        id: statusBar
        height: 40
        mode: appWindow.protocol ? appWindow.protocol.mode : "Hybrid"
        status: appWindow.protocol ? appWindow.protocol.status : "idle"
        coherence: appWindow.protocol ? appWindow.protocol.coherence : 0
        gated: appWindow.protocol ? appWindow.protocol.gated : false
        actor: appWindow.protocol ? appWindow.protocol.actor : "KickFlow"
        sectionCount: appWindow.protocol ? appWindow.protocol.sections.count : 0
        busy: appWindow.protocol ? appWindow.protocol.busy : false
        genaiReady: appWindow.protocol ? appWindow.protocol.genaiReady : false
        genaiModel: appWindow.protocol ? appWindow.protocol.genaiModel : ""
        genaiSource: appWindow.protocol ? appWindow.protocol.genaiSource : ""
    }

    ProtocolDispatchView {
        id: dispatchView
        anchors.fill: parent
        protocol: appWindow.protocol
        onExportNexusRequested: exportDialog.open()
        onImportNexusRequested: importDialog.open()
        onCopySnapshotRequested: appWindow.copyNexusSnapshot()
        onDispatched: function (sectionType, qualifier, ok) {
            if (eventLogModel)
                eventLogModel.appendEvent(ok ? "protocol" : "error",
                                          "dispatch",
                                          sectionType
                                          + (qualifier && qualifier.length ? (":" + qualifier) : "")
                                          + (ok ? " ok" : " rejected"))
        }
    }

    Binding { target: tasModel; property: "status"; value: appWindow.protocol ? appWindow.protocol.status : "idle" }
    Binding { target: tasModel; property: "mode"; value: appWindow.protocol ? appWindow.protocol.mode : "Hybrid" }
    Binding { target: tasModel; property: "coherence"; value: appWindow.protocol ? appWindow.protocol.coherence : 1 }
    Binding { target: tasModel; property: "activeSteps"; value: appWindow.protocol ? appWindow.protocol.activeSteps : 0 }
    Binding { target: tasModel; property: "currentTasId"; value: appWindow.protocol ? appWindow.protocol.currentTasId : "" }
    Binding { target: tasModel; property: "gated"; value: appWindow.protocol ? appWindow.protocol.gated : false }
    Binding { target: klmxItem; property: "coherence"; value: appWindow.protocol ? appWindow.protocol.coherence : 1 }
    Binding { target: klmxItem; property: "mode"; value: appWindow.protocol ? appWindow.protocol.mode : "Hybrid" }

    function nexusFileName() {
        const d = new Date()
        const pad = function (n) { return (n < 10 ? "0" : "") + n }
        return "nexus-" + d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + ".ocs"
    }

    function copyNexusSnapshot() {
        if (!appWindow.protocol)
            return false
        clipHelper.text = appWindow.protocol.exportNexus()
        clipHelper.selectAll()
        clipHelper.copy()
        if (eventLogModel)
            eventLogModel.appendEvent("info", "nexus-export", "copied snapshot")
        return true
    }

    function exportNexusTo(url) {
        if (!appWindow.protocol)
            return false
        const ok = appWindow.protocol.saveNexusToFile(url)
        if (eventLogModel)
            eventLogModel.appendEvent(ok ? "info" : "error", "nexus-export",
                                      ok ? String(url) : "save failed")
        return ok
    }

    function importNexusFrom(url) {
        if (!appWindow.protocol)
            return false
        const ok = appWindow.protocol.loadNexusFromFile(url)
        if (eventLogModel)
            eventLogModel.appendEvent(ok ? "info" : "error", "nexus-import",
                                      ok ? String(url) : "load failed")
        return ok
    }

    TextEdit {
        id: clipHelper
        visible: false
        width: 0
        height: 0
    }

    FileDialog {
        id: exportDialog
        title: "Export Nexus"
        fileMode: FileDialog.SaveFile
        nameFilters: ["OCS protocol (*.ocs)", "All files (*)"]
        defaultSuffix: "ocs"
        currentFile: "file:" + appWindow.nexusFileName()
        onAccepted: appWindow.exportNexusTo(selectedFile)
    }

    FileDialog {
        id: importDialog
        title: "Import Nexus"
        fileMode: FileDialog.OpenFile
        nameFilters: ["OCS protocol (*.ocs)", "All files (*)"]
        onAccepted: appWindow.importNexusFrom(selectedFile)
    }

    ConsentGateDialog {
        id: consentGate
        protocol: appWindow.protocol
        onExportNexusRequested: exportDialog.open()
    }
}
