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
    property string previewToken: ""
    property string previewError: ""
    readonly property bool previewBusy: preview.running || finishPreview.running
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

    function apply() {
        if (previewBusy || previewToken !== "") return
        previewError = ""
        preview.command = ["/usr/libexec/vabu/display-preview", "preview", JSON.stringify(draft)]
        preview.running = true
    }
    function keep() { finish("keep") }
    function revert() { finish("revert") }
    function finish(action) {
        if (!previewToken || previewBusy) return
        finishPreview.action = action
        finishPreview.command = ["/usr/libexec/vabu/display-preview", action, previewToken]
        finishPreview.running = true
    }
    Process {
        id: preview
        stdout: StdioCollector { id: previewOut }
        stderr: StdioCollector { id: previewErr }
        onExited: code => {
            if (code === 0) {
                page.previewToken = previewOut.text.trim()
                page.countdown = 15
            } else page.previewError = previewErr.text.trim() || "Ekran ayarı uygulanamadı."
        }
    }
    Process {
        id: finishPreview
        property string action: ""
        stderr: StdioCollector { id: finishErr }
        onExited: code => {
            if (code === 0 && action === "keep")
                NiriConf.set("outputs", Object.keys(page.draft).map(n => Object.assign({ name: n }, page.draft[n])))
            else if (code !== 0) page.previewError = finishErr.text.trim() || "Önizleme süresi dolmuş olabilir; ekranları yeniden denetle."
            page.previewToken = ""
            page.countdown = 0
            page.load()
        }
    }
    // Bu sayaç yalnızca görseldir. Ayrı koruyucu süreç sayfa veya uygulama kapansa da geri alır.
    Timer {
        running: page.countdown > 0
        interval: 1000
        repeat: true
        onTriggered: { page.countdown -= 1; if (page.countdown === 0) page.revert() }
    }
    Text {
        Layout.fillWidth: true
        visible: page.previewError !== ""
        text: page.previewError
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Theme.danger
        font.family: Theme.sans
        font.pixelSize: Math.round((13) * Config.textScale)
    }

    // Yerleşim
    Rectangle {
        id: canvasBox
        Layout.fillWidth: true
        implicitHeight: 240
        radius: Theme.radiusTile
        color: Theme.group
        border.width: 1
        border.color: Theme.groupEdge

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
                readonly property bool isOn: page.selected === modelData.name
                visible: !st.off
                x: 40 + (st.x - canvasBox.bounds.minX) * canvasBox.k
                y: 30 + (st.y - canvasBox.bounds.minY) * canvasBox.k
                width: dims[0] * canvasBox.k
                height: dims[1] * canvasBox.k
                radius: 12
                color: isOn ? Theme.accent : Theme.well
                border.width: 1
                border.color: isOn ? Theme.accent : Theme.line
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text { textFormat: Text.PlainText; anchors.horizontalCenter: parent.horizontalCenter; text: mon.index + 1; color: mon.isOn ? Theme.accentInk : Theme.paper; font.family: Theme.sans; font.weight: Font.DemiBold; font.pixelSize: Math.round((26) * Config.textScale)}
                    Text { textFormat: Text.PlainText; anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.name; color: mon.isOn ? Theme.accentInk : Theme.soft; font.family: Theme.sans; font.pixelSize: Math.round((12) * Config.textScale)}
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    enabled: !page.previewBusy && page.previewToken === ""
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
        Text { textFormat: Text.PlainText;
            anchors { right: parent.right; bottom: parent.bottom; margins: 12 }
            text: page.outputs.length > 1 ? "Ekranları sürükleyerek diz" : ""
            color: Theme.faint
            font.family: Theme.sans
            font.pixelSize: Math.round((12) * Config.textScale)
        }
    }

    // Seçili ekran
    Group {
        enabled: !page.previewBusy && page.previewToken === ""
        visible: page.sel !== null && page.cur !== null
        title: page.sel ? (page.sel.make + " " + page.sel.model).trim() : ""

        SettingRow {
            id: resRow
            label: Lang.t("Çözünürlük")
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
                IconButton { implicitWidth: 34; implicitHeight: 34; icon: "chevron_left"; tooltip: Lang.t("Daha büyük"); onClicked: parent.pick(Math.max(0, parent.idx - 1)) }
                Text { textFormat: Text.PlainText; anchors.verticalCenter: parent.verticalCenter; text: parent.sizes[parent.idx] ?? ""; color: Theme.paper; font.family: Theme.sans; font.weight: Font.Medium; font.pixelSize: Math.round((14) * Config.textScale); font.features: ({ "tnum": 1 }) }
                IconButton { implicitWidth: 34; implicitHeight: 34; icon: "chevron_right"; tooltip: Lang.t("Daha küçük"); onClicked: parent.pick(Math.min(parent.sizes.length - 1, parent.idx + 1)) }
            }
        }
        SettingRow {
            id: rateRow
            label: Lang.t("Yenileme hızı")
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
            label: Lang.t("Ölçek")
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
            label: Lang.t("Değişken yenileme hızı (VRR)")
            Toggle { checked: page.cur?.vrr ?? false; onToggled: page.setDraft("vrr", !page.cur.vrr) }
        }
        SettingRow {
            visible: page.outputs.length > 1
            label: Lang.t("Bu ekranı kullan")
            Toggle { checked: !(page.cur?.off ?? false); onToggled: page.setDraft("off", !page.cur.off) }
        }
    }

    Group {
        title: Lang.t("Gece ışığı")
        SettingRow {
            label: Lang.t("Gece ışığı")
            sub: Config.nightLight ? Lang.t("Gün batımından gün doğumuna") : ""
            Toggle { checked: Config.nightLight; onToggled: Config.set("nightLight", !Config.nightLight) }
        }
    }

    Group {
        title: Lang.t("Ekran düzeni profilleri")
        note: Lang.t("Profili yükledikten sonra Uygula düğmesiyle dene. Onaylanmayan değişiklikler otomatik geri alınır. Bağlı ekran adları uyuşmalıdır.")
        Field { id: profileName; Layout.fillWidth: true; placeholder: Lang.t("Profil adı (ör. Masa, Sunum)") }
        PillButton {
            label: Lang.t("Bu düzeni profil olarak sakla")
            enabled: !page.previewBusy && page.previewToken === "" && profileName.text.trim().length > 0 && profileName.text.trim().length <= 40 && page.outputs.length > 0
            onClicked: {
                const profile = {name:profileName.text.trim(), outputs:JSON.parse(JSON.stringify(page.draft))}
                Config.set("displayProfiles", (Config.values.displayProfiles ?? []).filter(p => p.name !== profile.name).concat([profile]).slice(-12))
                profileName.text = ""
            }
        }
        Repeater {
            model: Config.values.displayProfiles ?? []
            delegate: SettingRow {
                required property var modelData
                label: modelData.name
                PillButton {
                    label: Lang.t("Yükle"); enabled: !page.previewBusy && page.previewToken === ""
                    onClicked: {
                        const expected = Object.keys(modelData.outputs).sort().join("\n")
                        const actual = page.outputs.map(o => o.name).sort().join("\n")
                        if (expected !== actual) { page.previewError = "Bu profilin ekranları bağlı ekranlarla uyuşmuyor."; return }
                        page.draft = JSON.parse(JSON.stringify(modelData.outputs))
                    }
                }
                IconButton { icon: "delete"; tooltip: Lang.t("Profili sil"); onClicked: Config.set("displayProfiles", (Config.values.displayProfiles ?? []).filter(p => p.name !== modelData.name)) }
            }
        }
    }

    // Uygula / onay
    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        visible: page.previewToken === ""
        PillButton { primary: true; label: Lang.t("Uygula"); enabled: !page.previewBusy; onClicked: page.apply() }
        PillButton { label: Lang.t("Yenile"); icon: "refresh"; enabled: !page.previewBusy; onClicked: page.load() }
        Text { textFormat: Text.PlainText;
            Layout.fillWidth: true
            text: Lang.t("Onaylamazsan 15 saniye içinde eski ayara döner.")
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: Math.round((12) * Config.textScale)
            wrapMode: Text.Wrap
        }
    }
    Rectangle {
        Layout.fillWidth: true
        visible: page.previewToken !== ""
        implicitHeight: 68
        radius: Theme.radiusTile
        color: Theme.well
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.5)
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                text: Lang.t("Böyle kalsın mı? ") + page.countdown + Lang.t(" sn sonra eski hâline döner.")
                color: Theme.paper
                font.family: Theme.sans
                font.weight: Font.DemiBold
                font.pixelSize: Math.round((15) * Config.textScale)
            }
            PillButton { label: Lang.t("Geri al"); enabled: !page.previewBusy; onClicked: page.revert() }
            PillButton { primary: true; label: Lang.t("Böyle kalsın"); enabled: !page.previewBusy; onClicked: page.keep() }
        }
    }

    NiriStatus { Layout.fillWidth: true }
}
