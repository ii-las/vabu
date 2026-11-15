pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var accents: ({
        "nane":    { color: "#8EF0C6", ink: "#0E3B2C", name: "Nane" },
        "gok":     { color: "#A9C7F7", ink: "#14243F", name: "Gök" },
        "seftali": { color: "#F2B48A", ink: "#3B2414", name: "Şeftali" },
        "gul":     { color: "#F7A8C4", ink: "#3B1426", name: "Gül" },
        "kagit":   { color: "#F3F1EC", ink: "#16161B", name: "Kağıt" }
    })
    readonly property var wallpapers: [
        { name: "Alacakaranlık", path: "/usr/share/vabu/assets/wallpaper.png" },
        { name: "Gece", path: "/usr/share/vabu/assets/wallpaper-gece.png" }
    ]

    property var values: ({})
    readonly property string dir: Quickshell.env("HOME") + "/.config/vabu"

    readonly property string accentName: values.accent ?? "gok"
    readonly property color accent: (accents[accentName] ?? accents.gok).color
    readonly property color accentInk: (accents[accentName] ?? accents.gok).ink
    readonly property string wallpaper: values.wallpaper ?? wallpapers[0].path
    readonly property string sidebarSide: values.sidebarSide ?? "left"
    readonly property bool showSeconds: values.showSeconds ?? false
    readonly property bool showMedia: values.showMedia ?? true
    readonly property var pinned: values.pinned ?? [
        "org.mozilla.firefox", "Alacritty", "org.gnome.Nautilus",
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
