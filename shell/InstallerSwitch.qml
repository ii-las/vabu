import QtQuick
import QtQuick.Layouts

// Açma kapama satırı. Satırın her yerine tıklanır; odaktayken boşlukla değişir.
Rectangle {
    id: root
    property string label: ""
    property bool checked: false
    signal toggled()

    implicitHeight: 56
    radius: 14
    color: InstallerState.group
    border.width: 1
    border.color: Theme.groupEdge
    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onToggleAction: root.toggled()

    Keys.onSpacePressed: root.toggled()

    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: -3
        radius: root.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.alpha(Theme.accent, 0.6)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16
        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: 14
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Toggle { checked: root.checked }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
