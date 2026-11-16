//@ pragma UseQApplication
//@ pragma IconTheme Papirus
// Vabu Shell - giriş noktası.  Çalıştırma:  qs -p /usr/share/vabu/shell
// Komut satırından denetim (niri kısayolları bunları kullanır):
//   qs -p /usr/share/vabu/shell ipc call launcher open search|install|command
//   qs -p /usr/share/vabu/shell ipc call lock lock
//   qs -p /usr/share/vabu/shell ipc call shortcuts toggle
//   qs -p /usr/share/vabu/shell ipc call session toggle
//   qs -p /usr/share/vabu/shell ipc call panel toggle wifi|bluetooth|sound|calendar|control|notifications
//   qs -p /usr/share/vabu/shell ipc call osd brightness 60
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    Component.onCompleted: {
        // Ekranları doğal çözünürlük + en yüksek yenileme hızında aç (ayarı olmayanlar için)
        DisplayAuto.run()
        // Arka plan servisleri ilk kullanımda değil, oturumla birlikte başlasın
        Net.refresh()
        NightLight.failed = false
        root.applyScheme()
    }

    // Görünüm değişince (elle ya da gün batımında) uygulamalar ve odak halkası da değişir
    function applyScheme(): void {
        const d = Theme.dark
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", d ? "prefer-dark" : "prefer-light"])
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", d ? "adw-gtk3-dark" : "adw-gtk3"])
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", d ? "Papirus-Dark" : "Papirus"])
        const accents = { mavi: "blue", yesil: "green", turuncu: "orange", pembe: "pink", grafit: "slate" }
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "accent-color", accents[Config.accentName] || "blue"])
    }
    Connections {
        target: Config
        function onAccentNameChanged() { root.applyScheme() }
    }

    // Odak halkası rengi ilk açılışta da güncel görünüme uysun
    Connections {
        target: NiriConf
        function onReadyChanged() { if (NiriConf.ready) NiriConf.apply(false) }
    }
    Connections {
        target: Theme
        function onDarkChanged() {
            root.applyScheme()
            if (NiriConf.ready) NiriConf.apply(false)
        }
    }

    // Her ekran: duvar kağıdı, yan panel, yan panelden açılan paneller
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
        delegate: Component { Popover {} }
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
                // niri klavyeyi imlecin olduğu ekrana verir; her ekran şifre alabilir
                primary: true
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
        function isSecure(): bool { return sessionLock.secure }
    }
    IpcHandler {
        target: "shortcuts"
        function toggle(): void { Ui.shortcutsOpen = !Ui.shortcutsOpen }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { Ui.sessionMenuOpen = !Ui.sessionMenuOpen }
    }
    // Paneller klavyeden açılınca odaktaki ekranda belirir
    function panelScreen(): string {
        return Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "")
    }
    IpcHandler {
        target: "panel"
        function toggle(name: string): void { Ui.togglePopover(name, root.panelScreen()) }
        function close(): void { Ui.closePopover() }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { Ui.togglePopover("notifications", root.panelScreen()) }
        function dnd(isOn: bool): void { Notifs.dnd = isOn }
        function clear(): void { Notifs.clearAll() }
    }
    IpcHandler {
        target: "osd"
        function brightness(percent: int): void {
            Brightness.noteExternal(percent / 100)
            osd.show("brightness", percent / 100, false)
        }
    }
}
