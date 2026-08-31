import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    color: "#0d1117"
    border.color: gated ? "#f85149" : "#30363d"
    border.width: 1
    radius: 8
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
            color: "#3d1f24"
            radius: 4
            Label {
                id: gateLabel
                anchors.fill: parent
                anchors.margins: 6
                text: "KickGuard · gated" + (root.haltReason.length ? (": " + root.haltReason) : "")
                      + "  — paste ⫻protocol/ocs without ⫻cmd/halt to resume"
                color: "#f85149"
                font.family: "monospace"
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
                placeholderText: "Message (Google GenAI), ⫻ protocol, or /mode /halt /exec /obj /tas"
                enabled: !root.busy
                color: "#c9d1d9"
                placeholderTextColor: "#6e7681"
                font.family: "monospace"
                font.pixelSize: 13
                wrapMode: Text.Wrap
                selectByMouse: true
                background: Rectangle {
                    color: "#161b22"
                    border.color: "#30363d"
                    border.width: 1
                    radius: 4
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
                color: root.genaiReady ? "#6e7681" : "#d29922"
                font.family: "monospace"
                font.pixelSize: 10
                Layout.fillWidth: true
            }
            Button {
                text: root.inspectorVisible ? "Hide protocol" : "Show protocol"
                onClicked: root.inspectorToggled()
            }
            Button {
                text: "Halt"
                onClicked: {
                    if (root.protocol)
                        root.protocol.requestHalt("user-gate-from-composer")
                }
            }
            Button {
                id: sendBtn
                text: root.busy ? "…" : "Send"
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
