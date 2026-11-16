// Vabu kurulum: üstte ilerleme çizgisi. Calamares ViewManager adımlarını gösterir.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick 2.15

Rectangle {
    id: root
    color: "#151318"
    implicitHeight: 76
    height: implicitHeight

    Row {
        anchors.centerIn: parent
        spacing: 6
        Repeater {
            id: steps
            model: ViewManager
            Rectangle {
                width: index === ViewManager.currentStepIndex ? 46 : 18
                height: 6
                radius: 3
                color: index < ViewManager.currentStepIndex ? "#EFECE6"
                     : index === ViewManager.currentStepIndex ? "#EFECE6" : Qt.rgba(1, 1, 1, 0.18)
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        text: String(ViewManager.currentStepIndex + 1).padStart(2, "0") + " / " + String(steps.count).padStart(2, "0")
        color: "#8C8882"
        font.family: "Hanken Grotesk"
        font.pixelSize: 11
        font.letterSpacing: 1.6
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        text: "vabu"
        color: "#EFECE6"
        font.family: "Hanken Grotesk"; font.weight: Font.DemiBold
        font.pixelSize: 26
    }
}
