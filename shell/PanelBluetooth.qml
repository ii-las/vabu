import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
    id: root
    spacing: 4

    // Panel açıkken yakındaki cihazlar aranır
    Component.onCompleted: Bt.setDiscovering(true)
    Component.onDestruction: Bt.setDiscovering(false)

    PanelHeader {
        title: "Bluetooth"
        sub: !Bt.available ? "Bu bilgisayarda Bluetooth yok"
            : !Bt.isOn ? Lang.t("Kapalı")
            : Bt.connected.length ? Bt.label + " bağlı" : "Yakındaki cihazlar aranıyor"
        Spinner {
            visible: Bt.isOn && Bt.discovering
            anchors.verticalCenter: parent.verticalCenter
            size: 17
            color: Theme.muted
        }
        Toggle {
            visible: Bt.available
            anchors.verticalCenter: parent.verticalCenter
            checked: Bt.isOn
            onToggled: { Bt.setOn(!Bt.isOn); scanSoon.start() }
        }
    }
    Timer { id: scanSoon; interval: 1500; onTriggered: Bt.setDiscovering(true) }

    Flickable {
        id: flick
        Layout.fillWidth: true
        implicitHeight: Math.min(list.implicitHeight, 372)
        contentHeight: list.implicitHeight
        clip: true
        visible: Bt.isOn && Bt.sorted.length > 0
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: flick.width
            spacing: 2
            Repeater {
                model: Bt.isOn ? Bt.sorted : []
                delegate: ListRow {
                    required property var modelData
                    readonly property bool working: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                    icon: Bt.deviceIcon(modelData)
                    label: modelData.name || modelData.address
                    sub: working ? (modelData.pairing ? Lang.t("Eşleştiriliyor") : Lang.t("Bağlanıyor"))
                        : modelData.connected ? (modelData.batteryAvailable ? "Bağlı · pil %" + Math.round(modelData.battery * 100) : "Bağlı")
                        : modelData.paired ? Lang.t("Eşleşmiş") : "Eşleştirmek için tıkla"
                    selected: modelData.connected
                    busy: working
                    onClicked: Bt.activate(modelData)
                }
            }
        }
    }

    Text { textFormat: Text.PlainText;
        visible: Bt.available && Bt.isOn && Bt.sorted.length === 0
        Layout.fillWidth: true
        Layout.topMargin: 18
        Layout.bottomMargin: 18
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: Lang.t("Yakında cihaz yok")
        color: Theme.muted
        font.family: Theme.sans
        font.pixelSize: Theme.textSmall
        lineHeight: 1.2
    }

    PillButton { label: Lang.t("Bluetooth eşleştirme ve PIN"); onClicked: Quickshell.execDetached(["blueman-manager"]) }
    DashLine { Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4 }
    ListRow {
        icon: "settings"
        label: Lang.t("Bluetooth ayarları")
        iconColor: Theme.soft
        trailing: "chevron_right"
        onClicked: Ui.settings("network")
    }
}
