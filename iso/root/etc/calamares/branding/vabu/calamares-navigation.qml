// Vabu kurulum: altta yuvarlak geri düğmesi ve nane renkli "Devam et" hapı.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick 2.15

Rectangle {
    id: root
    color: "#151318"
    // Calamares bu alana implicitHeight kadar yer verir; düğmeler buna sığmalı
    implicitHeight: 104
    height: implicitHeight

    Row {
        anchors.centerIn: parent
        spacing: 12
        // İlk sayfada kendi düğmeleri var (Vabu'yu kur / Kurmadan dene)
        visible: ViewManager.backAndNextVisible && ViewManager.currentStepIndex > 0

        Rectangle {
            visible: ViewManager.backEnabled
            width: 64; height: 64; radius: 32
            color: backMouse.containsMouse ? "#2C2931" : "#221F26"
            Text { anchors.centerIn: parent; text: "←"; color: "#EFECE6"; font.pixelSize: 22 }
            MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ViewManager.back() }
            Accessible.role: Accessible.Button
            Accessible.name: ViewManager.backLabel
        }
        Rectangle {
            width: 260; height: 64; radius: 32
            opacity: ViewManager.nextEnabled ? 1 : 0.45
            color: nextMouse.containsMouse && ViewManager.nextEnabled ? "#FFFFFF" : "#EFECE6"
            Text {
                anchors.centerIn: parent
                text: ViewManager.nextLabel.replace("&", "")
                color: "#141316"
                font.family: "Hanken Grotesk"
                font.pixelSize: 16
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
        color: "#A39E97"
        font.family: "Hanken Grotesk"
        font.pixelSize: 14
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ViewManager.quit() }
    }
}
