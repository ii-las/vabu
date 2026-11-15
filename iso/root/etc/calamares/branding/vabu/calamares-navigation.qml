// Vabu kurulum: altta yuvarlak geri düğmesi ve nane renkli "Devam et" hapı.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick 2.15

Rectangle {
    id: root
    color: "#121216"
    height: 150

    Row {
        anchors.centerIn: parent
        spacing: 12
        visible: ViewManager.backAndNextVisible

        Rectangle {
            visible: ViewManager.backEnabled
            width: 80; height: 80; radius: 40
            color: backMouse.containsMouse ? "#34313B" : "#26242C"
            Text { anchors.centerIn: parent; text: "←"; color: "#F3F1EC"; font.pixelSize: 26 }
            MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ViewManager.back() }
            Accessible.role: Accessible.Button
            Accessible.name: ViewManager.backLabel
        }
        Rectangle {
            width: 300; height: 80; radius: 40
            opacity: ViewManager.nextEnabled ? 1 : 0.45
            color: nextMouse.containsMouse && ViewManager.nextEnabled ? "#A6F5D3" : "#8EF0C6"
            Text {
                anchors.centerIn: parent
                text: ViewManager.nextLabel.replace("&", "")
                color: "#0E3B2C"
                font.family: "Geist"
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: ViewManager.nextEnabled
                cursorShape: Qt.PointingHandCursor
                onClicked: ViewManager.next()
            }
            Accessible.role: Accessible.Button
            Accessible.name: ViewManager.nextLabel
        }
    }

    Text {
        visible: ViewManager.quitVisible
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        text: ViewManager.quitLabel.replace("&", "")
        color: "#A3A1A8"
        font.family: "Geist"
        font.pixelSize: 14
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ViewManager.quit() }
    }
}
