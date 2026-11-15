import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root
    visible: Ui.launcherOpen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "vabu-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int selected: 0

    // Kip: "kur:", ">" ya da "=" yazılınca öneki metinden alıp kipe çeviririz;
    // önek ekranda soluk renkle ayrı gösterilir. Boşken geri silme kipten çıkar.
    property string mode: "search"
    readonly property string query: input.text
    readonly property var prefixes: ({ "install": "Kur:", "command": ">", "calc": "=" })

    function setMode(m) {
        mode = m
        input.forceActiveFocus()
    }

    readonly property var commands: [
        { icon: "update",   name: "Sistemi güncelle",        sub: "dnf + Flatpak · öncesinde geri alma noktası", run: () => Ui.terminal(["vabu", "update"]) },
        { icon: "chip",     name: "Sürücüler",               sub: "Ekran kartı, codec'ler",                      run: () => Ui.settings("drivers") },
        { icon: "restart",  name: "Geri alma noktaları",     sub: "vabu snapshots",                              run: () => Ui.settings("updates") },
        { icon: "camera",   name: "Ekran görüntüsü",         sub: "Print",                                       run: () => Niri.action(["screenshot"]) },
        { icon: "keyboard", name: "Kısayollar",              sub: "Super + Shift + /",                           run: () => { Ui.shortcutsOpen = true } },
        { icon: "sliders",  name: "Ayarlar",                 sub: "Super + ,",                                   run: () => Ui.settings() },
        { icon: "lock",     name: "Ekranı kilitle",          sub: "Super + Alt + L",                             run: () => Ui.lock() },
        { icon: "logout",   name: "Oturumu kapat",           sub: "",                                            run: () => Niri.quit() },
        { icon: "restart",  name: "Yeniden başlat",          sub: "",                                            run: () => Ui.run(["systemctl", "reboot"]) },
        { icon: "power",    name: "Kapat",                   sub: "",                                            run: () => Ui.run(["systemctl", "poweroff"]) }
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
        if (mode === "command") {
            const q = query.toLowerCase()
            return commands.filter(c => !q || c.name.toLowerCase().includes(q) || c.sub.toLowerCase().includes(q))
        }
        if (mode === "install") return Packages.results
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
    onVisibleChanged: {
        if (visible) {
            input.text = ""
            mode = Ui.launcherMode
            Ui.launcherMode = "search"
            input.forceActiveFocus()
        }
    }

    function activate(i) {
        const it = items[i]
        if (mode === "calc") {
            if (calcResult !== null) Quickshell.execDetached(["wl-copy", String(calcResult)])
        } else if (!it) {
            return
        } else if (mode === "search") {
            Apps.launch(it)
        } else if (mode === "command") {
            it.run()
        } else if (mode === "install") {
            if (!it.installed && Packages.states[it.key] !== "installing") Packages.install(it)
            return   // kurulum sürerken başlatıcı açık kalır
        }
        Ui.launcherOpen = false
    }

    // Dışarı tıklayınca kapan
    MouseArea {
        anchors.fill: parent
        onClicked: Ui.launcherOpen = false
    }

    Card {
        id: panel
        strong: true
        radius: Theme.radiusPanel
        width: 680
        x: (parent.width - width) / 2
        y: parent.height * 0.2
        height: content.implicitHeight + 20
        marks: true

        // Açılış hareketi
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // panele tıklama kapatmasın

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 10
            spacing: 0

            // Arama satırı
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 12

                Text {
                    visible: root.mode !== "search"
                    text: root.prefixes[root.mode] ?? ""
                    color: Theme.faint
                    font.family: Theme.serif
                    font.pixelSize: 32
                }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.paper
                    font.family: Theme.serif
                    font.pixelSize: 32
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
                    Text {
                        visible: !input.text
                        text: root.mode === "install" ? "uygulama adı" : root.mode === "command" ? "komut" : root.mode === "calc" ? "12 × 8" : "Ne arıyorsun?"
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
                        else if (event.key === Qt.Key_Tab) {
                            const order = ["search", "install", "command"]
                            root.mode = order[(Math.max(0, order.indexOf(root.mode)) + 1) % order.length]
                            event.accepted = true
                        }
                    }
                }
                Icon { name: "search"; color: Theme.soft; size: 24; stroke: 1.6 }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(1, 1, 1, 0.1) }

            // Ara kipi, boş: öneri kartları
            GridLayout {
                visible: root.mode === "search" && !root.query
                Layout.fillWidth: true
                Layout.margins: 8
                Layout.topMargin: 12
                columns: 3
                rowSpacing: 8
                columnSpacing: 8

                LauncherCard {
                    Layout.fillWidth: true
                    highlight: true
                    glyph: "download"
                    title: "Uygulama kur"
                    subtitle: "Fedora, RPM Fusion, Flathub"
                    onActivated: root.setMode("install")
                }
                Repeater {
                    model: Apps.frequent
                    delegate: LauncherCard {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        entry: modelData
                        title: modelData.name
                        subtitle: modelData.genericName || ""
                        selected: root.selected === index
                        onActivated: { Apps.launch(modelData); Ui.launcherOpen = false }
                    }
                }
            }

            // Hesap makinesi
            ColumnLayout {
                visible: root.mode === "calc"
                Layout.fillWidth: true
                Layout.margins: 18
                spacing: 4
                Text {
                    text: root.calcResult !== null ? "= " + String(root.calcResult).replace(".", ",") : "…"
                    color: Theme.paper
                    font.family: Theme.serif
                    font.pixelSize: 44
                }
                Text {
                    text: "⏎ SONUCU KOPYALA"
                    color: Theme.muted
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }
            }

            // Liste (arama sonuçları, kur, komut)
            ColumnLayout {
                visible: root.mode !== "calc" && !(root.mode === "search" && !root.query)
                Layout.fillWidth: true
                Layout.margins: 6
                Layout.topMargin: 10
                spacing: 2

                Text {
                    visible: root.mode === "install" && root.items.length === 0
                    Layout.margins: 12
                    text: root.query.length < 2 ? "Kurmak istediğin uygulamanın adını yaz."
                        : Packages.busy ? "Fedora, RPM Fusion ve Flathub'da aranıyor…" : "Bir şey bulunamadı."
                    color: Theme.muted
                    font.family: Theme.serif
                    font.pixelSize: 20
                }

                Repeater {
                    model: root.items
                    delegate: LauncherRow {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        mode: root.mode
                        item: modelData
                        selected: root.selected === index
                        onHovered: root.selected = index
                        onActivated: root.activate(index)
                    }
                }
            }

            // Kip seçici
            Rectangle { Layout.fillWidth: true; Layout.topMargin: 6; implicitHeight: 1; color: Qt.rgba(1, 1, 1, 0.08) }
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 8
                Layout.bottomMargin: 0
                spacing: 6
                Repeater {
                    model: [
                        { k: "search", label: "ARA" },
                        { k: "install", label: "KUR:  uygulama" },
                        { k: "command", label: ">  KOMUT" },
                        { k: "calc", label: "=  HESAP" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: root.mode === modelData.k
                        implicitHeight: 32
                        implicitWidth: chip.implicitWidth + 24
                        radius: 16
                        color: on ? Theme.paper : "transparent"
                        border.color: on ? Theme.paper : Qt.rgba(1, 1, 1, 0.16)
                        Text {
                            id: chip
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: parent.on ? "#16161B" : Theme.soft
                            font.family: Theme.mono
                            font.pixelSize: 11
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode(parent.modelData.k)
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.mode === "install" ? "⏎ KUR · TAB KİP" : root.mode === "command" ? "⏎ ÇALIŞTIR" : "⏎ AÇ · TAB KİP"
                    color: Theme.muted
                    font.family: Theme.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
