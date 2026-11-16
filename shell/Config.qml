pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Vurgu renkleri: açık görünümde koyu ton, koyu görünümde açık ton
    readonly property var accents: ({
        "mavi":    { light: "#2C56CC", dark: "#8FB2FF", darkInk: "#0E1A33", name: "Mavi" },
        "yesil":   { light: "#1F7F58", dark: "#86D4AC", darkInk: "#0B2A1C", name: "Yeşil" },
        "turuncu": { light: "#B5601A", dark: "#EDB483", darkInk: "#3A1E07", name: "Turuncu" },
        "pembe":   { light: "#B23A6E", dark: "#EFA9C6", darkInk: "#3A0F22", name: "Pembe" },
        "grafit":  { light: "#3B4250", dark: "#C9CED8", darkInk: "#15181E", name: "Grafit" }
    })
    readonly property var wallpapers: [
        { name: "Gündüz", path: "/usr/share/vabu/assets/wallpaper-gunduz.jpg" },
        { name: "Alacakaranlık", path: "/usr/share/vabu/assets/wallpaper.jpg" },
        { name: "Gece", path: "/usr/share/vabu/assets/wallpaper-gece.jpg" }
    ]

    property var values: ({})
    readonly property string dir: Quickshell.env("HOME") + "/.config/vabu"

    // acik | koyu | otomatik (gün batımında koyu)
    readonly property string theme: values.theme ?? "otomatik"
    readonly property string accentName: accents[values.accent] ? values.accent : "mavi"
    readonly property color accentLight: accents[accentName].light
    readonly property color accentDark: accents[accentName].dark
    readonly property color accentDarkInk: accents[accentName].darkInk
    // "auto": görünüme göre gündüz ya da alacakaranlık. Eski sürümler .png kaydetmişti.
    readonly property string wallpaperChoice: (values.wallpaper ?? "auto")
        .replace(/^\/usr\/share\/vabu\/assets\/(wallpaper[a-z-]*)\.png$/, "/usr/share/vabu/assets/$1.jpg")
        .replace(/wallpaper-sis\.jpg$/, "wallpaper-gunduz.jpg")
    readonly property string wallpaper: wallpaperChoice !== "auto" ? wallpaperChoice
        : Theme.dark ? wallpapers[1].path : wallpapers[0].path
    readonly property string sidebarSide: values.sidebarSide ?? "left"
    readonly property bool showSeconds: values.showSeconds ?? false
    readonly property bool showMedia: values.showMedia ?? true
    readonly property bool nightLight: values.nightLight ?? false
    readonly property var pinned: values.pinned ?? [
        "org.mozilla.firefox", "foot", "org.gnome.Nautilus",
        "steam", "so.vabu.Settings", "org.gnome.TextEditor"
    ]
    // Gün yayı için konum; boşsa saat diliminden bulunur (bkz. Sun.qml).
    readonly property var location: values.location ?? null

    function set(key, value) {
        const v = Object.assign({}, values)
        if (value === null || value === undefined) delete v[key]
        else v[key] = value
        values = v
        file.setText(JSON.stringify(v, null, 2) + "\n")
    }

    // Klasör yoksa dosya izlenemez; oluşturunca izlemeyi yeniden kur
    Process { running: true; command: ["mkdir", "-p", root.dir]; onExited: file.reload() }

    FileView {
        id: file
        path: root.dir + "/shell.json"
        // Pencereler açılmadan önce okunsun: ilk karede doğru görünüm
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            try { root.values = JSON.parse(text()) } catch (e) { root.values = {} }
        }
        onLoadFailed: root.values = {}
        onFileChanged: reload()
    }
}
