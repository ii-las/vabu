import QtQuick
import QtQuick.Layouts

// Hoş geldin: dil seçimi; kurmadan denemek isteyen pencereyi kapatır.
InstallerPage {
    key: "welcome"
    step: 0
    heading: InstallerState.s.welcome
    headingSize: 30
    canBack: false
    nextLabel: InstallerState.s.install
    altLabel: InstallerState.s.tryLive

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: InstallerState.s.language
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        InstallerChoice {
            objectName: "dil"
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 13
            stretch: true
            fontSize: 15
            options: ["Türkçe", "English"]
            currentIndex: InstallerState.lang === "en" ? 1 : 0
            onPicked: i => InstallerState.lang = i === 1 ? "en" : "tr"
        }
    }
}
