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

    readonly property var values: store.values
    readonly property bool ready: store.ready && store.writable
    readonly property string error: store.error
    readonly property bool canRecover: store.canRecover
    function recover() { store.recover() }
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/vabu"

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
    readonly property bool sidebarCompact: focusMode ? (values.focusCompact ?? true) : (values.sidebarCompact ?? false)
    readonly property bool nightLight: values.nightLight ?? false
    readonly property var pinned: values.pinned ?? [
        "org.mozilla.firefox", "foot", "org.gnome.Nautilus",
        "steam", "so.vabu.Settings", "org.gnome.TextEditor"
    ]
    // Gün yayı için konum; boşsa saat diliminden bulunur (bkz. Sun.qml).
    readonly property var location: values.location ?? null

    property real focusClock: Date.now()
    readonly property real focusUntil: Number(values.focusUntil) || 0
    readonly property bool focusMode: values.focusMode === true || focusUntil > focusClock
    function focusFor(minutes) { store.patch({focusMode:false, focusUntil:Date.now() + minutes * 60000}) }
    function stopFocus() { store.patch({focusMode:false, focusUntil:null}) }
    function setMany(changes) { store.patch(changes) }
    Timer { interval: 1000; repeat: true; running: root.focusUntil > 0; onTriggered: { root.focusClock = Date.now(); if (root.focusUntil <= root.focusClock) store.patch({focusUntil:null}) } }
    readonly property bool clipboardEnabled: values.clipboardEnabled === true
    readonly property bool reducedMotion: values.reducedMotion ?? false
    readonly property bool highContrast: values.highContrast ?? false
    readonly property bool effects: values.effects ?? false
    readonly property real textScale: [1, 1.15, 1.3, 1.5].includes(values.textScale) ? values.textScale : 1
    readonly property int sidebarWidth: Math.max(240, Math.min(360, Number(values.sidebarWidth) || 280))
    readonly property string language: values.language === "en" ? "en" : "tr"

    function set(key, value) {
        if (key === "focusMode" && value === false) { stopFocus(); return }
        if (key === "sidebarCompact" && focusMode) key = "focusCompact"
        const change = {}
        change[key] = value === undefined ? null : value
        store.patch(change)
    }
    JsonStore { id: store; document: "shell" }
}
