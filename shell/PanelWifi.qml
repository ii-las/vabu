import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 4

    Component.onCompleted: Net.scan()
    // Şifre yazılırken liste yenilenmez: satırlar yeniden kurulursa yazılan silinir
    Timer { interval: 12000; running: Net.askPassword === "" && Net.connecting === ""; repeat: true; onTriggered: Net.scan() }

    PanelHeader {
        title: "Wi‑Fi"
        sub: !Net.wifiAvailable ? "Bu bilgisayarda Wi‑Fi yok"
            : !Net.wifiOn ? Lang.t("Kapalı")
            : Net.kind === "wifi" ? Net.name + " ağına bağlı" : Lang.t("Bağlı değil")
        IconButton {
            visible: Net.wifiOn
            implicitWidth: 34; implicitHeight: 34
            icon: "refresh"
            iconSize: 19
            iconColor: Theme.soft
            tooltip: Lang.t("Yeniden tara")
            onClicked: Net.scan()
            rotation: Net.scanning ? 360 : 0
            Behavior on rotation { enabled: Net.scanning; NumberAnimation { duration: Config.reducedMotion ? 0 : 900; easing.type: Easing.InOutCubic } }
        }
        Toggle {
            visible: Net.wifiAvailable
            anchors.verticalCenter: parent.verticalCenter
            checked: Net.wifiOn
            onToggled: { Net.setWifi(!Net.wifiOn); if (Net.wifiOn) rescan.start() }
        }
    }
    Timer { id: rescan; interval: 2500; onTriggered: Net.scan() }

    ListRow {
        visible: Net.wired !== ""
        icon: "lan"
        label: Net.wired
        sub: Lang.t("Kablolu bağlantı")
        selected: true
    }

    Flickable {
        id: flick
        Layout.fillWidth: true
        implicitHeight: Math.min(list.implicitHeight, 372)
        contentHeight: list.implicitHeight
        clip: true
        visible: Net.wifiOn && Net.networks.length > 0
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: flick.width
            spacing: 2

            Repeater {
                model: Net.wifiOn ? Net.networks : []
                delegate: ColumnLayout {
                    id: net
                    required property var modelData
                    readonly property bool asking: Net.askPassword === modelData.ssid
                    Layout.fillWidth: true
                    spacing: 0

                    ListRow {
                        icon: Net.signalIcon(net.modelData.signal)
                        label: net.modelData.ssid
                        sub: net.modelData.active ? "Bağlı"
                            : Net.connecting === net.modelData.ssid ? Lang.t("Bağlanıyor")
                            : Net.known[net.modelData.ssid] ? Lang.t("Kayıtlı") : ""
                        selected: net.modelData.active
                        busy: Net.connecting === net.modelData.ssid
                        trailing: net.modelData.secure && !Net.known[net.modelData.ssid] ? "lock" : ""
                        onClicked: Net.activate(net.modelData)
                    }

                    // Şifre: satırın hemen altında açılır
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: net.asking ? form.implicitHeight + 10 : 0
                        clip: true
                        Behavior on implicitHeight { NumberAnimation { duration: Config.reducedMotion ? 0 : 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

                        ColumnLayout {
                            id: form
                            x: 12
                            width: parent.width - 24
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Field {
                                    id: pw
                                    Layout.fillWidth: true
                                    implicitHeight: 40
                                    echoMode: TextInput.Password
                                    placeholder: Lang.t("Şifre")
                                    onAccepted: if (text.length >= 8) Net.connect(net.modelData, text)
                                }
                                IconButton {
                                    implicitWidth: 40; implicitHeight: 40
                                    icon: "arrow_forward"
                                    active: pw.text.length >= 8
                                    tooltip: Lang.t("Bağlan")
                                    onClicked: if (pw.text.length >= 8) Net.connect(net.modelData, pw.text)
                                }
                            }
                            Text { textFormat: Text.PlainText;
                                visible: Net.error !== ""
                                text: Net.error
                                color: Theme.danger
                                font.family: Theme.sans
                                font.pixelSize: Math.round((12) * Config.textScale)
                            }
                        }
                    }
                    onAskingChanged: if (asking) pw.focusField()
                }
            }
        }
    }

    Text { textFormat: Text.PlainText;
        visible: Net.wifiOn && Net.networks.length === 0
        Layout.fillWidth: true
        Layout.topMargin: 18
        Layout.bottomMargin: 18
        horizontalAlignment: Text.AlignHCenter
        text: Net.scanning ? "Ağlar aranıyor…" : "Yakında ağ bulunamadı"
        color: Theme.muted
        font.family: Theme.sans
        font.pixelSize: Math.round((13) * Config.textScale)
    }

    DashLine { Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4 }
    ListRow {
        icon: "settings"
        label: Lang.t("Ağ ayarları")
        iconColor: Theme.soft
        trailing: "chevron_right"
        onClicked: Ui.settings("network")
    }
}
