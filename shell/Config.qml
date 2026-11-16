pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var accents: ({
        "kagit":   { color: "#EDEAE3", ink: "#141316", name: "Kağıt" },
        "nane":    { color: "#B9E3C6", ink: "#10301F", name: "Nane" },
        "gok":     { color: "#B9CCF2", ink: "#14223D", name: "Gök" },
        "seftali": { color: "#EBC09A", ink: "#3A2213", name: "Şeftali" },
        "gul":     { color: "#EBB4C8", ink: "#3A1428", name: "Gül" }
    })
    readonly property var wallpapers: [
        { name: "Alacakaranlık", path: "/usr/share/vabu/assets/wallpaper.jpg" },
        { name: "Gece", path: "/usr/share/vabu/assets/wallpaper-gece.jpg" },
        { name: "Sis", path: "/usr/share/vabu/assets/wallpaper-sis.jpg" }
    ]

    property var values: ({})
    readonly property string dir: Quickshell.env("HOME") + "/.config/vabu"

    readonly property string accentName: values.accent ?? "kagit"
    readonly property color accent: (accents[accentName] ?? accents.kagit).color
    readonly property color accentInk: (accents[accentName] ?? accents.kagit).ink
    // Eski sürümler hazır duvar kağıtlarını .png olarak kaydetmişti
    readonly property string wallpaper: (values.wallpaper ?? wallpapers[0].path)
        .replace(/^\/usr\/share\/vabu\/assets\/(wallpaper[a-z-]*)\.png$/, "/usr/share/vabu/assets/$1.jpg")
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

    Process { running: true; command: ["mkdir", "-p", root.dir] }

    FileView {
        id: file
        path: root.dir + "/shell.json"
        watchChanges: true
        printErrors: false
        onLoaded: {
            try { root.values = JSON.parse(text()) } catch (e) { root.values = {} }
        }
        onLoadFailed: root.values = {}
        onFileChanged: reload()
    }
}
