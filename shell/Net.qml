pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ağ durumu (NetworkManager). Değişiklikleri `nmcli monitor` ile dinler; yoklama yapmaz.
Singleton {
    id: root

    property bool wifiAvailable: false
    property bool wifiOn: false
    property string kind: "none"          // wifi | ethernet | none
    property string name: ""              // bağlı ağın adı
    property string wired: ""
    property int strength: 0              // bağlı Wi‑Fi sinyali, 0-100
    property var networks: []             // [{ssid, signal, secure, active}]
    property var known: ({})              // kayıtlı ağ adları
    property bool scanning: false
    property string connecting: ""
    property string askPassword: ""       // şifresi sorulan ağ
    property string error: ""

    readonly property string icon: kind === "ethernet" ? "lan"
        : kind === "wifi" ? signalIcon(strength)
        : wifiOn ? "wifi_find" : "wifi_off"
    readonly property string label: kind === "none" ? (wifiOn ? "Bağlı değil" : "Kapalı") : name

    function signalIcon(s) {
        return s >= 75 ? "signal_wifi_4_bar" : s >= 50 ? "network_wifi_3_bar" : s >= 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
    }

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

    function refresh() { status.running = true }
    function scan() {
        if (!wifiOn) return
        scanning = true
        list.command = ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
        list.running = true
        saved.running = true
    }
    function setWifi(isOn) {
        wifiOn = isOn
        if (!isOn) networks = []
        Quickshell.execDetached(["nmcli", "radio", "wifi", isOn ? "on" : "off"])
    }
    function disconnect(ssid) {
        Quickshell.execDetached(["nmcli", "connection", "down", "id", ssid])
    }
    function forget(ssid) {
        Quickshell.execDetached(["nmcli", "connection", "delete", "id", ssid])
    }

    // Bağlan. Şifre komut satırına yazılmaz: standart girdiden okunur, geçici bir dosyaya
    // yazılır ve "connection up" ona passwd-file ile verilir; dosya hemen silinir.
    // Yeni bir şifreli ağ için önce şifresiz bir bağlantı kaydı açılır, olmazsa geri silinir.
    readonly property string withSecret:
        "umask 077; f=$(mktemp -p \"${XDG_RUNTIME_DIR:-/tmp}\" vabu-ag.XXXXXX) || exit 1; " +
        "IFS= read -r p; printf '802-11-wireless-security.psk:%s\\n' \"$p\" > \"$f\"; " +
        "if [ \"$2\" = yeni ]; then " +
        "  nmcli connection add type wifi con-name \"$1\" ifname '*' ssid \"$1\" wifi-sec.key-mgmt wpa-psk >/dev/null || { rm -f \"$f\"; exit 1; }; " +
        "fi; " +
        "nmcli -w 25 connection up id \"$1\" passwd-file \"$f\"; r=$?; rm -f \"$f\"; " +
        "if [ $r -ne 0 ] && [ \"$2\" = yeni ]; then nmcli connection delete id \"$1\" >/dev/null 2>&1; fi; " +
        "exit $r"

    function connect(net, password) {
        connecting = net.ssid
        error = ""
        connector.target = net
        connector.usedPassword = password !== ""
        if (password !== "") {
            connector.pending = password
            connector.command = ["sh", "-c", withSecret, "sh", net.ssid, known[net.ssid] ? "kayitli" : "yeni"]
        } else if (known[net.ssid]) {
            connector.pending = ""
            connector.command = ["nmcli", "-w", "25", "connection", "up", "id", net.ssid]
        } else {
            connector.pending = ""
            connector.command = ["nmcli", "-w", "25", "device", "wifi", "connect", net.ssid]
        }
        connector.running = true
    }
    function activate(net) {
        if (net.active) { disconnect(net.ssid); return }
        if (net.secure && !known[net.ssid]) { askPassword = askPassword === net.ssid ? "" : net.ssid; error = ""; return }
        connect(net, "")
    }

    function friendly(text) {
        const t = text.toLowerCase()
        if (t.includes("secrets were required") || t.includes("802-11-wireless-security") || t.includes("password")) return "Şifre yanlış görünüyor."
        if (t.includes("no network with ssid")) return "Ağ artık görünmüyor."
        if (t.includes("timeout")) return "Ağ yanıt vermedi."
        return "Bağlanılamadı."
    }

    Process {
        id: status
        environment: ({ "LC_ALL": "C" })
        command: ["sh", "-c", "nmcli radio wifi; echo ---; nmcli -t -f TYPE,STATE,CONNECTION device; echo ---; nmcli -t -f IN-USE,SIGNAL device wifi list --rescan no 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---\n")
                root.wifiOn = (parts[0] ?? "").trim() === "enabled"
                let kind = "none", name = "", wired = "", hasWifi = false
                for (const l of (parts[1] ?? "").split("\n")) {
                    const [type, state, conn] = root.splitNm(l)
                    if (type === "wifi") hasWifi = true
                    if (state !== "connected") continue
                    if (type === "ethernet") { wired = conn; kind = "ethernet"; name = conn }
                    else if (type === "wifi" && kind !== "ethernet") { kind = "wifi"; name = conn }
                }
                let strength = 0
                for (const l of (parts[2] ?? "").split("\n")) {
                    const [use, signal] = root.splitNm(l)
                    if (use && use.includes("*")) strength = parseInt(signal) || 0
                }
                root.wifiAvailable = hasWifi
                root.kind = kind
                root.name = name
                root.wired = wired
                root.strength = strength
            }
        }
    }
    Process {
        id: list
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                for (const l of text.split("\n")) {
                    const [use, ssid, signal, sec] = root.splitNm(l)
                    if (!ssid) continue
                    const s = parseInt(signal) || 0
                    const active = use.includes("*")
                    if (seen[ssid] && !active && (seen[ssid].active || seen[ssid].signal >= s)) continue
                    seen[ssid] = { ssid: ssid, signal: s, secure: !!sec && sec !== "--", active: active }
                }
                root.networks = Object.values(seen).sort((a, b) => b.active - a.active || b.signal - a.signal).slice(0, 14)
                root.scanning = false
            }
        }
        onExited: root.scanning = false
    }
    Process {
        id: saved
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const k = {}
                for (const l of text.split("\n")) { const [n, t] = root.splitNm(l); if (t && t.includes("wireless")) k[n] = true }
                root.known = k
            }
        }
    }
    Process {
        id: connector
        environment: ({ "LC_ALL": "C" })
        property string pending: ""
        property var target: null
        property bool usedPassword: false
        stdinEnabled: true
        stderr: StdioCollector { id: connErr }
        onStarted: { if (pending !== "") { write(pending + "\n"); pending = "" } }
        onExited: code => {
            root.error = code === 0 ? "" : root.friendly(connErr.text)
            if (code === 0) root.askPassword = ""
            // Kayıtlı ağın şifresi değişmiş olabilir: şifre alanını aç ki yenisi girilebilsin
            else if (target && target.secure) root.askPassword = target.ssid
            root.connecting = ""
            root.refresh()
            root.scan()
        }
    }

    // Olaylar: bağlantı kurulunca, kopunca, cihaz takılınca satır basar
    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: _ => settle.restart() }
        onExited: monitorRetry.start()
    }
    Timer { id: monitorRetry; interval: 5000; onTriggered: monitor.running = true }
    Timer { id: settle; interval: 400; onTriggered: root.refresh() }
    // Sinyal gücü olay üretmez; seyrek bir tazeleme yeter
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
