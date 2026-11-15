import QtQuick

Item {
    id: root
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property real value: 0
    property color fill: Theme.accent
    signal moved(real value)

    implicitWidth: 240
    implicitHeight: 28
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider

    readonly property real ratio: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    function setFromX(x) {
        let v = from + Math.max(0, Math.min(1, x / track.width)) * (to - from)
        if (stepSize > 0) v = Math.round(v / stepSize) * stepSize
        v = Math.max(from, Math.min(to, v))
        if (v !== value) root.moved(v)
    }

    Keys.onLeftPressed: root.moved(Math.max(from, value - (stepSize || (to - from) / 20)))
    Keys.onRightPressed: root.moved(Math.min(to, value + (stepSize || (to - from) / 20)))

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Qt.rgba(1, 1, 1, 0.12)
        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: 3
            color: root.fill
        }
    }
    Rectangle {
        x: track.width * root.ratio - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 20; height: 20; radius: 10
        color: Theme.paper
        border.color: root.activeFocus ? Theme.accent : "transparent"
        border.width: 2
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => { root.forceActiveFocus(); root.setFromX(mouse.x) }
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x) }
    }
}
