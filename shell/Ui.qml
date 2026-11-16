pragma Singleton
import QtQuick
import Quickshell

// Kabuğun açık/kapalı durumu: aynı anda tek bir katman açık olur.
Singleton {
    id: root

    property bool launcherOpen: false
    property string launcherMode: "search"     // search | install | command | calc
    property bool sessionMenuOpen: false
    property bool shortcutsOpen: false
    property bool welcomeOpen: false
    property var appMenuEntry: null
    property bool clipboardOpen: false
    property bool locked: false

    // Yan panelden açılan paneller: wifi | bluetooth | sound | calendar | control | notifications
    property string popover: ""
    property string popoverScreen: ""

    function togglePopover(name, screenName) {
        const same = popover === name && popoverScreen === screenName
        const keep = popover !== ""       // panelden panele geçerken diğer katmanlar zaten kapalı
        if (!keep) closeAll()
        if (same) { popover = ""; return }
        popoverScreen = screenName
        popover = name
    }
    function closePopover() { popover = "" }

    function openLauncher(mode) {
        closeAll()
        launcherMode = mode || "search"
        launcherOpen = true
    }
    function toggleLauncher(mode) {
        if (launcherOpen) launcherOpen = false
        else openLauncher(mode)
    }
    function closeAll() {
        welcomeOpen = false
        appMenuEntry = null
        clipboardOpen = false
        launcherOpen = false
        popover = ""
        sessionMenuOpen = false
        shortcutsOpen = false
    }
    function lock() {
        closeAll()
        locked = true
    }

    // Önce açık katmanlar kapanır ki görüntüde çıkmasınlar
    function suspend() {
        closeAll()
        Quickshell.execDetached(["sh", "-c", "/usr/libexec/vabu/lock && systemctl suspend"])
    }
    function screenshot() { closeAll(); shot.start() }
    Timer { id: shot; interval: 320; onTriggered: Quickshell.execDetached(["niri", "msg", "action", "screenshot"]) }

    function appMenu(entry) { closeAll(); appMenuEntry = entry }
    function run(cmd) { Quickshell.execDetached(cmd) }
    function terminal(cmd) { Quickshell.execDetached(["foot", "--app-id", "vabu-term"].concat(cmd)) }
    function settings(page) { closeAll(); Quickshell.execDetached(page ? ["vabu-settings", page] : ["vabu-settings"]) }
}
