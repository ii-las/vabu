import QtQuick

// Parçalı seçici. Seçili parçanın zemini bir sonrakine kayarak geçer.
Rectangle {
    id: root
    property var options: []
    property int currentIndex: 0
    property bool mono: false
    property bool stretch: false          // parçalar genişliği eşit paylaşır
    signal picked(int index)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 40
    radius: Theme.radiusRow + 1
    color: Theme.well

    Rectangle {
        id: pill
        readonly property Item target: repeater.count > root.currentIndex && root.currentIndex >= 0 ? repeater.itemAt(root.currentIndex) : null
        visible: target !== null
        x: target ? row.x + target.x : 0
        width: target ? target.width : 0
        y: 4
        height: root.height - 8
        radius: Theme.radiusRow - 3
        color: Theme.segOn
        border.width: Theme.dark ? 0 : 1
        border.color: Qt.rgba(22 / 255, 32 / 255, 44 / 255, 0.08)
        Behavior on x { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on width { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }

    Row {
        id: row
        x: root.stretch ? 4 : (root.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            id: repeater
            model: root.options
            delegate: Item {
                required property var modelData
                required property int index
                readonly property bool isOn: root.currentIndex === index
                width: root.stretch ? (root.width - 8) / Math.max(1, root.options.length) : label.implicitWidth + 28
                height: root.height - 8
                Accessible.role: Accessible.RadioButton
                Accessible.checked: isOn
                Accessible.name: modelData
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.isOn ? Theme.paper : Theme.soft
                    font.family: Theme.sans
                    font.pixelSize: 13
                    font.weight: parent.isOn ? Font.DemiBold : Font.Normal
                    font.features: root.mono ? { "tnum": 1 } : {}
                    Behavior on color { ColorAnimation { duration: Theme.state } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.index)
                }
            }
        }
    }
}
