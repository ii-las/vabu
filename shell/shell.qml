//@ pragma UseQApplication
// Vabu Shell - giriş noktası.  Çalıştırma:  qs -p /usr/share/vabu/shell
// Komut satırından denetim (niri kısayolları bunları kullanır):
//   qs -p /usr/share/vabu/shell ipc call launcher open search|install|command
//   qs -p /usr/share/vabu/shell ipc call lock lock
//   qs -p /usr/share/vabu/shell ipc call shortcuts toggle
//   qs -p /usr/share/vabu/shell ipc call session toggle
//   qs -p /usr/share/vabu/shell ipc call notifications toggle
//   qs -p /usr/share/vabu/shell ipc call osd brightness 60
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // Her ekran: duvar kağıdı, yan çubuk, bildirim merkezi
    Variants {
        model: Quickshell.screens
        delegate: Component { Wallpaper {} }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component { Sidebar {} }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component { NotificationCenter {} }
    }

    // Tek örnekler (odaktaki ekranda açılır)
    Launcher {}
    NotificationPopups {}
    Osd { id: osd }
    Shortcuts {}
    SessionMenu {}

    // Kilit ekranı
    WlSessionLock {
        id: sessionLock
        locked: Ui.locked
        WlSessionLockSurface {
            id: surface
            color: Theme.night
            LockSurface {
                anchors.fill: parent
                // Şifre alanı ilk ekranda; diğer ekranlar sadece saat + duvar kağıdı gösterir
                primary: surface.screen === Quickshell.screens[0]
                onUnlocked: Ui.locked = false
            }
        }
    }

    // IPC
    IpcHandler {
        target: "launcher"
        function open(mode: string): void { Ui.openLauncher(mode) }
        function toggle(mode: string): void { Ui.toggleLauncher(mode) }
        function close(): void { Ui.launcherOpen = false }
    }
    IpcHandler {
        target: "lock"
        function lock(): void { Ui.lock() }
        function isLocked(): bool { return Ui.locked }
    }
    IpcHandler {
        target: "shortcuts"
        function toggle(): void { Ui.shortcutsOpen = !Ui.shortcutsOpen }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { Ui.sessionMenuOpen = !Ui.sessionMenuOpen }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { Ui.notifCenterOpen = !Ui.notifCenterOpen }
        function dnd(on: bool): void { Notifs.dnd = on }
        function clear(): void { Notifs.clearAll() }
    }
    IpcHandler {
        target: "osd"
        function brightness(percent: int): void { osd.show("brightness", percent / 100, false) }
    }
}
