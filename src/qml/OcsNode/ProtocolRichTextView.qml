import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

// Read-only rich text of the living protocol document. No second store.
Rectangle {
    id: root
    color: Theme.bg

    property var protocol: null
    property string documentText: ""
    property string richText: ""

    function familyColor(family) {
        switch (family) {
        case "display": return Theme.emerald
        case "protocol": return Theme.cyan
        case "cmd": return Theme.amber
        case "data": return Theme.violet
        case "flow": return Theme.teal
        case "context": return Theme.info
        case "query": return Theme.warning
        default: return Theme.textMuted
        }
    }

    function escapeHtml(value) {
        return value.replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
    }

    function refresh() {
        if (!protocol) {
            documentText = ""
            richText = ""
            return
        }
        const raw = protocol.sourceText.length > 0 ? protocol.sourceText : protocol.emitText()
        documentText = raw
        const lines = raw.split("\n")
        let html = ""
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i]
            const shown = line.length > 0 ? escapeHtml(line) : "&nbsp;"
            if (line.charAt(0) === "\u2afb") {
                const family = line.slice(1).split(/[\/:]/)[0]
                html += "<span style=\"color:" + familyColor(family) + "\"><b>"
                        + shown + "</b></span><br/>"
            } else {
                html += "<span style=\"color:" + Theme.text + "\">" + shown + "</span><br/>"
            }
        }
        richText = html
    }

    Connections {
        target: protocol ? protocol.sections : null
        function onCountChanged() { root.refresh() }
    }

    Connections {
        target: protocol
        function onStateChanged() { root.refresh() }
        function onSourceChanged() { root.refresh() }
    }

    Component.onCompleted: refresh()

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
                    text: "Protocol"
                    font.family: Theme.fontUi
                    font.bold: true
                    font.pixelSize: 13
                    color: Theme.text
                }

                Label {
                    text: (root.protocol ? root.protocol.sections.count : 0) + " sections"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textMuted
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgSunken
            border.color: Theme.borderSubtle
            border.width: Theme.borderWidth
            radius: Theme.radiusSm

            Label {
                visible: root.documentText.length === 0
                anchors.centerIn: parent
                text: "No living document"
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Theme.textFaint
            }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                visible: root.documentText.length > 0
                clip: true

                TextArea {
                    text: root.richText
                    textFormat: TextEdit.RichText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: Theme.text
                    background: null
                }
            }
        }
    }
}
