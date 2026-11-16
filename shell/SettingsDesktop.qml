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
                    delegate: SettingRow {
                        required property var modelData
                        label: Apps.byId(modelData)?.name || modelData
                        IconButton {
                            icon: "close"; tooltip: Lang.t("Kaldır")
                            onClicked: NiriConf.set("workspaces", (NiriConf.values.workspaces ?? []).map(w => w.name === workspaceGroup.modelData.name ? Object.assign({},w,{apps:(w.apps ?? []).filter(a => a !== modelData)}) : w))
                        }
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
                            NiriConf.set("workspaces", (NiriConf.values.workspaces ?? []).map(w => Object.assign({},w,{apps:(w.name === modelData.name ? [...new Set((w.apps ?? []).concat([app]))] : (w.apps ?? []).filter(a => a !== app))})))
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
