import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell.Io
ColumnLayout {
    id: page
    spacing: 18
    property string document: "shell"
    property string incoming: ""
    property var preview: null
    property string message: ""
    property bool confirmed: false
    function fieldName(key) {
        return Lang.t(({theme:"Görünüm",accent:"Vurgu rengi",sidebarSide:"Panel konumu",sidebarWidth:"Panel genişliği",sidebarCompact:"Dar panel",focusCompact:"Odakta paneli daralt",showSeconds:"Saniyeleri göster",showMedia:"Medya",reducedMotion:"Hareketi azalt",highContrast:"Yüksek kontrast",effects:"Cam efektleri",textScale:"Yazı ölçeği",language:"Arayüz dili",pinned:"Sabitlenmiş uygulamalar",displayProfiles:"Ekran profilleri",notificationPolicies:"Bildirim tercihleri",xkbLayout:"Klavye düzenleri",xkbVariant:"Klavye çeşidi",xkbOptions:"Klavye seçenekleri",naturalScroll:"Doğal kaydırma",gaps:"Pencere aralığı",radius:"Köşe yuvarlaklığı",animations:"Animasyonlar",workspaces:"Çalışma alanları",shortcuts:"Kısayollar",acLock:"Prizde kilitleme",acScreen:"Prizde ekran kapama",acSuspend:"Prizde uyku",batteryLock:"Pilde kilitleme",batteryScreen:"Pilde ekran kapama",batterySuspend:"Pilde uyku"})[key] || key)
    }
    Group {
        title: Lang.t("Ayarları dışa aktar")
        note: Lang.t("Masaüstü ve pencere ayarları ayrı aktarılır. Parolalar, pano, konum, otomatik başlatma izni ve canlı ekran düzeni aktarılmaz.")
        Segmented { options: [Lang.t("Masaüstü"),Lang.t("Pencereler")]; currentIndex: page.document === "shell" ? 0 : 1; onPicked: i => page.document = i === 0 ? "shell" : "niri" }
        PillButton { label: Lang.t("JSON dosyasına kaydet"); enabled: !transfer.running; onClicked: saveDialog.open() }
    }
    Group {
        title: Lang.t("Ayarları içe aktar")
        note: Lang.t("Önce değişiklikleri incele. Dosya veya mevcut ayarlar değişirse yeniden önizleme gerekir. Mevcut sağlam ayarlar yedeklenir.")
        PillButton { label: Lang.t("Dosya seç ve önizle"); enabled: !transfer.running; onClicked: loadDialog.open() }
        Text { font.family: Theme.sans; font.pixelSize: Math.round(14 * Config.textScale); Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText; color: Theme.soft; text: page.preview ? (page.preview.document === "shell" ? Lang.t("Masaüstü") : Lang.t("Pencereler")) + " · " + page.preview.changes.length : "" }
        Repeater {
            model: page.preview?.changes ?? []
            delegate: Group {
                required property var modelData
                title: page.fieldName(modelData.key)
                Text { font.family: Theme.sans; font.pixelSize: Math.round(14 * Config.textScale); Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText; color: Theme.soft; text: JSON.stringify(modelData.before) + " → " + JSON.stringify(modelData.after) }
            }
        }
        SettingRow { visible: page.preview !== null; label: Lang.t("Değişiklikleri inceledim"); Toggle { checked: page.confirmed; onToggled: page.confirmed = !checked } }
        PillButton { label: Lang.t("İncelediğim değişiklikleri uygula"); enabled: page.preview !== null && page.confirmed && !transfer.running; onClicked: { transfer.action="apply"; transfer.command=["/usr/libexec/vabu/preferences","apply",page.incoming,page.preview.fileDigest,page.preview.baseDigest]; page.confirmed=false; transfer.running=true } }
    }
    Text { font.family: Theme.sans; font.pixelSize: Math.round(14 * Config.textScale); Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText; color: Theme.soft; text: page.message }
    FileDialog { id: saveDialog; title: Lang.t("Ayarları dışa aktar"); fileMode: FileDialog.SaveFile; defaultSuffix: "json"; nameFilters: ["JSON (*.json)"]; onAccepted: { transfer.action="export"; transfer.command=["/usr/libexec/vabu/preferences","export",page.document,selectedFile.toString()]; transfer.running=true } }
    FileDialog { id: loadDialog; title: Lang.t("Ayarları içe aktar"); nameFilters: ["JSON (*.json)"]; onAccepted: { page.incoming=selectedFile.toString(); page.preview=null; page.confirmed=false; transfer.action="preview"; transfer.command=["/usr/libexec/vabu/preferences","preview",page.incoming]; transfer.running=true } }
    Process {
        id: transfer
        property string action: ""
        stdout: StdioCollector { id: result }
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (code !== 0) { page.message=errors.text.trim() || Lang.t("İşlem tamamlanamadı."); page.preview=null; return }
            try {
                const data=JSON.parse(result.text)
                if (action === "preview") { page.preview=data; page.message="" }
                else { page.message=Lang.t("Tamamlandı"); if (action === "apply") { if (data.document === "niri") NiriConf.apply(false); page.preview=null } }
            } catch(e) { page.message=Lang.t("İşlem tamamlanamadı.") }
        }
    }
}
