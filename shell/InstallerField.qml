import QtQuick
import QtQuick.Layouts

// Etiketli metin alanı. Hatada kenarı kırmızılaşır, altında kısa bir not çıkar.
// `next` verilirse Enter odağı oraya geçirir; verilmezse Enter sayfaya (Devam et) gider.
FocusScope {
    id: root
    property string label: ""
    property alias text: input.text
    property bool password: false
    property string error: ""
    property string icon: ""
    property string placeholder: ""
    property int maximumLength: 256
    property Item next: null
    property bool reveal: false
    signal edited()

    implicitWidth: 260
    implicitHeight: column.implicitHeight

    function clear() { input.text = "" }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 6

        Text {
            visible: root.label !== ""
            text: root.label
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 12
            color: input.activeFocus ? Theme.hover : Theme.well
            border.width: 1.5
            border.color: root.error !== "" ? Theme.danger : input.activeFocus ? Theme.accent : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onPressed: input.forceActiveFocus()
            }

            Icon {
                visible: root.icon !== ""
                x: 13
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon
                size: 19
                color: Theme.muted
            }

            TextInput {
                id: input
                objectName: root.objectName
                focus: true
                activeFocusOnTab: true
                anchors.fill: parent
                anchors.leftMargin: root.icon !== "" ? 42 : 14
                anchors.rightMargin: root.password ? 46 : 14
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 15
                font.letterSpacing: echoMode === TextInput.Password ? 2 : 0
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentInk
                selectByMouse: true
                clip: true
                maximumLength: root.maximumLength
                echoMode: root.password && !root.reveal ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                inputMethodHints: root.password ? Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText : Qt.ImhNoPredictiveText
                Accessible.name: root.label || root.placeholder
                onTextEdited: root.edited()
                Keys.onReturnPressed: event => {
                    if (root.next) root.next.forceActiveFocus()
                    else event.accepted = false
                }
                Keys.onEnterPressed: event => {
                    if (root.next) root.next.forceActiveFocus()
                    else event.accepted = false
                }

                Text {
                    visible: !input.text && root.placeholder !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.placeholder
                    color: Theme.faint
                    font: input.font
                }
            }

            Icon {
                visible: root.password
                anchors.right: parent.right
                anchors.rightMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                name: root.reveal ? "visibility_off" : "visibility"
                size: 20
                color: Theme.muted
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -9
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.reveal = !root.reveal
                }
            }
        }

        Text {
            visible: root.error !== ""
            Layout.fillWidth: true
            text: root.error
            color: Theme.danger
            font.family: Theme.sans
            font.pixelSize: 13
            wrapMode: Text.Wrap
        }
    }
}
