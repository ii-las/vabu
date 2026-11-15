import QtQuick

Item {
    id: root
    property int count: 0
    property bool error: false
    property bool busy: false
    implicitWidth: 500
    implicitHeight: 500

    signal burstDone()

    onCountChanged: canvas.requestPaint()
    onErrorChanged: canvas.requestPaint()

    // Açılışta haritanın belirmesi: soluk halkalar dışa doğru çizilip geri çekilir
    property real intro: 0
    onIntroChanged: canvas.requestPaint()
    SequentialAnimation on intro {
        running: true
        NumberAnimation { from: 0; to: 6; duration: 900; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 250 }
        NumberAnimation { to: 0; duration: 700; easing.type: Easing.InOutCubic }
    }

    // Doğrulanırken halkalar hafifçe nefes alır
    property real pulse: 0
    SequentialAnimation on pulse {
        running: root.busy
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 700; easing.type: Easing.InOutSine }
    }
    onPulseChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        function ring(ctx, i) {
            const cx = width / 2, cy = height / 2
            const r0 = 52 + i * 15 + root.pulse * 3
            ctx.beginPath()
            for (let s = 0; s <= 90; s++) {
                const t = (s / 90) * Math.PI * 2
                const r = r0 * (1 + 0.07 * Math.sin(3 * t + i * 0.7) + 0.04 * Math.sin(5 * t - i * 0.4))
                const x = cx + r * Math.cos(t), y = cy + r * Math.sin(t)
                s ? ctx.lineTo(x, y) : ctx.moveTo(x, y)
            }
            ctx.stroke()
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const n = Math.min(14, root.count)
            const warm = root.error ? "rgba(247,168,168,0.55)" : "rgba(246,220,196,0.55)"
            const head = root.error ? "#F7A8A8" : "#8EF0C6"
            if (n === 0 && root.intro > 0) {
                const full = Math.floor(root.intro)
                for (let i = 0; i <= full && i < 6; i++) {
                    const a = i < full ? 0.28 : (root.intro - full) * 0.28
                    ctx.lineWidth = 1.2
                    ctx.strokeStyle = "rgba(246,220,196," + (a * (1 - i / 7)).toFixed(3) + ")"
                    ring(ctx, i)
                }
            }
            ctx.lineWidth = 1.4
            ctx.strokeStyle = warm
            for (let i = 0; i < n - 1; i++) ring(ctx, i)
            if (n > 0) {
                ctx.lineWidth = 2.2
                ctx.strokeStyle = head
                ring(ctx, n - 1)
            }
            // çekirdek
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, 34, 0, Math.PI * 2)
            ctx.fillStyle = root.error ? "#F7A8A8" : (n > 0 ? "#8EF0C6" : "rgba(243,241,236,0.16)")
            ctx.fill()
        }
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -3
        text: "v"
        color: root.count > 0 || root.error ? Theme.mintInk : Theme.paper
        font.family: Theme.serif
        font.italic: true
        font.pixelSize: 40
    }

    // Hatalı şifrede kısa titreme
    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "x"; by: -12; duration: 50 }
        NumberAnimation { target: root; property: "x"; by: 24; duration: 70 }
        NumberAnimation { target: root; property: "x"; by: -20; duration: 70 }
        NumberAnimation { target: root; property: "x"; by: 8; duration: 60 }
    }
    function shakeIt() { shake.start() }

    // Doğru şifre: halkalar dışa açılıp kaybolur, sonra kilit kalkar
    ParallelAnimation {
        id: burst
        NumberAnimation { target: root; property: "scale"; to: 1.7; duration: 460; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 460; easing.type: Easing.OutCubic }
        onFinished: root.burstDone()
    }
    function burstIt() { burst.start() }
}
