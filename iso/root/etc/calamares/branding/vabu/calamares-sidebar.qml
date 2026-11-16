// Üst şerit: solda işaret ve ad, ortada adımlar. Adımlar Calamares ViewManager'dan gelir.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick 2.15
import QtQuick.Shapes 1.15

Rectangle {
    id: root
    color: "#F4F5F7"
    // Calamares yatay şeritlere en çok 64 px verir
    implicitHeight: 64
    height: implicitHeight

    // Uyuyan kedi: tek siluet, gözler ve burun zemin renginde oyuk
    component CatMark: Item {
        id: mark
        property color tint: "#2C56CC"
        property color cutout: "#F4F5F7"
        implicitWidth: 30
        implicitHeight: 30
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

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 32
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        CatMark {
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Vabu kurulumu"
            color: "#15181E"
            font.family: "Hanken Grotesk"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
    }

    // Geçilen ve bulunulan adımlar vurgu renginde; bulunulan uzun bir hap
    Row {
        anchors.centerIn: parent
        spacing: 6
        Repeater {
            model: ViewManager
            Rectangle {
                width: index === ViewManager.currentStepIndex ? 28 : 10
                height: 5
                radius: 2.5
                color: index <= ViewManager.currentStepIndex ? "#2C56CC" : Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.18)
                Behavior on width {
                    NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
                }
                Behavior on color { ColorAnimation { duration: 220 } }
            }
        }
    }
}
