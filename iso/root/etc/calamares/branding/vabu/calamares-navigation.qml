// Alt şerit: ortada geri ve ileri düğmeleri, solda vazgeçme bağlantısı.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick 2.15

Rectangle {
    id: root
    color: "#F4F5F7"
    // Calamares yatay şeritlere en çok 64 px verir; düğmeler buna da sığar.
    // tests/ekran.sh ileri düğmesine 1440x900 pencerede (758, 848) noktasından tıklar.
    implicitHeight: 104
    height: implicitHeight

    Row {
        anchors.centerIn: parent
        spacing: 12
        // İlk sayfada kendi düğmeleri var (Vabu'yu kur / Kurmadan dene). Son sayfada
        // ne geri ne ileri gidilebilir; orada da gizli.
        visible: ViewManager.backAndNextVisible && ViewManager.currentStepIndex > 0
                 && (ViewManager.nextEnabled || ViewManager.backEnabled)

        Rectangle {
            visible: ViewManager.backEnabled
            width: 46
            height: 46
            radius: 13
            color: backMouse.pressed ? Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.13)
                 : backMouse.containsMouse ? Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.09)
                 : Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.06)
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: "arrow_back"
                color: "#15181E"
                font.family: "Material Symbols Rounded"
                font.weight: Font.Light
                font.pixelSize: 21
            }
            // Tıklama alanı şeridin boyunca biraz daha geniş
            MouseArea {
                id: backMouse
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ViewManager.back()
            }
            Accessible.role: Accessible.Button
            Accessible.name: ViewManager.backLabel
        }
        Rectangle {
            width: Math.max(160, nextText.implicitWidth + 48)
            height: 46
            radius: 13
            opacity: ViewManager.nextEnabled ? 1 : 0.45
            color: !ViewManager.nextEnabled ? "#2C56CC"
                 : nextMouse.pressed ? "#2347AE" : nextMouse.containsMouse ? "#284EBD" : "#2C56CC"
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                id: nextText
                anchors.centerIn: parent
                text: ViewManager.nextLabel.replace("&", "")
                color: "#FFFFFF"
                font.family: "Hanken Grotesk"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: nextMouse
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
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
        opacity: ViewManager.quitEnabled ? 1 : 0.45
        anchors.left: parent.left
        anchors.leftMargin: 32
        anchors.verticalCenter: parent.verticalCenter
        text: ViewManager.quitLabel.replace("&", "")
        color: quitMouse.containsMouse ? "#15181E" : "#566070"
        font.family: "Hanken Grotesk"
        font.pixelSize: 14
        font.weight: Font.Medium
        Behavior on color { ColorAnimation { duration: 120 } }
        MouseArea {
            id: quitMouse
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            enabled: ViewManager.quitEnabled
            cursorShape: Qt.PointingHandCursor
            onClicked: ViewManager.quit()
        }
    }
}
