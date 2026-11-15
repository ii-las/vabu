import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 20

    property bool wifiOn: true
    property var networks: []         // [{ssid, signal, secure, active, known}]
    property var known: ({})
    property string wired: ""
    property string connecting: ""
    property string askPassword: ""   // şifre sorulan SSID
    property string netError: ""

    property bool btOn: false
    property bool btAvailable: false
    property var btDevices: []        // [{mac, name, connected, paired}]
    property bool btScanning: false

    // nmcli -t çıktısında ":" kaçışlı gelir (\:)
    function splitNm(line) {
        const out = []; let cur = ""
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (line[i] === ":") { out.push(cur); cur = ""; continue }
            cur += line[i]
        }
        out.push(cur)
        return out
    }

    function refresh() {
        radio.running = true
        scan.running = true
        saved.running = true
        devices.running = true
        btShow.running = true
    }
    Component.onCompleted: refresh()
    Timer { interval: 10000; running: true; repeat: true; onTriggered: page.refresh() }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: page.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: saved
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const k = {}
                for (const l of text.split("\n")) { const [n, t] = page.splitNm(l); if (t && t.includes("wireless")) k[n] = true }
                page.known = k
            }
        }
    }
    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                for (const l of text.split("\n")) {
                    const [use, ssid, signal, sec] = page.splitNm(l)
                    if (!ssid) continue
                    const s = parseInt(signal) || 0
                    if (seen[ssid] && seen[ssid].signal >= s && !use.includes("*")) continue
                    seen[ssid] = { ssid, signal: s, secure: !!sec && sec !== "--", active: use.includes("*") }
                }
                page.networks = Object.values(seen).sort((a, b) => b.active - a.active || b.signal - a.signal).slice(0, 12)
            }
        }
    }
    Process {
        id: devices
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.wired = ""
                for (const l of text.split("\n")) {
                    const [t, s, c] = page.splitNm(l)
                    if (t === "ethernet" && s === "connected") page.wired = c
                }
            }
        }
    }
    Process {
        id: connector
        stderr: StdioCollector { id: connErr }
        onExited: code => {
            page.netError = code === 0 ? "" : (connErr.text.trim() || "Bağlanılamadı.")
            if (code === 0) page.askPassword = ""
            page.connecting = ""
            page.refresh()
        }
    }

    function connect(net, password) {
        connecting = net.ssid
        netError = ""
        if (known[net.ssid]) connector.command = ["nmcli", "connection", "up", "id", net.ssid]
        else if (net.secure) connector.command = ["nmcli", "device", "wifi", "connect", net.ssid, "password", password]
        else connector.command = ["nmcli", "device", "wifi", "connect", net.ssid]
        connector.running = true
    }

    // --- Bluetooth ---
    Process {
        id: btShow
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.btAvailable = text.includes("Controller")
                page.btOn = /Powered:\s*yes/.test(text)
                if (page.btAvailable) btList.running = true
            }
        }
    }
    Process {
        id: btList
        command: ["sh", "-c", "for m in $(bluetoothctl devices | awk '{print $2}'); do bluetoothctl info \"$m\" | awk -v m=\"$m\" '/Name:/{sub(/^[ \\t]*Name: /,\"\");n=$0} /Paired:/{p=$2} /Connected:/{c=$2} END{print m\"\\t\"n\"\\t\"p\"\\t\"c}'; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.btDevices = text.split("\n").filter(l => l).map(l => {
                    const [mac, name, paired, connected] = l.split("\t")
                    return { mac, name: name || mac, paired: paired === "yes", connected: connected === "yes" }
                }).sort((a, b) => b.connected - a.connected || b.paired - a.paired)
            }
        }
    }
    Process {
        id: btScan
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        onExited: { page.btScanning = false; btList.running = true }
    }
    Process {
        id: btAction
        onExited: btList.running = true
    }

    // ------------------------------------------------------------------ Arayüz
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        SectionLabel { text: "WI‑FI" }
        DashLine { Layout.fillWidth: true }
        SettingRow {
            label: "Wi‑Fi"
            sub: page.wired ? "Kablolu bağlantı da etkin: " + page.wired : ""
            Toggle {
                checked: page.wifiOn
                onToggled: { Quickshell.execDetached(["nmcli", "radio", "wifi", page.wifiOn ? "off" : "on"]); page.wifiOn = !page.wifiOn }
            }
        }

        Repeater {
            model: page.wifiOn ? page.networks : []
            delegate: ColumnLayout {
                id: net
                required property var modelData
                Layout.fillWidth: true
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 58
                    RowLayout {
                        anchors.fill: parent
                        spacing: 14
                        Icon { name: "wifi"; color: net.modelData.signal > 60 ? Theme.paper : net.modelData.signal > 30 ? Theme.soft : Theme.faint }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: net.modelData.ssid; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 15; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text {
                                text: (net.modelData.active ? "Bağlı · " : page.known[net.modelData.ssid] ? "Kayıtlı · " : "") + (net.modelData.secure ? "Şifreli" : "Açık ağ") + " · %" + net.modelData.signal
                                color: net.modelData.active ? Theme.mint : Theme.muted
                                font.family: Theme.sans; font.pixelSize: 12
                            }
                        }
                        PillButton {
                            implicitHeight: 38
                            primary: !net.modelData.active
                            label: page.connecting === net.modelData.ssid ? "Bağlanıyor…" : net.modelData.active ? "Bağlantıyı kes" : "Bağlan"
                            onClicked: {
                                if (net.modelData.active) Quickshell.execDetached(["nmcli", "connection", "down", "id", net.modelData.ssid])
                                else if (net.modelData.secure && !page.known[net.modelData.ssid]) page.askPassword = net.modelData.ssid
                                else page.connect(net.modelData, "")
                            }
                        }
                    }
                }
                RowLayout {
                    visible: page.askPassword === net.modelData.ssid
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    spacing: 8
                    Field {
                        id: pw
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholder: net.modelData.ssid + " şifresi"
                        onAccepted: page.connect(net.modelData, text)
                        onVisibleChanged: if (visible) focusField()
                    }
                    PillButton { primary: true; implicitHeight: 42; label: "Bağlan"; onClicked: page.connect(net.modelData, pw.text) }
                }
                Text {
                    visible: page.netError !== "" && page.askPassword === net.modelData.ssid
                    Layout.bottomMargin: 10
                    text: page.netError
                    color: Theme.coral
                    font.family: Theme.sans
                    font.pixelSize: 12
                }
                DashLine { Layout.fillWidth: true }
            }
        }
        RowLayout {
            Layout.topMargin: 14
            spacing: 10
            PillButton { label: "Yeniden tara"; icon: "restart"; onClicked: page.refresh() }
            PillButton { label: "Gelişmiş ağ ayarları"; icon: "sliders"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 0
        SectionLabel { text: "BLUETOOTH" }
        DashLine { Layout.fillWidth: true }
        SettingRow {
            label: "Bluetooth"
            sub: page.btAvailable ? "" : "Bu bilgisayarda Bluetooth bulunamadı"
            Toggle {
                visible: page.btAvailable
                checked: page.btOn
                onToggled: { Quickshell.execDetached(["bluetoothctl", "power", page.btOn ? "off" : "on"]); page.btOn = !page.btOn }
            }
        }
        Repeater {
            model: page.btOn ? page.btDevices : []
            delegate: SettingRow {
                required property var modelData
                label: modelData.name
                sub: modelData.connected ? "Bağlı" : modelData.paired ? "Eşleştirilmiş" : "Yakında"
                PillButton {
                    implicitHeight: 38
                    primary: !modelData.connected
                    label: modelData.connected ? "Bağlantıyı kes" : modelData.paired ? "Bağlan" : "Eşleştir"
                    onClicked: {
                        const m = modelData.mac
                        btAction.command = modelData.connected ? ["bluetoothctl", "disconnect", m]
                            : modelData.paired ? ["bluetoothctl", "connect", m]
                            : ["sh", "-c", "bluetoothctl pair " + m + " && bluetoothctl trust " + m + " && bluetoothctl connect " + m]
                        btAction.running = true
                    }
                }
            }
        }
        PillButton {
            visible: page.btOn
            Layout.topMargin: 14
            label: page.btScanning ? "Aranıyor…" : "Yeni cihaz ara"
            icon: "bluetooth"
            onClicked: { if (!page.btScanning) { page.btScanning = true; btScan.running = true } }
        }
    }
}
