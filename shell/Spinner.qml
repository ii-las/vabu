import QtQuick

// Bekleme göstergesi: dönen ince yay.
Item {
    id: root
    property bool running: true
    property real size: 18
    property color color: Theme.soft
    implicitWidth: size
    implicitHeight: size

    Icon {
        anchors.centerIn: parent
        name: "progress_activity"
        size: root.size
        weight: 400
        color: root.color
        RotationAnimator on rotation {
            running: root.running && root.visible
            from: 0; to: 360
            duration: 900
            loops: Animation.Infinite
        }
    }
}
