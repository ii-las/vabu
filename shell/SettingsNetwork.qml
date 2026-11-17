import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// Ağ ve Bluetooth. Durum ve işlemler yan paneldekilerle aynı servislerden gelir (Net, Bt).
ColumnLayout {
    id: page
    spacing: 24

    Component.onCompleted: { Net.refresh(); Net.scan(); Bt.setDiscovering(true) }
    Component.onDestruction: Bt.setDiscovering(false)
    Timer { interval: 12000; running: Net.askPassword === "" && Net.connecting === ""; repeat: true; onTriggered: Net.scan() }

    Group {
        title: "Wi‑Fi"
        SettingRow {
            label: "Wi‑Fi"
            sub: !Net.wifiAvailable ? "Bu bilgisayarda Wi‑Fi yok"
                : Net.kind === "wifi" ? Net.name + " ağına bağlı"
                : Net.wired !== "" ? "Kablolu bağlantı etkin: " + Net.wired : ""
            Spinner { visible: Net.scanning; anchors.verticalCenter: parent.verticalCenter; size: 17; color: Theme.muted }
            Toggle {
                visible: Net.wifiAvailable
                anchors.verticalCenter: parent.verticalCenter
                checked: Net.wifiOn
                onToggled: { Net.setWifi(!Net.wifiOn); rescan.start() }
            }
        }
        Timer { id: rescan; interval: 2500; onTriggered: Net.scan() }

        Repeater {
            model: Net.wifiOn ? Net.networks : []
            delegate: ColumnLayout {
                id: net
                required property var modelData
                readonly property bool asking: Net.askPassword === modelData.ssid
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 0

                ListRow {
                    icon: Net.signalIcon(net.modelData.signal)
                    label: net.modelData.ssid
                    sub: net.modelData.active ? "Bağlı"
                        : Net.connecting === net.modelData.ssid ? Lang.t("Bağlanıyor")
                        : (Net.known[net.modelData.ssid] ? "Kayıtlı · " : "") + (net.modelData.secure ? Lang.t("Şifreli") : Lang.t("Açık ağ"))
                    selected: net.modelData.active
                    busy: Net.connecting === net.modelData.ssid
                    trailing: net.modelData.secure && !Net.known[net.modelData.ssid] ? "lock" : ""
                    onClicked: Net.activate(net.modelData)
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: net.asking ? form.implicitHeight + 12 : 0
                    clip: true
                    Behavior on implicitHeight { NumberAnimation { duration: Config.reducedMotion ? 0 : 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                    ColumnLayout {
                        id: form
                        x: 44
                        width: Math.min(380, parent.width - 56)
                        spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Field {
                                id: pw
                                Layout.fillWidth: true
                                implicitHeight: 40
                                echoMode: TextInput.Password
                                placeholder: net.modelData.ssid + " şifresi"
                                onAccepted: if (text.length >= 8) Net.connect(net.modelData, text)
                            }
                            PillButton { implicitHeight: 40; primary: true; label: Lang.t("Bağlan"); enabled: pw.text.length >= 8; onClicked: Net.connect(net.modelData, pw.text) }
                        }
                        Text { textFormat: Text.PlainText; visible: Net.error !== ""; text: Net.error; color: Theme.danger; font.family: Theme.sans; font.pixelSize: Theme.textSmall}
                    }
                }
                onAskingChanged: if (asking) pw.focusField()
            }
        }
        Item { visible: Net.wifiOn && Net.networks.length > 0; implicitHeight: 4 }
    }

    RowLayout {
        spacing: 8
        PillButton { label: Lang.t("Yeniden tara"); icon: "refresh"; enabled: Net.wifiOn; onClicked: Net.scan() }
        PillButton { label: Lang.t("Gelişmiş ağ ayarları"); icon: "tune"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
    }

    PillButton { label: Lang.t("Bluetooth eşleştirme ve PIN"); onClicked: Quickshell.execDetached(["blueman-manager"]) }
    Group {
        title: Lang.t("Gizli ağ, kurumsal Wi-Fi ve VPN")
        note: Lang.t("Ağ düzenleyicisinde Wi-Fi güvenlik türünü ve gizli ağ seçeneğini seç. VPN eklerken sağlayıcının verdiği yapılandırmayı kullan.")
        PillButton { label: Lang.t("Wi-Fi bağlantısı ekle"); onClicked: Ui.run(["nm-connection-editor","--create","--type","wifi"]) }
        PillButton { label: Lang.t("VPN ekle"); onClicked: Ui.run(["nm-connection-editor","--create","--type","vpn"]) }
        Repeater {
            model: Bt.sorted.filter(d => d.paired)
            delegate: SettingRow { required property var modelData; label: modelData.name; PillButton { label: Lang.t("Eşleşmeyi kaldır"); onClicked: modelData.forget() } }
        }
    }
    Group {
        title: "Bluetooth"
        SettingRow {
            label: "Bluetooth"
            sub: !Bt.available ? "Bu bilgisayarda Bluetooth yok"
                : Bt.connected.length ? Bt.label + " bağlı" : ""
            Spinner { visible: Bt.isOn && Bt.discovering; anchors.verticalCenter: parent.verticalCenter; size: 17; color: Theme.muted }
            Toggle {
                visible: Bt.available
                anchors.verticalCenter: parent.verticalCenter
                checked: Bt.isOn
                onToggled: { Bt.setOn(!Bt.isOn); btScan.start() }
            }
        }
        Timer { id: btScan; interval: 1500; onTriggered: Bt.setDiscovering(true) }

        Repeater {
            model: Bt.isOn ? Bt.sorted : []
            delegate: ListRow {
                id: dev
                required property var modelData
                readonly property bool working: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                Layout.leftMargin: 4
                Layout.rightMargin: 4
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
        Item { visible: Bt.isOn && Bt.sorted.length > 0; implicitHeight: 4 }
    }
}
