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
        "installed-inactive": { title: "Sürücü etkin değil", body: "Paket kurulu, fakat çekirdek modülü yüklenmedi. Yeniden başlatma, akmods derlemesi ve Secure Boot/MOK durumunu denetle.", btn: "", kind: "warn" },
        "active": { title: "NVIDIA sürücüsü etkin", body: "Kart tam performansla çalışıyor. Çekirdek güncellemelerinde sürücü kendiliğinden yeniden derlenir.", btn: "", kind: "ok" }
    })

    RowLayout {
        visible: page.loading
        spacing: 10
        Spinner { size: 18 }
        Text { text: "Donanım denetleniyor"; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 14 }
    }

    // NVIDIA kartı
    Rectangle {
        Layout.fillWidth: true
        visible: !page.loading && page.nv !== "none"
        implicitHeight: nvCol.implicitHeight + 36
        radius: Theme.radiusTile
        color: Theme.group
        border.width: 1
        border.color: page.nv === "active" ? Theme.groupEdge : Theme.alpha(Theme.warn, 0.5)

        ColumnLayout {
            id: nvCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Rectangle {
                    implicitWidth: 46; implicitHeight: 46; radius: 14
                    color: Theme.well
                    Icon { anchors.centerIn: parent; name: "developer_board"; size: 24 }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: (page.st?.gpus ?? []).find(g => /nvidia/i.test(g)) ?? "NVIDIA ekran kartı"
                        color: Theme.paper; font.family: Theme.sans; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideRight
                    }
                    Text { text: page.nvText[page.nv]?.title ?? ""; color: Theme.soft; font.family: Theme.sans; font.pixelSize: 13 }
                }
                PillButton {
                    visible: (page.nvText[page.nv]?.btn ?? "") !== ""
                    primary: true
                    label: page.nvText[page.nv]?.btn ?? ""
                    onClicked: page.run("nvidia")
                }
            }
            Text {
                Layout.fillWidth: true
                text: page.nvText[page.nv]?.body ?? ""
                color: Theme.soft; font.family: Theme.sans; font.pixelSize: 13; wrapMode: Text.Wrap; lineHeight: 1.25
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Chip { text: page.st?.rpmfusion ? "RPM Fusion açık" : "RPM Fusion kapalı"; kind: page.st?.rpmfusion ? "ok" : "warn" }
                Chip { text: page.st?.secureBoot ? "Secure Boot açık" : "Secure Boot kapalı"; kind: "info" }
                Chip { visible: (page.st?.intel || page.st?.amd) ?? false; text: "Hibrit grafik"; kind: "info" }
            }
        }
    }

    Group {
        visible: !page.loading
        title: "Donanım"

        Repeater {
            model: (page.st?.gpus ?? []).filter(g => !/nvidia/i.test(g))
            delegate: SettingRow {
                required property var modelData
                label: modelData
                sub: "Mesa"
                Chip { text: "Hazır"; kind: "ok" }
            }
        }
        SettingRow {
            label: "Medya codec'leri"
            sub: ""
            Chip { visible: page.st?.codecs ?? false; text: "Kurulu"; kind: "ok" }
            PillButton { visible: !(page.st?.codecs ?? true); implicitHeight: 36; primary: true; label: "Kur"; onClicked: page.run("codecs") }
        }
        SettingRow {
            visible: page.st?.amd ?? false
            label: "AMD donanım video hızlandırma"
            sub: ""
            PillButton { implicitHeight: 36; label: "Kur"; onClicked: page.run("amd") }
        }
        SettingRow {
            visible: page.st?.intel ?? false
            label: "Intel donanım video hızlandırma"
            sub: ""
            PillButton { implicitHeight: 36; label: "Kur"; onClicked: page.run("intel") }
        }
    }

    RowLayout {
        visible: !page.loading
        spacing: 8
        PillButton { label: "Önerilen her şeyi kur"; primary: true; onClicked: page.run("auto") }
        PillButton { label: "Yeniden denetle"; icon: "refresh"; onClicked: page.refresh() }
    }
}
