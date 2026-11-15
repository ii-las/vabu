pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool launcherOpen: false
    property string launcherMode: "search"     // search | install | command | calc
    property bool notifCenterOpen: false
    property bool sessionMenuOpen: false
    property bool shortcutsOpen: false
    property bool locked: false

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
        launcherOpen = false
        notifCenterOpen = false
        sessionMenuOpen = false
        shortcutsOpen = false
    }
    function lock() {
        closeAll()
        locked = true
    }

    function run(cmd) { Quickshell.execDetached(cmd) }
    function terminal(cmd) { Quickshell.execDetached(["alacritty", "--class", "vabu-term", "-e"].concat(cmd)) }
    function settings(page) { Quickshell.execDetached(page ? ["vabu-settings", page] : ["vabu-settings"]) }
}
