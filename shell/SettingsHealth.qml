import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
ColumnLayout {
    id: page
    spacing: 18
    property var checks: []
    property var metrics: ({})
    property string error: ""
    property string reportText: ""
    property bool resetConfirmed: false
    property var boot: ({})
    property var measurements: []
    Process { id: sampleProbe; command: ["/usr/libexec/vabu/desktop-measures","sample"]; stdout: StdioCollector {}; stderr: StdioCollector {}; onExited: code => { if (code !== 0) page.error=Lang.t("Ölçüm tamamlanamadı."); measureHistory.running=true } }
    Process { id: measureHistory; running: true; command: ["/usr/libexec/vabu/desktop-measures","records"]; stdout: StdioCollector { onStreamFinished: { try { page.measurements=JSON.parse(text).records } catch(e) {} } } }
    Process { id: bootProbe; command: ["/usr/libexec/vabu/system-check","recovery"]; stdout: StdioCollector { onStreamFinished: { try { page.boot = JSON.parse(text) } catch(e) { page.error = "Önyükleme envanteri okunamadı." } } } }

    Component.onCompleted: { probe.running = true; perf.running = true; bootProbe.running = true }
    Process {
        id: probe; command: ["/usr/libexec/vabu/desktop-tools", "diagnostics"]
        stdout: StdioCollector { onStreamFinished: { try { page.checks = JSON.parse(text).checks } catch(e) { page.error = "Tanılama okunamadı." } } }
        onExited: code => { if (code !== 0) page.error = "Tanılama çalıştırılamadı." }
    }
    Process { id: perf; command: ["/usr/libexec/vabu/desktop-tools", "performance"]; stdout: StdioCollector { onStreamFinished: { try { page.metrics = JSON.parse(text) } catch(e) {} } } }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: if (!perf.running) perf.running = true }
    RowLayout {
        visible: probe.running
        Spinner {}
        Text { textFormat: Text.PlainText; text: Lang.t("Denetleniyor"); color: Theme.soft; font.family: Theme.sans }
    }
    Group {
        title: Lang.t("Sistem denetimi")
        note: Lang.t("Bu kontroller ayar değiştirmez. İsteğe bağlı hizmetlerin boşta olması hata sayılmaz. İşlevlerin gerçek kullanım denemesi ayrıca gerekir.")
        Repeater {
            model: page.checks
            delegate: SettingRow {
                required property var modelData
                label: Lang.t(modelData.label); sub: Lang.t(modelData.detail)
                Chip { text: Lang.t(({ok:"Çalışıyor",available:"Kullanımda değil",inactive:"Bağlı değil",unconfigured:"Yapılandırılmamış",failed:"Başarısız",unknown:"Bilinmiyor",attention:"Denetle"})[modelData.state] || "Bilinmiyor"); kind: modelData.state === "ok" ? "ok" : ["available","inactive","unconfigured"].includes(modelData.state) ? "info" : "warn" }
                PillButton { label: Lang.t("Aç"); onClicked: Ui.settings(({network:"network",bluetooth:"network",drivers:"drivers",updates:"updates",snapshots:"updates",audio:"sound",locking:"power",printing:"devices",portal:"devices"})[modelData.id] || "about") }
            }
        }
        PillButton { label: Lang.t("Yeniden denetle"); enabled: !probe.running; onClicked: { page.error = ""; probe.running = true } }
    }
    Group {
        title: Lang.t("Kaynak kullanımı")
        note: Lang.t("CPU yüzdesi süreç ömrü ortalamasıdır. Bunlar karşılaştırmalı performans veya pil ömrü testi değildir.")
        Repeater { model: page.metrics.processes ?? []; delegate: SettingRow { required property var modelData; label: modelData.name; sub: modelData.memoryMiB + " MiB · CPU %" + modelData.cpu } }
        Repeater { model: page.metrics.battery ?? []; delegate: SettingRow { required property var modelData; label: "Pil %" + modelData.percent; sub: modelData.watts === null ? "Güç ölçümü sunulmuyor" : modelData.watts.toFixed(2) + " W" } }
    }
    Group {
        title: Lang.t("Tekrarlanabilir ölçüm")
        note: Lang.t("Aynı donanım, parlaklık, güç kaynağı ve uygulamalarla karşılaştır. Bellek ve destekleniyorsa pil gücü örneklenir; CPU süreç ömrü ortalamasıdır. Kısa örnekleme pil ömrü veya performans garantisi vermez.")
        PillButton { label: sampleProbe.running ? Lang.t("Ölçülüyor") : Lang.t("10 örnek al"); enabled: !sampleProbe.running; onClicked: sampleProbe.running=true }
        Repeater {
            model: page.measurements
            delegate: SettingRow {
                required property var modelData
                label: new Date(modelData.time*1000).toLocaleString(Config.language === "en" ? "en-GB" : "tr-TR")
                sub: (modelData.memoryMiB === null ? Lang.t("Ölçülemedi") : modelData.memoryMiB + " MiB") + " · CPU %" + (modelData.cpuLifetimePercent === null ? "?" : modelData.cpuLifetimePercent) + " · " + (modelData.batteryWatts === null ? Lang.t("Güç ölçümü sunulmuyor") : modelData.batteryWatts + " W") + " · boot " + (modelData.bootSeconds === null ? "?" : modelData.bootSeconds + " s")
            }
        }
    }
    Group {
        title: Lang.t("Kurtarma")
        note: Lang.t("niri sıfırlama kişisel niri ayarlarını varsayılana döndürür. Eski kullanıcı ayarları yedeklenir. Tam sistem geri alma burada uygulanmaz.")
        SettingRow { label: Lang.t("niri ayarlarını sıfırla"); Toggle { checked: page.resetConfirmed; onToggled: page.resetConfirmed = !checked } }
        PillButton { label: Lang.t("Yedekleyip sıfırla"); enabled: page.resetConfirmed; onClicked: { page.resetConfirmed = false; Ui.terminal(["vabu","reset","niri"]) } }
        SettingRow { label: Lang.t("Tam sistem geri alma"); sub: Lang.t(page.boot.offlineRestoreAvailable ? "Canlı ISO için deneysel motor mevcut; VM doğrulaması bekliyor." : "Tam geri alma aracı bulunamadı.") }
        SettingRow { label: Lang.t("Çekirdek ve önyükleme dosyaları"); sub: Lang.t(page.boot.state === "files-present" ? "Eşleşen dosyalar bulundu; açılış doğrulanmadı." : "Dosya tutarlılığı doğrulanamadı.") }
        Repeater {
            model: page.boot.kernels ?? []
            delegate: SettingRow { required property var modelData; label: modelData.version; sub: "kernel: " + modelData.image + " · initramfs: " + modelData.initramfs + " · modules: " + modelData.modules }
        }
        PillButton { label: Lang.t("Anlık görüntüleri göster"); onClicked: Ui.settings("updates") }
        PillButton { label: Lang.t("Kurtarma oturumu"); onClicked: page.error = "Giriş ekranında Vabu Kurtarma oturumunu seçebilirsin. Masaüstü kabuğu olmadan terminal ve temel panel açılır." }
    }
    Group {
        title: Lang.t("Paylaşılabilir rapor")
        note: Lang.t("Yalnızca paket sürümleri ve sabit durum etiketleri toplanır. Kullanıcı adı, ağ adı, IP adresi, seri numarası ve günlük içerikleri eklenmez. Önce aşağıdaki raporu incele.")
        PillButton { label: Lang.t("Raporu hazırla"); enabled: !report.running; onClicked: report.running = true }
        TextEdit { textFormat: TextEdit.PlainText; Layout.fillWidth: true; implicitHeight: Math.min(320, contentHeight + 16); text: page.reportText; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap; color: Theme.paper; font.family: Theme.mono; font.pixelSize: Math.round((12) * Config.textScale)}
        PillButton { label: Lang.t("İncelediğim raporu kopyala"); enabled: page.reportText !== ""; onClicked: Quickshell.clipboardText = page.reportText }
    }
    Process { id: report; command: ["/usr/libexec/vabu/desktop-tools", "report"]; stdout: StdioCollector { onStreamFinished: { try { page.reportText = JSON.stringify(JSON.parse(text), null, 2) } catch(e) { page.error = "Rapor hazırlanamadı." } } } }
    Text { Layout.fillWidth: true; text: page.error; wrapMode: Text.Wrap; textFormat: Text.PlainText; color: Theme.warn }
}
