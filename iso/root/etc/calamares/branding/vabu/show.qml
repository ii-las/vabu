// Kurulum sürerken gösterilen sayfa: eş yükselti haritası yavaşça büyür, ipuçları döner.
import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    readonly property var tips: [
        "Super + Space ile her şeyi bulursun.",
        "“kur:” yazıp Fedora, RPM Fusion ya da Flathub’dan uygulama kurarsın.",
        "Her güncellemeden önce bir geri alma noktası alınır.",
        "Ayarlar › Sürücüler ekran kartın için doğru sürücüyü kurar.",
        "Super + Shift + / bütün kısayolları gösterir."
    ]
    property int tip: 0

    Timer {
        interval: 6000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: { tipText.opacity = 0; swap.start() }
    }
    Timer { id: swap; interval: 300; onTriggered: { presentation.tip = (presentation.tip + 1) % presentation.tips.length; tipText.opacity = 1 } }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#121216"

            Canvas {
                id: map
                anchors.fill: parent
                property real t: 0
                NumberAnimation on t { from: 0; to: 1; duration: 90000; loops: Animation.Infinite }
                onTChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width * 0.5, cy = height * 0.42
                    const rings = 3 + map.t * 14
                    for (let k = 0; k < Math.ceil(rings); k++) {
                        const r0 = 30 + k * 22
                        ctx.globalAlpha = Math.min(1, rings - k) * (0.55 - k * 0.025)
                        ctx.strokeStyle = k % 4 === 3 ? "#F2B48A" : "#A9C7F7"
                        ctx.lineWidth = k % 4 === 3 ? 1.6 : 1.1
                        ctx.beginPath()
                        for (let i = 0; i <= 120; i++) {
                            const a = (i / 120) * Math.PI * 2
                            const r = r0 * (1 + 0.1 * Math.sin(3 * a + 0.6 + k * 0.22) + 0.06 * Math.sin(5 * a - 1.2 + k * 0.37))
                            const x = cx + r * Math.cos(a) * 1.5, y = cy + r * Math.sin(a)
                            i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)
                        }
                        ctx.stroke()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.42 - height / 2
                text: "<i>kuruluyor</i>"
                textFormat: Text.StyledText
                color: "#F3F1EC"
                font.family: "Instrument Serif"
                font.pixelSize: 56
            }

            Text {
                id: tipText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40
                width: parent.width - 120
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: presentation.tips[presentation.tip]
                color: "#CFC9C2"
                font.family: "Instrument Serif"
                font.italic: true
                font.pixelSize: 24
                Behavior on opacity { NumberAnimation { duration: 280 } }
            }
        }
    }

    function onActivate() { }
    function onLeave() { }
}
