import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 20

    property var outputs: []          // niri msg -j outputs
    property string selected: ""
    property var draft: ({})          // name -> {mode, scale, x, y, vrr, off}
    property var before: ({})         // onay bekleyen değişiklikten önceki hâl
    property int countdown: 0

    readonly property var sel: outputs.find(o => o.name === selected) ?? null
    readonly property var cur: draft[selected] ?? null

    function modeString(m) { return m.width + "x" + m.height + "@" + (m.refresh_rate / 1000).toFixed(3) }
    function stateOf(o) {
        const m = o.current_mode !== null && o.modes[o.current_mode] ? o.modes[o.current_mode] : o.modes[0]
        return {
            mode: m ? modeString(m) : "",
            scale: o.logical ? o.logical.scale : 1,
            x: o.logical ? o.logical.x : 0,
            y: o.logical ? o.logical.y : 0,
            vrr: !!o.vrr_enabled,
            off: !o.logical
        }
    }
    function load() { reader.running = true }

    Process {
        id: reader
        running: true
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                let obj = {}
                try { obj = JSON.parse(text) } catch (e) { return }
                page.outputs = Object.values(obj).sort((a, b) => a.name.localeCompare(b.name))
                const d = {}
                for (const o of page.outputs) d[o.name] = page.stateOf(o)
                page.draft = d
                if (!page.selected && page.outputs.length) page.selected = page.outputs[0].name
            }
        }
    }

    function setDraft(key, value) {
        const d = Object.assign({}, draft)
        d[selected] = Object.assign({}, d[selected], { [key]: value })
        draft = d
    }

    function applyLive(state) {
        for (const name in state) {
            const s = state[name]
            const base = ["niri", "msg", "output", name]
            if (s.off) { Quickshell.execDetached(base.concat(["off"])); continue }
            Quickshell.execDetached(base.concat(["on"]))
            if (s.mode) Quickshell.execDetached(base.concat(["mode", s.mode]))
            Quickshell.execDetached(base.concat(["scale", String(s.scale)]))
            Quickshell.execDetached(base.concat(["position", "set", String(Math.round(s.x)), String(Math.round(s.y))]))
            Quickshell.execDetached(base.concat(["vrr", s.vrr ? "on" : "off"]))
        }
    }

    function apply() {
        const prev = {}
        for (const o of outputs) prev[o.name] = stateOf(o)
        before = prev
        applyLive(draft)
        countdown = 15
    }
    function keep() {
        countdown = 0
        NiriConf.set("outputs", Object.keys(draft).map(n => Object.assign({ name: n }, draft[n])))
        Qt.callLater(load)
    }
    function revert() {
        countdown = 0
        applyLive(before)
        Qt.callLater(load)
    }
    Timer {
        running: page.countdown > 0
        interval: 1000
        repeat: true
        onTriggered: { page.countdown -= 1; if (page.countdown === 0) page.revert() }
    }

    // Yerleşim
    Rectangle {
        id: canvasBox
        Layout.fillWidth: true
        implicitHeight: 260
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.03)
        border.color: Theme.dash

        // Tüm ekranları sığdıran ölçek
        readonly property var bounds: {
            let minX = 0, minY = 0, maxX = 1, maxY = 1
            for (const n in page.draft) {
                const o = page.outputs.find(x => x.name === n)
                if (!o || page.draft[n].off) continue
                const m = page.draft[n].mode.match(/^(\d+)x(\d+)/)
                const w = m ? m[1] / page.draft[n].scale : 1920, h = m ? m[2] / page.draft[n].scale : 1080
                minX = Math.min(minX, page.draft[n].x); minY = Math.min(minY, page.draft[n].y)
                maxX = Math.max(maxX, page.draft[n].x + w); maxY = Math.max(maxY, page.draft[n].y + h)
            }
            return { minX, minY, w: maxX - minX, h: maxY - minY }
        }
        readonly property real k: Math.min((width - 80) / bounds.w, (height - 60) / bounds.h)

        Repeater {
            model: page.outputs
            delegate: Rectangle {
                id: mon
                required property var modelData
                required property int index
                readonly property var st: page.draft[modelData.name] ?? { mode: "", scale: 1, x: 0, y: 0 }
                readonly property var dims: { const m = st.mode.match(/^(\d+)x(\d+)/); return m ? [m[1] / st.scale, m[2] / st.scale] : [1920, 1080] }
                readonly property bool on: page.selected === modelData.name
                visible: !st.off
                x: 40 + (st.x - canvasBox.bounds.minX) * canvasBox.k
                y: 30 + (st.y - canvasBox.bounds.minY) * canvasBox.k
                width: dims[0] * canvasBox.k
                height: dims[1] * canvasBox.k
                radius: 12
                color: on ? Theme.accent : Qt.rgba(1, 1, 1, 0.06)
                border.width: 2
                border.color: on ? Theme.accent : Qt.rgba(1, 1, 1, 0.2)
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.index + 1; color: mon.on ? Theme.accentInk : Theme.paper; font.family: Theme.serif; font.pixelSize: 34 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.name; color: mon.on ? Theme.accentInk : Theme.paper; font.family: Theme.mono; font.pixelSize: 10 }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    drag.target: page.outputs.length > 1 ? mon : null
                    onPressed: page.selected = mon.modelData.name
                    onReleased: {
                        if (page.outputs.length < 2) return
                        // Bırakılan konumu mantıksal piksele çevir, diğer ekranın kenarına yapıştır
                        let lx = (mon.x - 40) / canvasBox.k + canvasBox.bounds.minX
                        let ly = (mon.y - 30) / canvasBox.k + canvasBox.bounds.minY
                        for (const n in page.draft) {
                            if (n === mon.modelData.name || page.draft[n].off) continue
                            const o = page.draft[n]
                            const m = o.mode.match(/^(\d+)x(\d+)/)
                            const w = m ? m[1] / o.scale : 1920, h = m ? m[2] / o.scale : 1080
                            const snaps = [[o.x + w, lx], [o.x - mon.dims[0], lx]]
                            for (const [sx] of snaps) if (Math.abs(sx - lx) < 120) lx = sx
                            if (Math.abs(o.y - ly) < 120) ly = o.y
                        }
                        page.setDraft("x", Math.round(lx))
                        page.setDraft("y", Math.round(ly))
                    }
                }
            }
        }
        Text {
            anchors { right: parent.right; bottom: parent.bottom; margins: 12 }
            text: page.outputs.length > 1 ? "SÜRÜKLEYEREK DİZ" : ""
            color: Theme.muted
            font.family: Theme.mono
            font.pixelSize: 10
            font.letterSpacing: 1.4
        }
    }

    // Seçili ekran
    ColumnLayout {
        Layout.fillWidth: true
        visible: page.sel !== null && page.cur !== null
        spacing: 0
        SectionLabel { text: page.sel ? (page.sel.make + " " + page.sel.model).toUpperCase() : "" }
        DashLine { Layout.fillWidth: true }

        SettingRow {
            id: resRow
            label: "Çözünürlük"
            readonly property var sizes: page.sel ? [...new Set(page.sel.modes.map(m => m.width + "×" + m.height))] : []
            Segmented {
                visible: resRow.sizes.length <= 4
                mono: true
                options: resRow.sizes
                currentIndex: page.cur ? resRow.sizes.indexOf(page.cur.mode.split("@")[0].replace("x", "×")) : -1
                onPicked: i => {
                    const [w, h] = resRow.sizes[i].split("×").map(Number)
                    const best = page.sel.modes.filter(m => m.width === w && m.height === h).sort((a, b) => b.refresh_rate - a.refresh_rate)[0]
                    page.setDraft("mode", page.modeString(best))
                }
            }
            // Çok seçenek varsa: önceki / sonraki
            Row {
                visible: resRow.sizes.length > 4
                spacing: 8
                readonly property var sizes: resRow.sizes
                readonly property int idx: page.cur ? sizes.indexOf(page.cur.mode.split("@")[0].replace("x", "×")) : 0
                function pick(i) {
                    const [w, h] = sizes[i].split("×").map(Number)
                    const best = page.sel.modes.filter(m => m.width === w && m.height === h).sort((a, b) => b.refresh_rate - a.refresh_rate)[0]
                    page.setDraft("mode", page.modeString(best))
                }
                IconButton { icon: "arrow-left"; tooltip: "Daha büyük"; onClicked: parent.pick(Math.max(0, parent.idx - 1)) }
                Text { anchors.verticalCenter: parent.verticalCenter; text: parent.sizes[parent.idx] ?? ""; color: Theme.paper; font.family: Theme.mono; font.pixelSize: 14 }
                IconButton { icon: "arrow-right"; tooltip: "Daha küçük"; onClicked: parent.pick(Math.min(parent.sizes.length - 1, parent.idx + 1)) }
            }
        }
        SettingRow {
            id: rateRow
            label: "Yenileme hızı"
            readonly property var rates: {
                if (!page.sel || !page.cur) return []
                const [w, h] = page.cur.mode.split("@")[0].split("x").map(Number)
                return page.sel.modes.filter(m => m.width === w && m.height === h).sort((a, b) => a.refresh_rate - b.refresh_rate)
            }
            Segmented {
                mono: true
                options: rateRow.rates.slice(-4).map(m => Math.round(m.refresh_rate / 1000) + " Hz")
                currentIndex: rateRow.rates.slice(-4).findIndex(m => page.modeString(m) === page.cur?.mode)
                onPicked: i => page.setDraft("mode", page.modeString(rateRow.rates.slice(-4)[i]))
            }
        }
        SettingRow {
            id: scaleRow
            label: "Ölçek"
            sub: "Yazılar ve pencereler bu oranda büyür"
            readonly property var scales: [1, 1.25, 1.5, 1.75, 2]
            Segmented {
                mono: true
                options: scaleRow.scales.map(s => "%" + Math.round(s * 100))
                currentIndex: scaleRow.scales.indexOf(page.cur?.scale ?? 1)
                onPicked: i => page.setDraft("scale", scaleRow.scales[i])
            }
        }
        SettingRow {
            visible: page.sel?.vrr_supported ?? false
            label: "Değişken yenileme hızı (VRR)"
            sub: "Oyunlarda yırtılmayı önler"
            Toggle { checked: page.cur?.vrr ?? false; onToggled: page.setDraft("vrr", !page.cur.vrr) }
        }
        SettingRow {
            visible: page.outputs.length > 1
            label: "Bu ekranı kullan"
            Toggle { checked: !(page.cur?.off ?? false); onToggled: page.setDraft("off", !page.cur.off) }
        }
    }

    // Uygula / onay
    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        visible: page.countdown === 0
        PillButton { primary: true; label: "Uygula"; onClicked: page.apply() }
        PillButton { label: "Yenile"; icon: "restart"; onClicked: page.load() }
        Text {
            Layout.fillWidth: true
            text: "Onaylamazsan 15 saniye içinde eski ayara döner."
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
    }
    Rectangle {
        Layout.fillWidth: true
        visible: page.countdown > 0
        implicitHeight: 76
        radius: 18
        color: Qt.rgba(169 / 255, 199 / 255, 247 / 255, 0.1)
        border.color: Theme.sky
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: "Böyle kalsın mı? " + page.countdown + " sn sonra eski hâline döner."
                color: Theme.paper
                font.family: Theme.serif
                font.pixelSize: 22
            }
            PillButton { label: "Geri al"; onClicked: page.revert() }
            PillButton { primary: true; label: "Böyle kalsın"; onClicked: page.keep() }
        }
    }

    NiriStatus { Layout.fillWidth: true }
}
