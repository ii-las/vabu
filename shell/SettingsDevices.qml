import QtQuick
import QtQuick.Layouts
import Quickshell
ColumnLayout {
    spacing: 18
    Group {
        title: Lang.t("Yazıcı ve tarayıcı")
        note: Lang.t("Ağ ve USB cihazlarını ilgili araçta seç. Yeni cihaz ekleme işlemi gerektiğinde sistem yetkilendirmesi ister.")
        PillButton { label: Lang.t("Yazıcıları yönet"); icon: "print"; onClicked: Ui.run(["system-config-printer"]) }
        PillButton { label: Lang.t("Belge tara"); icon: "scanner"; onClicked: Ui.run(["simple-scan"]) }
    }
    Group {
        title: Lang.t("Diskler ve çıkarılabilir cihazlar")
        note: Lang.t("Dosyalar uygulamasının yan panelinden bağla veya güvenle çıkar. Disk yönetiminde biçimlendirme gibi işlemleri yalnızca doğru cihazı seçtikten sonra uygula.")
        PillButton { label: Lang.t("Dosyalar"); onClicked: Ui.run(["nautilus"]) }
        PillButton { label: Lang.t("Diskleri yönet"); onClicked: Ui.run(["gnome-disks"]) }
    }
    Group {
        title: Lang.t("Ekran paylaşımı")
        note: Lang.t("Paylaşımı tarayıcı veya görüşme uygulamasından başlat. Portalın seçim ekranında pencereyi ya da monitörü seç. Paylaşım izni kendiliğinden verilmez.")
        PillButton { label: Lang.t("Portal durumunu denetle"); onClicked: Ui.settings("health") }
    }
    Group {
        title: Lang.t("Uygulama izinleri ve varsayılanlar")
        PillButton { label: Lang.t("Varsayılan uygulamalar"); onClicked: Ui.settings("apps") }
        PillButton { label: Lang.t("Flatpak izinleri"); enabled: Apps.byId("com.github.tchx84.Flatseal") !== null; onClicked: Apps.launch(Apps.byId("com.github.tchx84.Flatseal")) }
    }
}
