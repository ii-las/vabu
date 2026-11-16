import QtQuick

// Parçalı seçici. Seçili parçanın zemini bir sonrakine kayar; odaktayken oklarla değişir.
Rectangle {
    id: root
    property var options: []
    property int currentIndex: 0
    property bool stretch: false
    property int fontSize: 13
    signal picked(int index)

    implicitHeight: 36
    implicitWidth: row.implicitWidth + 6
    radius: 11
    color: Theme.well
    activeFocusOnTab: true
    Accessible.role: Accessible.PageTabList

    Keys.onLeftPressed: if (currentIndex > 0) picked(currentIndex - 1)
    Keys.onRightPressed: if (currentIndex < options.length - 1) picked(currentIndex + 1)

    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: -3
        radius: root.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.alpha(Theme.accent, 0.6)
    }

    Rectangle {
        id: pill
        readonly property Item target: repeater.count > root.currentIndex && root.currentIndex >= 0 ? repeater.itemAt(root.currentIndex) : null
        visible: target !== null
        x: target ? row.x + target.x : 0
        y: 3
        width: target ? target.width : 0
        height: root.height - 6
        radius: root.radius - 3
        color: Theme.segOn
        border.width: Theme.dark ? 0 : 1
        border.color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.08)
        Behavior on x { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on width { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }

    Row {
        id: row
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            id: repeater
            model: root.options
            delegate: Item {
                id: seg
                required property var modelData
                required property int index
                readonly property bool isOn: root.currentIndex === index
                width: root.stretch ? (root.width - 6) / Math.max(1, root.options.length) : label.implicitWidth + 26
                height: root.height - 6
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData
                Accessible.selected: isOn
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: seg.modelData
                    color: seg.isOn ? Theme.paper : Theme.soft
                    font.family: Theme.sans
                    font.pixelSize: root.fontSize
                    font.weight: seg.isOn ? Font.DemiBold : Font.Normal
                    Behavior on color { ColorAnimation { duration: Theme.state } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(seg.index)
                }
            }
        }
    }
}
