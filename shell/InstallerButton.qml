import QtQuick
import QtQuick.Layouts

// Kurulum düğmesi: ana (vurgu rengi), ikincil (oyuk) ya da tehlikeli.
// Yazısızsa kare ikon düğmesidir. Tab ile gelinir, Enter ya da boşlukla basılır.
Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property bool primary: false
    property bool danger: false
    signal clicked()

    readonly property bool strong: primary || danger
    readonly property color ink: danger ? Theme.ink : primary ? Theme.accentInk : Theme.paper

    implicitHeight: 46
    implicitWidth: label === "" ? 46 : row.implicitWidth + (strong ? 48 : 40)
    radius: 13
    color: danger ? Theme.danger : primary ? Theme.accent : Theme.well
    opacity: enabled ? 1 : 0.45
    activeFocusOnTab: true
    scale: mouse.pressed ? 0.97 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.state } }
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.clicked()

    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: -3
        radius: root.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.alpha(root.danger ? Theme.danger : Theme.accent, 0.6)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 21
            color: root.ink
        }
        Text {
            visible: root.label !== ""
            text: root.label
            color: root.ink
            font.family: Theme.sans
            font.pixelSize: 15
            font.weight: root.strong ? Font.DemiBold : Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
