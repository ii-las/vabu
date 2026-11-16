//@ pragma UseQApplication
//@ pragma IconTheme Papirus
// Vabu kurulumu - giriş noktası.  Çalıştırma:  vabu-installer
// Canlı oturumda liveuser olarak açılır; yalnızca arka uç root olarak (sudo -n) çalışır.
// Ortam: VABU_INSTALL_BACKEND (arka ucun yolu), VABU_INSTALL_DRYRUN=1 (arka uca --dry-run)
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    FloatingWindow {
        id: win
        // Yan panel ve niri kuralı pencereyi bu adla tanır
        title: "Vabu'yu kur"
        implicitWidth: 1100
        implicitHeight: 720
        color: Theme.night
        // Kurulum sürerken pencere kapatılırsa yeniden açılır: arka uç yarıda kalmasın
        onVisibleChanged: {
            if (visible) return
            if (InstallerState.runState === "running") Qt.callLater(() => { win.visible = true })
            else Qt.quit()
        }

        InstallerView {
            id: view
            anchors.fill: parent
            focus: true
        }
    }

    IpcHandler {
        target: "installer"
        function state(): string { return JSON.stringify(view.describe()) }
    }
}
