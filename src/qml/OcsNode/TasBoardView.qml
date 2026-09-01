import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root
    color: Theme.bg

    property var model: null
    property var protocol: null
    property var tasks: []

    readonly property string currentTasId: model ? model.currentTasId : ""
    readonly property int activeSteps: model ? model.activeSteps : 0
    readonly property real coherence: model ? model.coherence : 0
    readonly property bool gated: model ? model.gated : false

    function refreshTasks() {
        if (!protocol || !model)
            return
        const tasBody = protocol.sectionBody("data/tas")
        const ptasBody = protocol.sectionBody("data/ptas")
        tasks = model.parseTasEntries(tasBody, ptasBody)
    }

    Connections {
        target: protocol ? protocol.sections : null
        function onCountChanged() { root.refreshTasks() }
    }

    Connections {
        target: protocol
        function onStateChanged() { root.refreshTasks() }
    }

    Component.onCompleted: refreshTasks()

    function filterByStatus(statuses) {
        const result = []
        for (let i = 0; i < tasks.length; ++i) {
            const item = tasks[i]
            if (statuses.indexOf(item.status) >= 0)
                result.push(item)
        }
        return result
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: Theme.bgRaised
            border.color: Theme.border
            border.width: Theme.borderWidth
            radius: Theme.radiusSm

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Label {
                    text: "TAS / PTAS Board"
                    font.family: Theme.fontUi
                    font.bold: true
                    font.pixelSize: 13
                    color: Theme.text
                }

                Rectangle {
                    radius: Theme.radiusSm
                    color: root.gated ? Theme.danger : Theme.bgPanel
                    implicitWidth: statusText.implicitWidth + 8
                    implicitHeight: 20
                    Label {
                        id: statusText
                        anchors.centerIn: parent
                        text: root.gated ? "GATED" : (root.activeSteps > 0 ? "RUNNING" : "IDLE")
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: root.gated ? "#ffffff" : Theme.cyan
                    }
                }

                Label {
                    text: "Current: " + (root.currentTasId.length ? root.currentTasId : "\u2014")
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    Layout.maximumWidth: 320
                }

                Item { Layout.fillWidth: true }

                ProgressBar {
                    from: 0
                    to: 1
                    value: root.coherence
                    implicitWidth: 100
                    implicitHeight: 8
                }

                Label {
                    text: Math.round(root.coherence * 100) + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.coherenceColor(root.coherence)
                }

                Label {
                    text: root.activeSteps + " active / " + root.tasks.length + " total"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.textFaint
                }

                Button {
                    text: "Refresh"
                    onClicked: root.refreshTasks()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            component TaskColumn: Rectangle {
                id: colRect
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgRaised
                border.color: Theme.borderSubtle
                border.width: Theme.borderWidth
                radius: Theme.radiusSm

                property string title: ""
                property color titleColor: Theme.cyan
                property var items: []

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: Theme.bgPanel
                        radius: Theme.radiusSm

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            Label {
                                text: colRect.title
                                font.family: Theme.fontUi
                                font.bold: true
                                font.pixelSize: 11
                                color: colRect.titleColor
                            }
                            Item { Layout.fillWidth: true }
                            Label {
                                text: String(colRect.items.length)
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    ListView {
                        id: taskList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        model: colRect.items

                        delegate: Rectangle {
                            width: taskList.width
                            implicitHeight: cardCol.implicitHeight + 12
                            radius: Theme.radiusSm
                            color: Theme.bgSunken
                            border.color: modelData.id === root.currentTasId ? Theme.cyan : Theme.borderSubtle
                            border.width: modelData.id === root.currentTasId ? 2 : Theme.borderWidth

                            ColumnLayout {
                                id: cardCol
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        radius: Theme.radiusSm
                                        color: modelData.status === "done" ? Theme.emerald : (modelData.status === "active" ? Theme.amber : Theme.bgPanel)
                                        implicitWidth: idBadge.implicitWidth + 8
                                        implicitHeight: 18
                                        Label {
                                            id: idBadge
                                            anchors.centerIn: parent
                                            text: modelData.id
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: modelData.status === "done" || modelData.status === "active" ? Theme.bgChrome : Theme.text
                                        }
                                    }

                                    Rectangle {
                                        radius: Theme.radiusSm
                                        color: Theme.bgChrome
                                        implicitWidth: kindBadge.implicitWidth + 6
                                        implicitHeight: 16
                                        Label {
                                            id: kindBadge
                                            anchors.centerIn: parent
                                            text: modelData.kind.toUpperCase()
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textFaint
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Label {
                                        text: modelData.status
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textMuted
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                    color: Theme.text
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }
            }

            TaskColumn {
                title: "ACTIVE"
                titleColor: Theme.amber
                items: root.filterByStatus(["active"])
            }

            TaskColumn {
                title: "OPEN / PLANNED"
                titleColor: Theme.cyan
                items: root.filterByStatus(["open", "planned"])
            }

            TaskColumn {
                title: "COMPLETED"
                titleColor: Theme.emerald
                items: root.filterByStatus(["done"])
            }

            TaskColumn {
                title: "BLOCKED / POLICY"
                titleColor: Theme.violet
                items: root.filterByStatus(["blocked", "policy"])
            }
        }
    }
}
