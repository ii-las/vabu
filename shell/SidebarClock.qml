import QtQuick
import QtQuick.Layouts
import Quickshell

Card {
    id: root
    marks: true
    implicitHeight: col.implicitHeight + 26

    readonly property var days: ["PAZ", "PZT", "SAL", "ÇAR", "PER", "CUM", "CMT"]

    SystemClock {
        id: clock
        precision: Config.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 14
        anchors.topMargin: 14
        anchors.bottomMargin: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: Qt.formatTime(clock.date, Config.showSeconds ? "HH:mm:ss" : "HH:mm")
                color: Theme.paper
                font.family: Theme.serif
                font.pixelSize: Config.showSeconds ? 46 : 60
                font.letterSpacing: -0.5
            }
            Rectangle {
                implicitWidth: 50
                implicitHeight: 54
                radius: 12
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.22)
                Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.days[clock.date.getDay()]
                        color: Theme.muted
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: clock.date.getDate()
                        color: Theme.paper
                        font.family: Theme.serif
                        font.pixelSize: 24
                    }
                }
            }
        }

        // Gün yayı
        Canvas {
            id: arc
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            antialiasing: true

            readonly property real p: Sun.progress
            onPChanged: requestPaint()
            onWidthChanged: requestPaint()

            function bez(u) {
                const x0 = 6, x2 = width - 6, x1 = width / 2
                return {
                    x: (1 - u) * (1 - u) * x0 + 2 * (1 - u) * u * x1 + u * u * x2,
                    y: (1 - u) * (1 - u) * 30 + 2 * (1 - u) * u * -12 + u * u * 30
                }
            }

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                // ufuk
                ctx.strokeStyle = "rgba(243,241,236,0.25)"
                ctx.lineWidth = 1
                ctx.beginPath(); ctx.moveTo(0, 30.5); ctx.lineTo(width, 30.5); ctx.stroke()
                // yay (kesikli)
                ctx.setLineDash([2, 4])
                ctx.strokeStyle = "rgba(243,241,236,0.35)"
                ctx.beginPath(); ctx.moveTo(6, 30); ctx.quadraticCurveTo(width / 2, -12, width - 6, 30); ctx.stroke()
                ctx.setLineDash([])
                const night = p < 0 || p > 1
                const t = Math.min(1, Math.max(0, p))
                // geçilen yol
                if (!night) {
                    ctx.strokeStyle = "#F2B48A"
                    ctx.lineWidth = 1.6
                    ctx.beginPath()
                    for (let i = 0; i <= 32; i++) {
                        const q = bez((i / 32) * t)
                        i ? ctx.lineTo(q.x, q.y) : ctx.moveTo(q.x, q.y)
                    }
                    ctx.stroke()
                }
                // güneş
                const s = bez(t)
                ctx.beginPath()
                ctx.arc(s.x, s.y, 5, 0, Math.PI * 2)
                ctx.fillStyle = night ? "#16161B" : "#F2B48A"
                ctx.fill()
                ctx.strokeStyle = "#F2B48A"
                ctx.lineWidth = 1.6
                ctx.stroke()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "↑ " + Sun.sunriseText; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Text { text: Sun.night ? "GECE" : "GÜN YAYI"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text { text: Sun.sunsetText + " ↓"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10 }
        }
    }
}
