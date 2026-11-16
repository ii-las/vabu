import QtQuick
import QtQuick.Layouts
import Quickshell
OverlayWindow {
    id: root
    open: Ui.welcomeOpen
    onDismissed: Ui.welcomeOpen = false
    property int step: 0
    readonly property var steps: [
        {title:Lang.t("Vabu’ya hoş geldin"), body:Lang.t("Pencereler yatay kolonlarda, çalışma alanları dikeyde düzenlenir. Bu kısa turda temel hareketleri deneyebilirsin."), action:Lang.t("Terminal aç"), cmd:["foot"]},
        {title:Lang.t("Kolonlar ve pencereler"), body:Lang.t("Super + Sol/Sağ kolonlar arasında gezer. Super + Yukarı/Aşağı pencereler ve çalışma alanları arasında ilerler. Shift ekleyerek pencereyi taşı."), action:Lang.t("Kısayolları göster"), special:"shortcuts"},
        {title:Lang.t("Çalışma alanların"), body:Lang.t("Super + O genel bakışı açar. Yan panelde pencere simgelerini sürükleyerek başka alana taşıyabilirsin."), action:Lang.t("Genel bakışı dene"), special:"overview"},
        {title:Lang.t("Ara, başlat, kur"), body:Lang.t("Super + Space uygulama arar. Super + Tab açık pencere başlıklarını arar. Super + I uygulama kurmayı açar."), action:Lang.t("Başlatıcıyı dene"), special:"launcher"},
        {title:Lang.t("Kendi düzenin"), body:Lang.t("Masaüstü ayarlarından alan adları, uygulama atamaları ve isteğe bağlı açılış düzenleri oluştur. Ekran düzenlerini profil olarak saklayabilirsin."), action:Lang.t("Masaüstü ayarları"), cmd:["vabu-settings","desktop"]},
        {title:Lang.t("Hazırsın"), body:Lang.t("Güç, erişilebilirlik ve gizlilik ayarlarını inceleyebilirsin. Bir sorun olursa Tanılama ve kurtarma sayfasından başlayabilirsin. Bu turu Masaüstü ayarlarından tekrar açabilirsin."), action:Lang.t("Tanılama merkezi"), cmd:["vabu-settings","health"]}
    ]
    function tryAction() {
        const s = steps[step]
        if (s.cmd) Ui.run(s.cmd)
        else if (s.special === "overview") Niri.toggleOverview()
        else if (s.special === "shortcuts") { Ui.welcomeOpen = false; Ui.shortcutsOpen = true }
        else { Ui.welcomeOpen = false; Ui.openLauncher("search") }
    }
    function finish() { Config.set("onboardingDone", true); Ui.welcomeOpen = false }
    Card {
        width: Math.min(620, parent.width - 32)
        height: Math.min(body.implicitHeight + 48, parent.height - 32)
        anchors.centerIn: parent
        tint: Theme.panelSolid
        Flickable {
            anchors.fill: parent; anchors.margins: 24
            contentHeight: body.implicitHeight; clip: true
            ColumnLayout {
                id: body; width: parent.width; spacing: 18
                Text { textFormat: Text.PlainText; text: "Vabu · " + (root.step + 1) + " / " + root.steps.length; color: Theme.accent; font.family: Theme.sans }
                Text { textFormat: Text.PlainText; text: root.steps[root.step].title; color: Theme.paper; font.pixelSize: Math.round((26) * Config.textScale); font.family: Theme.sans; Layout.fillWidth: true; wrapMode: Text.Wrap }
                Text { textFormat: Text.PlainText; text: root.steps[root.step].body; color: Theme.soft; font.pixelSize: Math.round((16) * Config.textScale); font.family: Theme.sans; Layout.fillWidth: true; wrapMode: Text.Wrap }
                PillButton { label: root.steps[root.step].action; onClicked: root.tryAction() }
                Flow {
                    Layout.fillWidth: true; spacing: 8
                    PillButton { label: Lang.t("Geri"); enabled: root.step > 0; onClicked: root.step-- }
                    PillButton { primary: true; label: root.step === root.steps.length - 1 ? Lang.t("Tamamla") : Lang.t("Devam et"); onClicked: root.step === root.steps.length - 1 ? root.finish() : root.step++ }
                    PillButton { label: Lang.t("Turu atla"); onClicked: root.finish() }
                }
            }
        }
    }
}
