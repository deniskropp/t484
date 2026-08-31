import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OcsNode 1.0

Rectangle {
    id: root

    property var protocol: null
    property bool inspectorVisible: true
    signal inspectorToggled()

    readonly property bool gated: protocol ? protocol.gated : false
    readonly property bool busy: protocol ? protocol.busy : false
    readonly property bool genaiReady: protocol ? protocol.genaiReady : false
    readonly property string genaiModel: protocol ? protocol.genaiModel : ""
    readonly property string genaiSource: protocol ? protocol.genaiSource : ""
    readonly property string haltReason: protocol ? protocol.haltReason : ""

    color: Theme.bg
    border.color: gated ? Theme.danger : Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius
    implicitHeight: col.implicitHeight + 20

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            visible: root.gated
            Layout.fillWidth: true
            implicitHeight: gateLabel.implicitHeight + 12
            color: Theme.gateFill
            radius: Theme.radiusSm
            Label {
                id: gateLabel
                anchors.fill: parent
                anchors.margins: 6
                text: "KickGuard · gated" + (root.haltReason.length ? (": " + root.haltReason) : "")
                      + "  — paste \u2afbprotocol/ocs without \u2afbcmd/halt to resume"
                color: Theme.danger
                font.family: Theme.fontMono
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 88
            clip: true
            TextArea {
                id: input
                placeholderText: "Message (Google GenAI), \u2afb protocol, or /mode /halt /exec /obj /tas"
                enabled: !root.busy
                color: Theme.text
                placeholderTextColor: Theme.textFaint
                font.family: Theme.fontMono
                font.pixelSize: 13
                wrapMode: Text.Wrap
                selectByMouse: true
                background: Rectangle {
                    color: Theme.bgRaised
                    border.color: Theme.border
                    border.width: Theme.borderWidth
                    radius: Theme.radiusSm
                }
                Keys.onPressed: function (event) {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && !(event.modifiers & Qt.ShiftModifier)) {
                        event.accepted = true
                        root.send()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                text: root.busy
                      ? ("KickFlow · " + root.genaiModel + " …")
                      : (root.genaiReady
                         ? ("Enter send · " + root.genaiModel + " · " + root.genaiSource)
                         : "no Gemini key in this process — .env or launch env")
                color: root.genaiReady ? Theme.textFaint : Theme.warning
                font.family: Theme.fontMono
                font.pixelSize: 10
                Layout.fillWidth: true
            }
            Button {
                text: root.inspectorVisible ? "Hide protocol" : "Show protocol"
                onClicked: root.inspectorToggled()
            }
            Button {
                text: "/halt"
                onClicked: {
                    if (root.protocol)
                        root.protocol.requestHalt("user-gate-from-composer")
                }
            }
            Button {
                id: sendBtn
                text: root.busy ? "…" : "/exec"
                highlighted: true
                enabled: !root.busy && input.text.trim().length > 0
                onClicked: root.send()
            }
        }
    }

    function send() {
        const text = input.text
        if (!text || !text.trim().length || !root.protocol || root.busy)
            return
        root.protocol.sendChat(text)
        input.text = ""
        input.forceActiveFocus()
    }

    Component.onCompleted: input.forceActiveFocus()
}
