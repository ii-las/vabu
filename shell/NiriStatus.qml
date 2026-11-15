import QtQuick
import QtQuick.Layouts

Rectangle {
    visible: NiriConf.status === "manual" || NiriConf.status === "invalid"
    implicitHeight: visible ? col.implicitHeight + 28 : 0
    radius: 16
    color: Qt.rgba(242 / 255, 180 / 255, 138 / 255, 0.1)
    border.color: Theme.peach

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: NiriConf.status === "manual"
                ? "niri ayar dosyan elle düzenlenmiş, bu yüzden pencere ayarları uygulanmadı."
                : "Bu ayar niri tarafından kabul edilmedi, uygulanmadı. Oturumun etkilenmedi."
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: 14
        }
        Text {
            Layout.fillWidth: true
            visible: NiriConf.lastError !== "" && NiriConf.status === "invalid"
            text: NiriConf.lastError
            color: Theme.soft
            font.family: Theme.mono
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
        PillButton {
            visible: NiriConf.status === "manual"
            implicitHeight: 40
            label: "Vabu yönetsin (eskisi yedeklenir)"
            onClicked: NiriConf.apply(true)
        }
    }
}
