import QtQuick
import QtQuick.Controls
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
            height: 36
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
            }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            Rectangle {
                SplitView.preferredWidth: appWindow.viewMode === "dev" ? 420 : 560
                SplitView.minimumWidth: 360
                color: Theme.bg

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    OcsChatTranscriptView {
                        id: transcript
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        protocol: appWindow.protocol
                        autoScroll: appWindow.autoScrollTranscript
                        fontPointSize: appWindow.fontPointSize
                        themeName: appWindow.themeName
                    }

                    OcsComposerView {
                        id: composer
                        Layout.fillWidth: true
                        protocol: appWindow.protocol
                        inspectorVisible: appWindow.inspectorVisible
                        onInspectorToggled: appWindow.inspectorVisible = !appWindow.inspectorVisible
                    }

                    RowLayout {
                        visible: appWindow.tasStripVisible
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        Layout.margins: 8
                        spacing: 10

                        TasStatusBarView {
                            id: tasBar
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: tasModel
                            onHaltRequested: function (reason) {
                                if (appWindow.protocol)
                                    appWindow.protocol.requestHalt(reason)
                            }
                        }

                        KlmxMoleculeSpaceView {
                            id: inspector
                            visible: appWindow.moleculeVisible
                            Layout.preferredWidth: 220
                            Layout.fillHeight: true
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
}
