// Kurulum sırasında gösterilen ipuçları (Calamares slideshow API 2).
import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation
    Timer { interval: 7000; running: presentation.activatedInCalamares; repeat: true; onTriggered: presentation.goToNextSlide() }

    Slide {
        Rectangle { anchors.fill: parent; color: "#121216" }
        Text { anchors.centerIn: parent; color: "#F3F1EC"; font.family: "Instrument Serif"; font.pixelSize: 34
               text: "Super + Space ile her şeyi bulursun." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#121216" }
        Text { anchors.centerIn: parent; color: "#F3F1EC"; font.family: "Instrument Serif"; font.pixelSize: 34
               text: "“kur:” yazıp Fedora, RPM Fusion ya da Flathub’dan uygulama kurarsın." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#121216" }
        Text { anchors.centerIn: parent; color: "#F3F1EC"; font.family: "Instrument Serif"; font.pixelSize: 34
               text: "Her güncellemeden önce bir geri alma noktası alınır." }
    }

    function onActivate() { }
    function onLeave() { }
}
