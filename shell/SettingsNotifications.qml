import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: page
    spacing: 18
    function change(key, mode) {
        const policies=Object.assign({},Config.values.notificationPolicies || {})
        if (mode === "show") delete policies[key]; else policies[key]=mode
        Config.set("notificationPolicies",policies)
    }
    Group {
        title: Lang.t("Uygulama bildirimleri")
        note: Lang.t("Sessiz seçeneği bildirimi merkezde tutar. Engelle seçeneği kritik bildirimleri de gizler. Bu tercihler uygulamanın bildirdiği kimliğe dayanır; bir güvenlik izni değildir.")
        Field { id: filter; Layout.fillWidth: true; placeholder: Lang.t("Uygulama ara") }
        Repeater {
            model: Apps.all.filter(a => !filter.text || a.name.toLocaleLowerCase().includes(filter.text.toLocaleLowerCase())).slice().sort((a,b)=>a.name.localeCompare(b.name)).slice(0,80)
            delegate: SettingRow {
                required property var modelData
                readonly property string appKey: modelData.id.replace(/\.desktop$/, "")
                label: modelData.name
                Segmented { options: [Lang.t("Göster"),Lang.t("Sessiz"),Lang.t("Engelle")]; currentIndex: ["show","silent","block"].indexOf((Config.values.notificationPolicies || {})[appKey] || "show"); onPicked: i => page.change(appKey,["show","silent","block"][i]) }
            }
        }
    }
    Group {
        title: Lang.t("Diğer bildirim kimlikleri")
        note: Lang.t("Masaüstü kimliği yoksa name:Uygulama biçimini kullan. Bildirim içeriği kaydedilmez.")
        Field { id: identity; Layout.fillWidth: true; placeholder: Lang.t("Bildirim kimliği (ör. name:Uygulama)") }
        Flow {
            Layout.fillWidth: true; spacing: 8
            PillButton { label: Lang.t("Sessiz"); enabled: identity.text.trim() !== ""; onClicked: page.change(identity.text.trim(),"silent") }
            PillButton { label: Lang.t("Engelle"); enabled: identity.text.trim() !== ""; onClicked: page.change(identity.text.trim(),"block") }
        }
        Repeater {
            model: Object.keys(Config.values.notificationPolicies || {})
            delegate: SettingRow { required property string modelData; label: modelData; sub: (Config.values.notificationPolicies || {})[modelData]; PillButton { label: Lang.t("Varsayılana dön"); onClicked: page.change(modelData,"show") } }
        }
    }
}
