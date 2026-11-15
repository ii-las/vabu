// Kurulum tamamlandı ekranı
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#121216"
    readonly property bool failed: (config.failureMessage || "") !== ""

    // Eş yükselti adaları: sayfa açılınca halka halka çizilir
    Canvas {
        id: islands
        anchors.fill: parent
        property real grow: 0
        onGrowChanged: requestPaint()
        onWidthChanged: requestPaint()
        NumberAnimation on grow { running: page.visible; from: 0; to: 1; duration: 2400; easing.type: Easing.OutCubic }
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const sx = width / 1440, sy = height / 900
            function island(cx, cy, n, base, gap, seed, color) {
                ctx.strokeStyle = color
                ctx.lineWidth = 1.2
                const shown = n * islands.grow
                for (let k = 0; k < Math.ceil(shown); k++) {
                    ctx.globalAlpha = Math.min(1, shown - k)
                    const r0 = base + k * gap
                    ctx.beginPath()
                    for (let i = 0; i <= 80; i++) {
                        const t = (i / 80) * Math.PI * 2
                        const r = r0 * (1 + 0.12 * Math.sin(3 * t + seed + k * 0.3) + 0.06 * Math.sin(5 * t - k * 0.5))
                        const x = (cx + r * Math.cos(t) * 1.3) * sx, y = (cy + r * Math.sin(t)) * sy
                        i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)
                    }
                    ctx.stroke()
                }
            }
            island(220, 120, 7, 22, 18, 0.4, "rgba(169,199,247,0.55)")
            island(1210, 260, 9, 20, 17, 1.9, "rgba(169,199,247,0.55)")
            island(1180, 820, 8, 24, 19, 2.7, "rgba(242,180,138,0.5)")
        }
    }

    Rectangle {
        x: page.width * 0.23; y: page.height * 0.32
        width: 112; height: 112; radius: 30
        scale: 0.6
        opacity: 0
        SequentialAnimation on scale {
            running: page.visible
            PauseAnimation { duration: 250 }
            NumberAnimation { to: 1; duration: 520; easing.type: Easing.OutBack }
        }
        NumberAnimation on opacity { running: page.visible; to: 1; duration: 500 }
        color: page.failed ? "#F7A8A8" : "#8EF0C6"
        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -8; text: "v"; color: "#0E3B2C"; font.family: "Instrument Serif"; font.italic: true; font.pixelSize: 96 }
    }
    Rectangle { x: page.width * 0.23 + 112; y: page.height * 0.32 + 112; width: 30; height: 30; color: "#F2B48A" }

    ColumnLayout {
        opacity: 0
        SequentialAnimation on opacity {
            running: page.visible
            PauseAnimation { duration: 500 }
            NumberAnimation { to: 1; duration: 600; easing.type: Easing.OutCubic }
        }
        x: page.width * 0.5
        y: page.height * 0.3
        width: Math.min(460, page.width * 0.42)
        spacing: 16

        Text {
            Layout.fillWidth: true
            textFormat: Text.StyledText
            text: page.failed ? "Kurulum<br>tamamlanamadı" : "Kurulum<br>tamamlandı"
            color: page.failed ? "#F7A8A8" : "#A9C7F7"
            font.family: "Instrument Serif"
            font.italic: true
            font.pixelSize: 74
            lineHeight: 0.92
        }
        Text {
            Layout.fillWidth: true
            text: page.failed ? config.failureMessage
                : "Vabu bilgisayarına kuruldu. Yeniden başlattığında giriş ekranı seni karşılayacak."
            color: "#CFC9C2"; font.family: "Geist"; font.pixelSize: 15; wrapMode: Text.Wrap; lineHeight: 1.25
        }
        Text {
            Layout.fillWidth: true
            visible: page.failed && (config.failureDetails || "") !== ""
            text: config.failureDetails || ""
            color: "#8E8B93"; font.family: "Geist Mono"; font.pixelSize: 11; wrapMode: Text.Wrap
        }
        Text {
            Layout.fillWidth: true
            visible: !page.failed
            text: "İlk açılışta: Ayarlar › Sürücüler ekran kartın için önerilen sürücüyü tek tıkla kurar."
            color: "#CFC9C2"; font.family: "Geist"; font.pixelSize: 15; wrapMode: Text.Wrap; lineHeight: 1.25
        }
        Rectangle {
            Layout.topMargin: 12
            visible: !page.failed
            implicitWidth: 300; implicitHeight: 80; radius: 40
            color: "#8EF0C6"
            Text { anchors.centerIn: parent; text: "Yeniden başlat"; color: "#0E3B2C"; font.family: "Geist"; font.pixelSize: 17; font.weight: Font.DemiBold }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: config.doRestart(true) }
        }
    }

    Rectangle {
        x: 64; y: page.height - 110
        width: tag.implicitWidth + 20; height: 24; radius: 6
        color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.3)
        Text { id: tag; anchors.centerIn: parent; text: "KURULUM"; color: "#A3A1A8"; font.family: "Geist Mono"; font.pixelSize: 10; font.letterSpacing: 1.6 }
    }
    Text { x: 64; y: page.height - 76; text: "Vabu 0.1"; color: "#8E8B93"; font.family: "Instrument Serif"; font.pixelSize: 30 }
}
