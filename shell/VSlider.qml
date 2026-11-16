import QtQuick

// İnce kaydırıcı: 3 px iz, sürüklerken büyüyen tutamak.
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
    readonly property bool engaged: mouse.pressed || mouse.containsMouse || activeFocus

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
        height: root.engaged ? 4 : 3
        radius: height / 2
        color: Theme.track
        Behavior on height { NumberAnimation { duration: Theme.fast } }
        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: root.fill
        }
    }
    Rectangle {
        readonly property real d: mouse.pressed ? 18 : root.engaged ? 14 : 12
        x: track.width * root.ratio - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: d; height: d; radius: d / 2
        color: Theme.knob
        border.width: Theme.dark ? 0 : 1
        border.color: Qt.rgba(22 / 255, 32 / 255, 44 / 255, 0.12)
        Behavior on width { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on height { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => { root.forceActiveFocus(); root.setFromX(mouse.x) }
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x) }
    }
}
