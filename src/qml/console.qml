import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import OcsNode 1.0

ApplicationWindow {
    id: appWindow
    width: 1600
    height: 900
    visible: true
    color: Theme.bg
    palette.window: Theme.bg
    palette.windowText: Theme.text
    palette.base: Theme.bgRaised
    palette.text: Theme.text
    palette.button: Theme.bgPanel
    palette.buttonText: Theme.text
    palette.highlight: Theme.violetDeep
    palette.highlightedText: "#ffffff"
    readonly property var protocol: engine
    title: "t484 Protocol Console \u2014 Source: "
           + (protocol && protocol.genaiReady
              ? protocol.genaiSource
              : "NO KEY")

    property string viewMode: "chat"
    property bool inspectorVisible: true
    property bool tasStripVisible: true
    property bool moleculeVisible: true
    property bool autoScrollTranscript: true
    property bool showRawSections: false
    property int fontPointSize: 12
    property string themeName: "Dark"
    property string logFilter: "all"
    property int genaiCallCount: 0
    property real lastResponseSeconds: 0
    property real avgResponseTime: 0
    property int responseSamples: 0
    property real busyStartedAt: 0

    onThemeNameChanged: Theme.apply(themeName)
    Component.onCompleted: Theme.apply(themeName)

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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            implicitHeight: 44
            color: Theme.bgRaised
            border.color: Theme.borderSubtle
            border.width: Theme.borderWidth

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 16

                Label {
                    text: "Status: "
                          + (appWindow.protocol && appWindow.protocol.genaiReady ? "Ready" : "NO KEY")
                          + " | Gated: " + (appWindow.protocol ? appWindow.protocol.gated : false)
                          + " | Busy: " + (appWindow.protocol ? appWindow.protocol.busy : false)
                          + " | Errors: " + (appWindow.protocol ? appWindow.protocol.errorCount : 0)
                    color: Theme.text
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "view"
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
                ComboBox {
                    id: viewSelector
                    model: ["chat", "inspect", "dev"]
                    currentIndex: 0
                    implicitWidth: 120
                    onActivated: appWindow.viewMode = model[index]
                }

                Label {
                    text: "cmd/mode"
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
                ComboBox {
                    id: modeSelector
                    model: ["Hybrid", "Fluid", "Swarm", "Predictive"]
                    implicitWidth: 140
                    onActivated: {
                        if (appWindow.protocol)
                            appWindow.protocol.setMode(model[index])
                    }
                }

                Button {
                    text: "Export Nexus"
                    onClicked: exportDialog.open()
                }
                Button {
                    text: "Import Nexus"
                    onClicked: importDialog.open()
                }
                Button {
                    text: "Copy snapshot"
                    onClicked: appWindow.copyNexusSnapshot()
                }
            }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            Rectangle {
                SplitView.preferredWidth: appWindow.viewMode === "dev" ? 420 : 560
                SplitView.minimumWidth: 360
                SplitView.fillHeight: true
                color: Theme.bg

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ListView implicit height is 0; wrap so ColumnLayout
                    // actually assigns the leftover stretch to the transcript.
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 180
                        Layout.preferredHeight: 400

                        OcsChatTranscriptView {
                            id: transcript
                            anchors.fill: parent
                            anchors.margins: 8
                            protocol: appWindow.protocol
                            autoScroll: appWindow.autoScrollTranscript
                            fontPointSize: appWindow.fontPointSize
                            themeName: appWindow.themeName
                        }
                    }

                    OcsComposerView {
                        id: composer
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.maximumHeight: implicitHeight
                        protocol: appWindow.protocol
                        inspectorVisible: appWindow.inspectorVisible
                        onInspectorToggled: appWindow.inspectorVisible = !appWindow.inspectorVisible
                    }

                    TasStatusBarView {
                        id: tasBar
                        visible: appWindow.tasStripVisible
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        Layout.maximumHeight: 48
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        model: tasModel
                        onHaltRequested: function (reason) {
                            if (appWindow.protocol)
                                appWindow.protocol.requestHalt(reason)
                        }
                    }

                    KlmxMoleculeSpaceView {
                        id: inspector
                        visible: appWindow.moleculeVisible
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        Layout.minimumHeight: 140
                        Layout.maximumHeight: 220
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        Layout.bottomMargin: 8
                        model: klmxItem
                        coherence: appWindow.protocol ? appWindow.protocol.coherence : 1
                        mode: appWindow.protocol ? appWindow.protocol.mode : "Hybrid"
                        onAccepted: function (payload) {
                            if (appWindow.protocol)
                                appWindow.protocol.submitMap(payload)
                        }
                    }
                }
            }

            SplitView {
                orientation: Qt.Vertical
                SplitView.preferredWidth: 520
                SplitView.minimumWidth: 320
                visible: appWindow.inspectorVisible || appWindow.viewMode !== "chat"

                OcsSettingsPanelView {
                    id: settingsPanel
                    SplitView.preferredHeight: 320
                    SplitView.minimumHeight: 180
                    protocol: appWindow.protocol
                    themeName: appWindow.themeName
                    fontPointSize: appWindow.fontPointSize
                    autoScrollTranscript: appWindow.autoScrollTranscript
                    tasStripVisible: appWindow.tasStripVisible
                    moleculeVisible: appWindow.moleculeVisible
                    showRawSections: appWindow.showRawSections
                    onThemeNameChanged: appWindow.themeName = themeName
                    onFontPointSizeChanged: appWindow.fontPointSize = fontPointSize
                    onAutoScrollTranscriptChanged: appWindow.autoScrollTranscript = autoScrollTranscript
                    onTasStripVisibleChanged: appWindow.tasStripVisible = tasStripVisible
                    onMoleculeVisibleChanged: appWindow.moleculeVisible = moleculeVisible
                    onShowRawSectionsChanged: appWindow.showRawSections = showRawSections
                    onExportNexusRequested: exportDialog.open()
                    onImportNexusRequested: importDialog.open()
                    onCopySnapshotRequested: appWindow.copyNexusSnapshot()
                }

                OcsEventLogView {
                    id: eventLog
                    SplitView.fillHeight: true
                    protocol: appWindow.protocol
                    logModel: eventLogModel
                    filter: appWindow.logFilter
                    onFilterChanged: appWindow.logFilter = filter
                }
            }

            OcsMetricsPanelView {
                id: metricsPanel
                SplitView.preferredWidth: appWindow.viewMode === "inspect" ? 280 : 420
                SplitView.minimumWidth: 240
                protocol: appWindow.protocol
                genaiCallCount: appWindow.genaiCallCount
                avgResponseTime: appWindow.avgResponseTime
                lastResponseSeconds: appWindow.lastResponseSeconds
                tasActiveSteps: tasModel ? tasModel.activeSteps : 0
            }
        }

        ScrollView {
            visible: appWindow.showRawSections
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            clip: true
            TextArea {
                text: appWindow.protocol ? appWindow.protocol.sourceText : ""
                readOnly: true
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
                wrapMode: Text.Wrap
                selectByMouse: true
                background: Rectangle { color: Theme.bgSunken }
            }
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

    Connections {
        target: appWindow.protocol
        function onBusyChanged() {
            if (!appWindow.protocol)
                return
            if (appWindow.protocol.busy) {
                appWindow.busyStartedAt = Date.now()
            } else if (appWindow.busyStartedAt > 0) {
                const secs = (Date.now() - appWindow.busyStartedAt) / 1000.0
                appWindow.lastResponseSeconds = secs
                appWindow.responseSamples += 1
                appWindow.avgResponseTime =
                    ((appWindow.avgResponseTime * (appWindow.responseSamples - 1)) + secs)
                    / appWindow.responseSamples
                appWindow.busyStartedAt = 0
            }
        }
        function onTurnCompleted(ok) {
            appWindow.genaiCallCount += 1
        }
    }

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
}
