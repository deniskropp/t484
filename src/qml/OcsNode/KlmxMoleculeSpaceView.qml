import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var model: null
    property string sectionType: model ? model.sectionType : "context/klmx"
    property string molecule: model ? model.molecule : "Kick/Lang"
    property alias formula: formulaArea.text
    property string modelName: model ? model.modelName : ""
    property string space: model ? model.space : "OCS/Node"
    property string scope: model ? model.scope : "global"
    property string reference: model ? model.reference : ""
    property string mode: model ? model.mode : "Hybrid"
    property real coherence: model ? model.coherence : 1.0
    property bool editable: model ? model.editable : true
    property string validationStatus: model ? model.validationStatus : "idle"
    signal accepted(var payload)
    signal validationRequested(string formula)

    color: "#0d1117"
    border.color: coherence > 0.85 ? "#238636" : (coherence > 0.6 ? "#9e6a03" : "#da3633")
    border.width: 1
    radius: 8

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10
        RowLayout {
            spacing: 12
            Label {
                text: "\u2afb" + root.sectionType + ":" + root.molecule
                color: "#7ee787"; font.family: "monospace"; font.pixelSize: 14; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: 3; color: "#21262d"
                implicitWidth: modeLabel.implicitWidth + 12; implicitHeight: 22
                Label { id: modeLabel; anchors.centerIn: parent; text: root.mode; font.family: "monospace"; font.pixelSize: 11; color: "#58a6ff" }
            }
            ProgressBar { from: 0; to: 1; value: root.coherence; implicitWidth: 70; implicitHeight: 6 }
            Label { text: Math.round(root.coherence * 100) + "%"; font.family: "monospace"; font.pixelSize: 11; color: "#8b949e" }
        }
        GridLayout {
            columns: 4; columnSpacing: 16; rowSpacing: 6; Layout.fillWidth: true
            Label { text: "Space"; color: "#8b949e"; font.pixelSize: 11 }
            Label { text: root.space; color: "#c9d1d9"; font.family: "monospace"; font.pixelSize: 12; Layout.fillWidth: true }
            Label { text: "Scope"; color: "#8b949e"; font.pixelSize: 11 }
            Label { text: root.scope; color: "#c9d1d9"; font.family: "monospace"; font.pixelSize: 12; Layout.fillWidth: true }
            Label { text: "Model"; color: "#8b949e"; font.pixelSize: 11 }
            Label { text: root.modelName.length ? root.modelName : "—"; color: "#c9d1d9"; font.family: "monospace"; font.pixelSize: 12; Layout.fillWidth: true }
            Label { text: "Ref"; color: "#8b949e"; font.pixelSize: 11 }
            Label { text: root.reference.length ? root.reference : "—"; color: "#c9d1d9"; font.family: "monospace"; font.pixelSize: 12; elide: Text.ElideMiddle; Layout.fillWidth: true }
        }
        Label { text: "Formula"; color: "#8b949e"; font.pixelSize: 11 }
        ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            TextArea {
                id: formulaArea
                text: root.model ? root.model.formula : ""
                color: "#c9d1d9"; font.family: "monospace"; font.pixelSize: 13
                wrapMode: Text.Wrap; readOnly: !root.editable
                background: Rectangle { color: "#161b22"; border.color: "#30363d"; border.width: 1; radius: 4 }
                selectByMouse: true
                onTextChanged: if (root.model && root.editable) root.model.formula = text
            }
        }
        RowLayout {
            spacing: 8
            Label {
                text: root.validationStatus
                color: {
                    switch (root.validationStatus) {
                    case "valid": return "#3fb950"
                    case "invalid": return "#f85149"
                    case "validating": return "#d29922"
                    default: return "#8b949e"
                    }
                }
                font.family: "monospace"; font.pixelSize: 11
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Validate"
                enabled: root.editable && formulaArea.text.length > 0
                onClicked: {
                    root.validationRequested(formulaArea.text)
                    if (root.model) root.model.validateFormula()
                }
            }
            Button {
                text: "Submit"
                enabled: root.editable; highlighted: true
                onClicked: {
                    var payload = {
                        "sectionType": root.sectionType,
                        "molecule": root.molecule,
                        "formula": formulaArea.text,
                        "qualifier": root.molecule,
                        "body": formulaArea.text,
                        "model": root.modelName,
                        "space": root.space,
                        "scope": root.scope,
                        "reference": root.reference,
                        "mode": root.mode,
                        "coherence": root.coherence
                    }
                    root.accepted(payload)
                    if (root.model) root.model.submitMolecule(payload)
                }
            }
        }
    }
}
