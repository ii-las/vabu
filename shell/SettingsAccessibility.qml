import QtQuick
import QtQuick.Layouts
ColumnLayout {
    spacing: 18
    Group {
        title: Lang.t("Okunabilirlik")
        SettingRow { label: Lang.t("Yazı ölçeği"); Segmented { options: ["%100","%115","%130","%150"]; currentIndex: [1,1.15,1.3,1.5].indexOf(Config.textScale); onPicked: i => Config.set("textScale", [1,1.15,1.3,1.5][i]) } }
        SettingRow { label: Lang.t("Yüksek kontrast"); Toggle { checked: Config.highContrast; onToggled: Config.set("highContrast", !checked) } }
        SettingRow { label: Lang.t("Hareketi azalt"); Toggle { checked: Config.reducedMotion; onToggled: { Config.set("reducedMotion", !checked); NiriConf.set("animations", checked) } } }
        SettingRow { label: Lang.t("Cam efektleri"); Toggle { checked: Config.effects; onToggled: Config.set("effects", !checked) } }
    }
    Group {
        title: Lang.t("Dil")
        note: Lang.t("Vabu arayüzü için uygulanır. Uygulamaların ve sistemin dili ayrı olabilir.")
        SettingRow { label: Lang.t("Arayüz dili"); Segmented { options: ["Türkçe","English"]; currentIndex: Config.language === "en" ? 1 : 0; onPicked: i => Config.set("language", i === 1 ? "en" : "tr") } }
    }
    Group {
        title: Lang.t("Klavye kullanımı")
        note: Lang.t("Tab ile denetimler arasında, Enter veya Space ile etkinleştir. Başlatıcıda yukarı/aşağı oklarıyla sonuç seç.")
        PillButton { label: Lang.t("Kısayolları göster"); onClicked: Ui.run(["qs","-p","/usr/share/vabu/shell","ipc","call","shortcuts","toggle"]) }
    }
}
