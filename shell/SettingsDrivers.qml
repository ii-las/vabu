import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 16

    property var st: null
    property bool loading: true

    function refresh() { loading = true; status.running = true }
    Component.onCompleted: refresh()

    Process {
        id: status
        command: ["vabu-drivers", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.st = JSON.parse(text) } catch (e) { page.st = null }
                page.loading = false
            }
        }
    }

    function run(what) { Ui.terminal(["sh", "-c", "vabu-drivers install " + what + "; echo; read -p 'Kapatmak için Enter…' _"]) }

    readonly property string nv: st ? st.nvidia : "none"
    readonly property var nvText: ({
        "missing": { title: "Önerilen sürücü kurulu değil", body: "Kart şu an açık kaynak sürücüyle (nouveau) çalışıyor. Oyun, video hızlandırma ve güç yönetimi için NVIDIA sürücüsünü kur.", btn: "Sürücüyü kur", kind: "warn" },
        "pending-reboot": { title: "Sürücü kuruldu", body: "Devreye girmesi için bilgisayarı yeniden başlat. Secure Boot açıksa açılışta mavi ekranda 'Enroll MOK' adımını tamamla.", btn: "Yeniden başlat", kind: "info" },
        "active": { title: "NVIDIA sürücüsü etkin", body: "Kart tam performansla çalışıyor. Çekirdek güncellemelerinde sürücü kendiliğinden yeniden derlenir.", btn: "", kind: "ok" }
    })

    Text {
        visible: page.loading
        text: "Donanım denetleniyor…"
        color: Theme.muted; font.family: Theme.serif; font.italic: true; font.pixelSize: 22
    }

    // NVIDIA kartı
    Rectangle {
        Layout.fillWidth: true
        visible: !page.loading && page.nv !== "none"
        implicitHeight: nvCol.implicitHeight + 44
        radius: 20
        readonly property color tone: page.nv === "active" ? Theme.mint : Theme.sky
        color: Qt.rgba(tone.r, tone.g, tone.b, 0.08)
        border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.4)

        ColumnLayout {
            id: nvCol
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Rectangle {
                    implicitWidth: 52; implicitHeight: 52; radius: 14
                    color: Theme.sky
                    Text { anchors.centerIn: parent; text: "GPU"; color: Theme.skyInk; font.family: Theme.mono; font.pixelSize: 12 }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: (page.st?.gpus ?? []).find(g => /nvidia/i.test(g)) ?? "NVIDIA ekran kartı"
                        color: Theme.paper; font.family: Theme.serif; font.pixelSize: 24; elide: Text.ElideRight
                    }
                    Text { text: page.nvText[page.nv]?.title ?? ""; color: Theme.soft; font.family: Theme.sans; font.pixelSize: 13 }
                }
                PillButton {
                    visible: (page.nvText[page.nv]?.btn ?? "") !== ""
                    primary: true
                    label: page.nvText[page.nv]?.btn ?? ""
                    onClicked: page.nv === "pending-reboot" ? Ui.run(["systemctl", "reboot"]) : page.run("nvidia")
                }
            }
            Text {
                Layout.fillWidth: true
                text: page.nvText[page.nv]?.body ?? ""
                color: Theme.soft; font.family: Theme.sans; font.pixelSize: 13; wrapMode: Text.Wrap; lineHeight: 1.2
            }
            RowLayout {
                spacing: 8
                Chip { text: "RPM FUSION"; kind: page.st?.rpmfusion ? "ok" : "warn" }
                Chip { text: page.st?.secureBoot ? "SECURE BOOT AÇIK" : "SECURE BOOT KAPALI"; kind: "info" }
                Chip { visible: page.st?.intel || page.st?.amd; text: "HİBRİT GRAFİK"; kind: "info" }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !page.loading
        spacing: 0
        SectionLabel { text: "Donanım" }
        DashLine { Layout.fillWidth: true }

        Repeater {
            model: (page.st?.gpus ?? []).filter(g => !/nvidia/i.test(g))
            delegate: SettingRow {
                required property var modelData
                label: modelData
                sub: "Mesa · OpenGL, Vulkan, donanım video hızlandırma"
                Chip { text: "HAZIR"; kind: "ok" }
            }
        }
        SettingRow {
            label: "Medya codec'leri"
            sub: "H.264, HEVC, AAC ve diğerleri · RPM Fusion"
            Chip { visible: page.st?.codecs ?? false; text: "KURULU"; kind: "ok" }
            PillButton { visible: !(page.st?.codecs ?? true); implicitHeight: 38; primary: true; label: "Kur"; onClicked: page.run("codecs") }
        }
        SettingRow {
            visible: page.st?.amd ?? false
            label: "AMD donanım video hızlandırma"
            sub: "VA-API / VDPAU (RPM Fusion)"
            PillButton { implicitHeight: 38; label: "Denetle ve kur"; onClicked: page.run("amd") }
        }
        SettingRow {
            visible: page.st?.intel ?? false
            label: "Intel donanım video hızlandırma"
            sub: "intel-media-driver (RPM Fusion)"
            PillButton { implicitHeight: 38; label: "Denetle ve kur"; onClicked: page.run("intel") }
        }
    }

    RowLayout {
        spacing: 10
        PillButton { label: "Önerilen her şeyi kur"; primary: true; onClicked: page.run("auto") }
        PillButton { label: "Yeniden denetle"; icon: "restart"; onClicked: page.refresh() }
    }
    Text {
        Layout.fillWidth: true
        text: "Kurulumdan önce otomatik bir geri alma noktası alınır; bir sorun olursa Güncellemeler sayfasından geri dönebilirsin."
        color: Theme.muted; font.family: Theme.sans; font.pixelSize: 12; wrapMode: Text.Wrap
    }
}
