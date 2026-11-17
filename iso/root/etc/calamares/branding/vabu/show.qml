import QtQuick 2.15
import QtQuick.Layouts 1.3
import calamares.slideshow 1.0

Presentation {
    id: presentation
    Rectangle { anchors.fill: parent; color: "#F4F3EF" }
    Slide {
        x: 0; y: 0; width: presentation.width; height: presentation.height
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(560, parent.width - 48)
            spacing: 20
            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64; Layout.preferredHeight: 64
                source: "file:///usr/share/icons/hicolor/scalable/apps/vabu-logo.svg"
                sourceSize: Qt.size(128, 128)
            }
            Text {
                Layout.fillWidth: true
                text: "Vabu kuruluyor"
                color: "#222725"
                font.family: "Hanken Grotesk"; font.pixelSize: 30; font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
            }
            Text {
                Layout.fillWidth: true
                text: "Tamamlandığında yeniden başlatabilirsin. Kurulum boyunca bilgisayarı açık ve güç kaynağına bağlı tut."
                color: "#585F5B"
                font.family: "Hanken Grotesk"; font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
            }
        }
    }
}
