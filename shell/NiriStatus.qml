import QtQuick
import QtQuick.Layouts

Rectangle {
    visible: NiriConf.status === "manual" || NiriConf.status === "invalid"
    implicitHeight: visible ? col.implicitHeight + 28 : 0
    radius: Theme.radiusTile
    color: Theme.alpha(Theme.warn, 0.08)
    border.width: 1
    border.color: Theme.alpha(Theme.warn, 0.5)

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
        Text { textFormat: Text.PlainText;
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: NiriConf.status === "manual"
                ? "niri ayar dosyan elle düzenlenmiş, bu yüzden pencere ayarları uygulanmadı."
                : "Bu ayar niri tarafından kabul edilmedi, uygulanmadı. Oturumun etkilenmedi."
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: Math.round((14) * Config.textScale)
        }
        Text { textFormat: Text.PlainText;
            Layout.fillWidth: true
            visible: NiriConf.lastError !== "" && NiriConf.status === "invalid"
            text: NiriConf.lastError
            color: Theme.soft
            font.family: Theme.mono
            font.pixelSize: Math.round((11) * Config.textScale)
            wrapMode: Text.Wrap
        }
        PillButton {
            visible: NiriConf.status === "manual"
            implicitHeight: 40
            label: Lang.t("Vabu yönetsin (eskisi yedeklenir)")
            onClicked: NiriConf.apply(true)
        }
    }
}
