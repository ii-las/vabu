import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 6

    PanelHeader {
        title: Lang.t("Bildirimler")
        sub: Notifs.effectiveDnd ? "Rahatsız etme açık" : Notifs.count === 0 ? "" : Notifs.count + " bildirim"
        IconButton {
            implicitWidth: 34; implicitHeight: 34
            icon: Notifs.effectiveDnd ? "notifications_off" : "notifications"
            iconSize: 19
            active: Notifs.effectiveDnd
            tooltip: Lang.t("Rahatsız etme")
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        IconButton {
            visible: Notifs.count > 0
            implicitWidth: 34; implicitHeight: 34
            icon: "clear_all"
            iconSize: 20
            iconColor: Theme.soft
            tooltip: Lang.t("Tümünü temizle")
            onClicked: Notifs.clearAll()
        }
    }

    Flickable {
        id: flick
        Layout.fillWidth: true
        implicitHeight: Math.min(list.implicitHeight, 520)
        contentHeight: list.implicitHeight
        clip: true
        visible: Notifs.count > 0
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: flick.width
            spacing: 6
            Repeater {
                model: Notifs.all.slice().reverse()
                delegate: NotificationCard {
                    required property var modelData
                    Layout.fillWidth: true
                    notif: modelData
                }
            }
        }
    }

    ColumnLayout {
        visible: Notifs.count === 0
        Layout.fillWidth: true
        Layout.topMargin: 26
        Layout.bottomMargin: 30
        spacing: 10
        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "notifications"
            size: 30
            weight: 200
            color: Theme.faint
        }
        Text { textFormat: Text.PlainText;
            Layout.alignment: Qt.AlignHCenter
            text: Lang.t("Yeni bildirim yok")
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: Theme.textSmall
        }
    }
}
