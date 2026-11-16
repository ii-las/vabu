import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    spacing: 24

    readonly property var catalog: [
        { layout: "tr", variant: "", name: Lang.t("Türkçe Q") },
        { layout: "tr", variant: "f", name: Lang.t("Türkçe F") },
        { layout: "us", variant: "", name: Lang.t("İngilizce (ABD)") },
        { layout: "gb", variant: "", name: Lang.t("İngilizce (BK)") },
        { layout: "de", variant: "", name: Lang.t("Almanca") },
        { layout: "fr", variant: "", name: Lang.t("Fransızca") },
        { layout: "es", variant: "", name: Lang.t("İspanyolca") },
        { layout: "it", variant: "", name: Lang.t("İtalyanca") },
        { layout: "ru", variant: "", name: Lang.t("Rusça") },
        { layout: "ara", variant: "", name: Lang.t("Arapça") },
        { layout: "az", variant: "", name: Lang.t("Azerice") }
    ]

    // niri.json'daki "us,tr" + ",f" → [{layout, variant}]
    readonly property var current: {
        const ls = NiriConf.xkbLayout.split(","), vs = NiriConf.xkbVariant.split(",")
        return ls.filter(l => l).map((l, i) => ({ layout: l, variant: vs[i] || "" }))
    }
    function nameOf(e) { return (catalog.find(c => c.layout === e.layout && c.variant === e.variant) || { name: e.layout + (e.variant ? " (" + e.variant + ")" : "") }).name }
    function save(list) {
        NiriConf.setMany({
            xkbLayout: list.map(e => e.layout).join(","),
            xkbVariant: list.some(e => e.variant) ? list.map(e => e.variant).join(",") : ""
        })
    }

    readonly property var switches: [
        { opt: "grp:alt_shift_toggle", name: "Alt + Shift" },
        { opt: "grp:ctrl_shift_toggle", name: "Ctrl + Shift" },
        { opt: "grp:caps_toggle", name: "Caps Lock" }
    ]

    Group {
        title: Lang.t("Klavye düzenleri")
        Repeater {
            model: page.current
            delegate: SettingRow {
                required property var modelData
                required property int index
                label: page.nameOf(modelData)
                sub: index === 0 ? "Varsayılan" : ""
                IconButton {
                    visible: index > 0
                    implicitWidth: 36; implicitHeight: 36
                    icon: "arrow_upward"; iconColor: Theme.soft; tooltip: Lang.t("Yukarı taşı")
                    onClicked: { const l = page.current.slice(); [l[index - 1], l[index]] = [l[index], l[index - 1]]; page.save(l) }
                }
                IconButton {
                    visible: page.current.length > 1
                    implicitWidth: 36; implicitHeight: 36
                    icon: "close"; iconColor: Theme.soft; tooltip: Lang.t("Kaldır")
                    onClicked: page.save(page.current.filter((_, i) => i !== index))
                }
            }
        }
        Flow {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 8
            Repeater {
                model: page.catalog.filter(c => !page.current.some(e => e.layout === c.layout && e.variant === c.variant))
                delegate: PillButton {
                    required property var modelData
                    implicitHeight: 36
                    icon: "add"
                    label: modelData.name
                    onClicked: page.save(page.current.concat([{ layout: modelData.layout, variant: modelData.variant }]))
                }
            }
        }
    }

    Group {
        SettingRow {
            visible: page.current.length > 1
            label: Lang.t("Düzenler arasında geçiş")
            Segmented {
                options: page.switches.map(s => s.name)
                currentIndex: page.switches.findIndex(s => NiriConf.xkbOptions.includes(s.opt))
                onPicked: i => NiriConf.set("xkbOptions", page.switches[i].opt)
            }
        }
        SettingRow {
            label: Lang.t("Doğal kaydırma")
            Toggle { checked: NiriConf.naturalScroll; onToggled: NiriConf.set("naturalScroll", !NiriConf.naturalScroll) }
        }
    }

    NiriStatus { Layout.fillWidth: true }

    Group {
        title: Lang.t("Kısayollar")
        SettingRow {
            label: Lang.t("Kısayol tablosu")
            sub: "Super + Shift + /"
            PillButton { implicitHeight: 38; label: Lang.t("Göster"); icon: "keyboard"; onClicked: Ui.run(["qs", "-p", "/usr/share/vabu/shell", "ipc", "call", "shortcuts", "toggle"]) }
        }
        SettingRow {
            label: Lang.t("niri ayar dosyası")
            sub: "~/.config/niri/config.kdl"
            PillButton { implicitHeight: 38; label: Lang.t("Aç"); icon: "edit"; onClicked: Ui.run(["xdg-open", (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/niri/config.kdl"]) }
        }
    }
}
