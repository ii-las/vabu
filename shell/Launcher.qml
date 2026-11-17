import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Başlatıcı: ara, kur, komut, hesap. Önek yazarak kip değişir: "kur:", ">" ya da "=".
OverlayWindow {
    id: root
    open: Ui.launcherOpen
    onDismissed: Ui.launcherOpen = false
    WlrLayershell.namespace: "vabu-launcher"

    property int selected: 0
    property string mode: "search"
    readonly property string query: input.text
    readonly property var modes: [
        { k: "search",  label: Lang.t("Ara"),   hint: Lang.t("Uygulama ara") },
        { k: "windows", label: Lang.t("Pencereler"), hint: Lang.t("Açık pencere ara") },
        { k: "install", label: Lang.t("Kur"),   hint: Lang.t("Kurulacak uygulamanın adı") },
        { k: "command", label: Lang.t("Komut"), hint: Lang.t("Komut ara") },
        { k: "calc",    label: Lang.t("Hesap"), hint: "12 × 8" }
    ]
    readonly property var modeInfo: modes.find(m => m.k === mode) ?? modes[0]

    function setMode(m) {
        mode = m
        input.forceActiveFocus()
    }

    readonly property var commands: [
        { icon: "system_update_alt",  name: Lang.t("Sistemi güncelle"),    sub: "",                                   run: () => Ui.terminal(["vabu", "update"]) },
        { icon: "memory",             name: Lang.t("Sürücüler"),           sub: "",                                   run: () => Ui.settings("drivers") },
        { icon: "history",            name: Lang.t("Geri alma noktaları"), sub: "",                                   run: () => Ui.settings("updates") },
        { icon: "screenshot_region",  name: Lang.t("Ekran görüntüsü"),     sub: "Print",                              run: () => Ui.screenshot() },
        { icon: "overview_key",       name: Lang.t("Genel bakış"),         sub: "Super + O",                          run: () => Niri.toggleOverview() },
        { icon: "keyboard",           name: Lang.t("Kısayollar"),          sub: "Super + Shift + /",                  run: () => { Ui.shortcutsOpen = true } },
        { icon: "settings",           name: Lang.t("Ayarlar"),             sub: "Super + ,",                          run: () => Ui.settings() },
        { icon: "lock",               name: Lang.t("Ekranı kilitle"),      sub: "Super + Alt + L",                    run: () => Ui.lock() },
        { icon: "bedtime",            name: Lang.t("Uyku"),                sub: "",                                   run: () => Ui.suspend() },
        { icon: "logout",             name: Lang.t("Oturumu kapat"),       sub: "",                                   run: () => Niri.quit() },
        { icon: "restart_alt",        name: Lang.t("Yeniden başlat"),      sub: "",                                   run: () => Ui.run(["systemctl", "reboot"]) },
        { icon: "power_settings_new", name: Lang.t("Kapat"),               sub: "",                                   run: () => Ui.run(["systemctl", "poweroff"]) }
    ]

    readonly property var calcResult: {
        if (mode !== "calc") return null
        const expr = query.replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/")
        if (!/^[\d\s+\-*/().%^]+$/.test(expr) || !expr.trim()) return null
        try {
            const v = Function("return (" + expr.replace(/\^/g, "**") + ")")()
            return Number.isFinite(v) ? Math.round(v * 1e10) / 1e10 : null
        } catch (e) { return null }
    }

    readonly property var items: {
        if (mode === "search") return Apps.search(query)
        if (mode === "windows") return Apps.searchWindows(query)
        if (mode === "command") {
            const q = query.toLowerCase()
            return commands.filter(c => !q || c.name.toLowerCase().includes(q) || c.sub.toLowerCase().includes(q)).slice(0, 8)
        }
        if (mode === "install") return Packages.results.slice(0, 8)
        return []
    }

    onModeChanged: {
        selected = 0
        if (mode === "install") Packages.search(query)
    }
    onQueryChanged: {
        selected = 0
        if (mode === "install") Packages.search(query)
    }
    onOpenChanged: {
        if (!open) return
        input.text = ""
        mode = Ui.launcherMode
        Ui.launcherMode = "search"
        selected = 0
        input.forceActiveFocus()
    }

    function activate(i) {
        const it = items[i]
        if (mode === "calc") {
            if (calcResult !== null) Quickshell.execDetached(["wl-copy", String(calcResult)])
        } else if (!it) {
            return
        } else if (mode === "search") {
            Apps.launch(it)
        } else if (mode === "windows") {
            Niri.focusWindow(it.id)
        } else if (mode === "command") {
            Ui.launcherOpen = false
            it.run()
            return
        } else if (mode === "install") {
            if (!it.installed && Packages.states[it.key] !== "installing") Packages.install(it)
            return   // kurulum sürerken başlatıcı açık kalır
        }
        Ui.launcherOpen = false
    }

    Card {
        id: panel
        tint: Theme.panelDeep
        radius: Theme.radiusPanel
        shadow: true
        width: Math.min(640, parent.width - 40)
        x: Math.round((parent.width - width) / 2)
        y: Math.round(parent.height * 0.2)
        height: content.implicitHeight
        Behavior on height {
            enabled: root.shown > 0.9
            NumberAnimation { duration: Config.reducedMotion ? 0 : 240; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
        }

        opacity: Math.min(1, root.shown * 1.5)
        transform: [
            Scale { origin.x: panel.width / 2; origin.y: 0; xScale: 0.96 + 0.04 * root.shown; yScale: 0.96 + 0.04 * root.shown },
            Translate { y: -14 * (1 - root.shown) }
        ]

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // panele tıklama kapatmasın

        Item {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 0

                // Arama satırı
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    Layout.leftMargin: 20
                    Layout.rightMargin: 16
                    spacing: 12

                    Icon { name: "search"; color: Theme.soft; size: 22 }

                    Rectangle {
                        visible: root.mode !== "search"
                        implicitHeight: 28
                        implicitWidth: modeLabel.implicitWidth + 20
                        radius: 9
                        color: Theme.accent
                        Text { textFormat: Text.PlainText;
                            id: modeLabel
                            anchors.centerIn: parent
                            text: root.modeInfo.label
                            color: Theme.accentInk
                            font.family: Theme.sans
                            font.pixelSize: Theme.textSmall
                            font.weight: Font.DemiBold
                        }
                    }

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.paper
                        font.family: Theme.sans
                        font.pixelSize: Math.round((20) * Config.textScale)
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentInk
                        clip: true
                        onTextChanged: {
                            if (root.mode !== "search") return
                            const m = text.match(/^(kur:|>|=)\s*/i)
                            if (!m) return
                            const p = m[1].toLowerCase()
                            root.mode = p === "kur:" ? "install" : p === ">" ? "command" : "calc"
                            text = text.slice(m[0].length)
                        }
                        Text { textFormat: Text.PlainText;
                            visible: !input.text
                            text: root.modeInfo.hint
                            color: Theme.faint
                            font: input.font
                        }
                        Keys.onPressed: event => {
                            const n = root.items.length
                            if (event.key === Qt.Key_Escape) {
                                if (root.mode !== "search" && !input.text) root.mode = "search"
                                else Ui.launcherOpen = false
                                event.accepted = true
                            }
                            else if (event.key === Qt.Key_Backspace && !input.text && root.mode !== "search") { root.mode = "search"; event.accepted = true }
                            else if (event.key === Qt.Key_Down) { root.selected = n ? (root.selected + 1) % n : 0; event.accepted = true }
                            else if (event.key === Qt.Key_Up) { root.selected = n ? (root.selected - 1 + n) % n : 0; event.accepted = true }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.activate(root.selected); event.accepted = true }
                            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                const order = root.modes.map(m => m.k)
                                const step = event.key === Qt.Key_Backtab ? order.length - 1 : 1
                                root.mode = order[(Math.max(0, order.indexOf(root.mode)) + step) % order.length]
                                event.accepted = true
                            }
                        }
                    }

                    Spinner { visible: root.mode === "install" && Packages.busy; size: 18; color: Theme.muted }
                }

                DashLine { Layout.fillWidth: true }

                // Hesap
                ColumnLayout {
                    visible: root.mode === "calc"
                    Layout.fillWidth: true
                    Layout.margins: 20
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                    spacing: 2
                    Text { textFormat: Text.PlainText;
                        text: root.calcResult !== null ? String(root.calcResult).replace(".", ",") : "Bir işlem yaz"
                        color: root.calcResult !== null ? Theme.paper : Theme.faint
                        font.family: Theme.sans
                        font.pixelSize: Math.round((root.calcResult !== null ? 38 : 15) * Config.textScale)
                        font.weight: root.calcResult !== null ? Font.Light : Font.Normal
                        font.features: ({ "tnum": 1 })
                    }
                }

                // Liste
                Item {
                    id: listArea
                    visible: root.mode !== "calc"
                    Layout.fillWidth: true
                    Layout.margins: 8
                    implicitHeight: heading.height + list.height

                    // Seçim vurgusu: satırdan satıra kayar
                    Rectangle {
                        visible: root.items.length > 0
                        y: heading.height + root.selected * 54
                        width: parent.width
                        height: 52
                        radius: Theme.radiusRow
                        color: Theme.well
                        Behavior on y { NumberAnimation { duration: Config.reducedMotion ? 0 : 130; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }
                    }

                    Item {
                        id: heading
                        readonly property bool on: root.mode === "search" && !root.query && root.items.length > 0
                        width: parent.width
                        height: on ? 30 : 0
                        Text { textFormat: Text.PlainText;
                            visible: heading.on
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: Lang.t("Sık kullanılanlar")
                            color: Theme.muted
                            font.family: Theme.sans
                            font.pixelSize: Theme.textSmall
                            font.weight: Font.Medium
                        }
                    }

                    Column {
                        id: list
                        y: heading.height
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: root.items
                            delegate: LauncherRow {
                                required property var modelData
                                required property int index
                                width: list.width
                                mode: root.mode
                                item: modelData
                                selected: root.selected === index
                                onHovered: root.selected = index
                                onActivated: root.activate(index)
                            }
                        }

                        Text { textFormat: Text.PlainText;
                            visible: root.items.length === 0
                            width: parent.width
                            height: 64
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: root.mode === "install"
                                ? (root.query.length < 2 ? "Fedora, RPM Fusion ve Flathub'da aranır"
                                    : Packages.busy ? Lang.t("Aranıyor…") : Lang.t("Bir şey bulunamadı"))
                                : Lang.t("Bir şey bulunamadı")
                            color: Theme.muted
                            font.family: Theme.sans
                            font.pixelSize: Theme.textSmall
                        }
                    }
                }

                DashLine { Layout.fillWidth: true }

                // Alt satır: kipler ve tuş ipuçları
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    Layout.leftMargin: 10
                    Layout.rightMargin: 18
                    spacing: 2

                    Repeater {
                        model: root.modes
                        delegate: Rectangle {
                            id: tab
                            required property var modelData
                            readonly property bool isOn: root.mode === modelData.k
                            implicitHeight: 28
                            implicitWidth: tabLabel.implicitWidth + 20
                            radius: 9
                            color: isOn ? Theme.well : (tabMouse.containsMouse ? Theme.hover : "transparent")
                            Text { textFormat: Text.PlainText;
                                id: tabLabel
                                anchors.centerIn: parent
                                text: tab.modelData.label
                                color: tab.isOn ? Theme.paper : Theme.muted
                                font.family: Theme.sans
                                font.pixelSize: Theme.textSmall
                                font.weight: tab.isOn ? Font.DemiBold : Font.Medium
                            }
                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setMode(tab.modelData.k)
                            }
                        }
                    }
                }
            }
        }
    }
}
