// Kurulum sürerken gösterilen sayfa: yumuşatılmış duvar kağıdı ve ortada Vabu işareti.
// İlerleme çubuğu ve o anki iş Calamares'in kendi alanında, bu sayfanın altında görünür.
import QtQuick 2.15
import QtQuick.Shapes 1.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    // Uyuyan kedi: tek siluet, gözler ve burun oyuk (oyuk rengi altındaki zeminin rengi)
    component CatMark: Item {
        id: mark
        property color tint: "#FFFFFF"
        property color cutout: "#2C56CC"
        implicitWidth: 48
        implicitHeight: 48
        // kenarlar yumuşak çıksın diye çoklu örnekleme
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true

        Shape {
            width: 256
            height: 256
            scale: mark.width / 256
            transformOrigin: Item.TopLeft
            ShapePath {
                fillColor: mark.tint
                strokeColor: "transparent"
                PathSvg { path: "M128 232 C62 232 22 202 22 156 C22 136 28 120 36 106 L50 52 Q55 36 69 45 L108 80 Q128 74 148 80 L187 45 Q201 36 206 52 L220 106 C228 120 234 136 234 156 C234 202 194 232 128 232 Z" }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: mark.cutout
                strokeWidth: 13
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M76 150 Q94 168 112 150 M144 150 Q162 168 180 150" }
            }
            ShapePath {
                fillColor: mark.cutout
                strokeColor: mark.cutout
                strokeWidth: 6
                joinStyle: ShapePath.RoundJoin
                PathSvg { path: "M120 180 h16 l-8 9 z" }
            }
        }
    }

    // Slayt alanının dışı da pencereyle aynı zeminde kalsın
    Rectangle { anchors.fill: parent; color: "#F4F5F7" }

    Slide {
        // Calamares'in Slide'ı kenar boşluğuyla gelir; bütün alanı kullan
        x: 0
        y: 0
        width: presentation.width
        height: presentation.height

        Item {
            id: card
            width: Math.min(parent.width - 48, 880)
            height: Math.min(parent.height - 24, Math.round(width * 0.5))
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)

            Rectangle { anchors.fill: parent; color: "#FFFFFF" }
            // Küçük çözülüp büyütülen resim kendiliğinden bulanık görünür
            Image {
                anchors.fill: parent
                source: "file:///usr/share/vabu/assets/wallpaper.jpg"
                sourceSize: Qt.size(160, 90)
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                clip: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 800 } }
            }
            // Açık bir tül: renkler sakinleşir
            Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.22) }
            // Köşeleri yuvarlatan çerçeve: zemin renginde kalın kenarlık, iç köşesi 14 px kalır
            Rectangle {
                anchors.fill: parent
                anchors.margins: -24
                radius: 38
                color: "transparent"
                border.width: 24
                border.color: "#F4F5F7"
            }
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.07)
            }

            Rectangle {
                anchors.centerIn: parent
                width: 72
                height: 72
                radius: 24
                color: "#2C56CC"
                CatMark {
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                }
            }
        }
    }

    // Belirme: kurulum başlayınca bir kez. Çağrı gelmezse kart zaten görünür durur.
    NumberAnimation {
        id: enter
        target: card
        property: "opacity"
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    }

    function onActivate() { enter.restart() }
    function onLeave() { }
}
