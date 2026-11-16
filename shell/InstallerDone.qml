import QtQuick
import QtQuick.Layouts

// Bitti: yeniden başlat ya da canlı oturumda kal.
InstallerPage {
    key: "done"
    step: 6
    canBack: false
    nextLabel: InstallerState.s.restart
    altLabel: InstallerState.s.close

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 18
        Layout.bottomMargin: 6
        spacing: 14

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 64
            implicitHeight: 64
            radius: 22
            color: Theme.accent
            Icon {
                anchors.centerIn: parent
                name: "check"
                size: 34
                weight: 400
                color: Theme.accentInk
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: InstallerState.s.done
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: 28
            font.weight: Font.DemiBold
            font.letterSpacing: -0.4
        }
    }
}
