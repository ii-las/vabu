import QtQuick
import QtQuick.Layouts
import Quickshell
ColumnLayout {
    id: page
    spacing: 18
    property string workspaceName: ""
    property string applicationId: ""
    property string selectedWorkspace: ""
    Group {
        title: Lang.t("Odak modu")
        note: Lang.t("Bildirimleri susturur ve istersen yan paneli daraltır. Diğer ayarlarını değiştirmeden kapatılabilir.")
        SettingRow { label: Lang.t("Odak modu"); Toggle { checked: Config.focusMode; onToggled: Config.set("focusMode", !checked) } }
        Flow {
            Layout.fillWidth: true; spacing: 8
            Repeater { model: [25,50,90]; delegate: PillButton { required property int modelData; label: modelData + (Config.language === "en" ? " min" : " dk"); onClicked: Config.focusFor(modelData) } }
            PillButton { visible: Config.focusMode; label: Lang.t("Odağı bitir"); onClicked: Config.stopFocus() }
        }
        Text { font.family: Theme.sans; font.pixelSize: Math.round(14 * Config.textScale); visible: Config.focusUntil > Config.focusClock; Layout.fillWidth: true; textFormat: Text.PlainText; color: Theme.soft; text: Lang.t("Kalan dakika") + ": " + Math.ceil((Config.focusUntil - Config.focusClock) / 60000) }
        SettingRow { label: Lang.t("Odakta paneli daralt"); Toggle { checked: Config.values.focusCompact ?? true; onToggled: Config.set("focusCompact", !checked) } }
    }
    Group {
        title: Lang.t("Yan panel")
        SettingRow { label: Lang.t("Genişlik"); VSlider { implicitWidth: 180; from: 240; to: 360; stepSize: 10; value: Config.sidebarWidth; onMoved: v => Config.set("sidebarWidth", v) } }
        PillButton { label: Lang.t("İlk açılış turunu göster"); onClicked: Ui.run(["qs","-p","/usr/share/vabu/shell","ipc","call","welcome","open"]) }
    }
    Group {
        title: Lang.t("Adlandırılmış çalışma alanları")
        note: Lang.t("Uygulama atamaları yeni açılan pencerelere uygulanır. Açılış uygulamaları yalnızca açıkça etkinleştirirsen oturumla başlar.")
        Repeater {
            model: NiriConf.values.workspaces ?? []
            delegate: Group {
                id: workspaceGroup
                required property var modelData
                title: modelData.name
                PillButton { label: Lang.t("Kaldır"); onClicked: NiriConf.set("workspaces", (NiriConf.values.workspaces ?? []).filter(w => w.name !== workspaceGroup.modelData.name)) }
                Repeater {
                    model: workspaceGroup.modelData.apps ?? []
                    delegate: Group {
                        id: assignment
                        required property var modelData
                        readonly property string desktopId: typeof modelData === "string" ? modelData : modelData.desktopId
                        property bool editing: false
                        title: Apps.byId(desktopId)?.name || desktopId
                        note: typeof modelData === "string" ? Lang.t("Otomatik pencere eşleştirmesi") : modelData.appId
                        function saveMapping() {
                            const replacement = {desktopId:desktopId, appId:appIdInput.text.trim(), title:titleInput.text.trim()}
                            NiriConf.set("workspaces", (NiriConf.values.workspaces ?? []).map(w => w.name === workspaceGroup.modelData.name ? Object.assign({}, w, {apps:w.apps.map(a => (typeof a === "string" ? a : a.desktopId) === desktopId ? replacement : a)}) : w))
                            editing = false
                        }
                        Flow {
                            Layout.fillWidth: true; spacing: 8
                            PillButton { label: Lang.t("Pencere kimliğini düzenle"); onClicked: assignment.editing = !assignment.editing }
                            PillButton {
                                label: Lang.t("Kaldır")
                                onClicked: NiriConf.set("workspaces", (NiriConf.values.workspaces ?? []).map(w => w.name === workspaceGroup.modelData.name ? Object.assign({},w,{apps:(w.apps ?? []).filter(a => (typeof a === "string" ? a : a.desktopId) !== assignment.desktopId)}) : w))
                            }
                        }
                        Field { id: appIdInput; visible: assignment.editing; Layout.fillWidth: true; placeholder: Lang.t("Pencere uygulama kimliği (app_id)"); text: typeof assignment.modelData === "string" ? assignment.desktopId : assignment.modelData.appId }
                        Field { id: titleInput; visible: assignment.editing; Layout.fillWidth: true; placeholder: Lang.t("Tam pencere başlığı (isteğe bağlı)"); text: typeof assignment.modelData === "string" ? "" : (assignment.modelData.title || "") }
                        Text { font.family: Theme.sans; font.pixelSize: Math.round(14 * Config.textScale); visible: assignment.editing; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText; color: Theme.soft; text: Lang.t("Açık bir pencereyi seç veya kimliği elle gir. Paylaşılan org.quickshell kimliğinde başlık da gerekir.") }
                        Repeater {
                            model: assignment.editing ? Niri.windows.filter(w => w.app_id).slice(0,16) : []
                            delegate: PillButton {
                                required property var modelData
                                Layout.fillWidth: true
                                label: modelData.app_id + " · " + (modelData.title || "")
                                onClicked: { appIdInput.text = modelData.app_id; titleInput.text = modelData.app_id === "org.quickshell" ? (modelData.title || "") : "" }
                            }
                        }
                        PillButton { visible: assignment.editing; label: Lang.t("Eşleştirmeyi kaydet"); enabled: appIdInput.text.trim() !== ""; onClicked: assignment.saveMapping() }
                    }
                }
            }
        }
        Field { id: name; Layout.fillWidth: true; placeholder: Lang.t("Alan adı (ör. Kod)") }
        PillButton {
            label: Lang.t("Alan ekle")
            enabled: name.text.trim().length > 0 && name.text.trim().length <= 40 && !(NiriConf.values.workspaces ?? []).some(w => w.name === name.text.trim())
            onClicked: { NiriConf.set("workspaces", (NiriConf.values.workspaces ?? []).concat([{name:name.text.trim(),apps:[]}]).slice(0,12)); name.text = "" }
        }
        Field { id: appSearch; Layout.fillWidth: true; placeholder: Lang.t("Atamak için uygulama ara") }
        Repeater {
            model: appSearch.text.length > 1 ? Apps.search(appSearch.text).slice(0,3) : []
            delegate: Group {
                id: candidate
                required property var modelData
                title: modelData.name
                Repeater {
                    model: NiriConf.values.workspaces ?? []
                    delegate: PillButton {
                        required property var modelData
                        label: modelData.name
                        onClicked: {
                            const app = candidate.modelData.id.replace(/\.desktop$/, "")
                            NiriConf.set("workspaces", (NiriConf.values.workspaces ?? []).map(w => Object.assign({},w,{apps:(w.name === modelData.name ? (w.apps ?? []).some(a => (typeof a === "string" ? a : a.desktopId) === app) ? w.apps : (w.apps ?? []).concat([app]) : (w.apps ?? []).filter(a => (typeof a === "string" ? a : a.desktopId) !== app))})))
                            appSearch.text = ""
                        }
                    }
                }
            }
        }
        SettingRow { label: Lang.t("Atanan uygulamaları oturum açılışında başlat"); Toggle { checked: Config.values.restoreWorkspaceApps ?? false; onToggled: Config.set("restoreWorkspaceApps", !checked) } }
    }
    Group {
        title: Lang.t("Pano geçmişi")
        note: Lang.t("Varsayılan olarak kapalıdır. Açıldığında yalnızca bellekte 20 metin tutulur; kilitlenince veya 10 dakika sonra temizlenir. Hassas işaretlenen içerik kaydedilmez. İşaretlenmemiş parolalar tanınamayabilir.")
        SettingRow { label: Lang.t("Pano geçmişini etkinleştir"); Toggle { checked: Config.clipboardEnabled; onToggled: Config.set("clipboardEnabled", !checked) } }
        PillButton { label: Lang.t("Pano geçmişini aç"); onClicked: Ui.run(["qs","-p","/usr/share/vabu/shell","ipc","call","clipboard","toggle"]) }
    }
    NiriStatus { Layout.fillWidth: true }
}
