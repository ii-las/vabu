import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 24

    property var info: ({})
    property bool editingHost: false

    Process {
        id: collect
        running: true
        command: ["sh", "-c",
            ". /etc/os-release; " +
            "echo \"vabu=$(rpm -q --qf '%{VERSION}' vabu-desktop 2>/dev/null)\"; " +
            "echo \"fedora=$VERSION_ID\"; " +
            "echo \"shell=$(rpm -q --qf '%{VERSION}' vabu-shell 2>/dev/null)\"; " +
            "echo \"niri=$(niri --version 2>/dev/null | awk '{print $2}')\"; " +
            "echo \"host=$(hostnamectl hostname 2>/dev/null || hostname)\"; " +
            "echo \"cpu=$(lscpu | sed -n 's/^Model name:[[:space:]]*//p' | head -1)\"; " +
            "echo \"gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' | sed 's/^[^:]*: //' | paste -sd ';')\"; " +
            "echo \"mem=$(awk '/MemTotal/ {printf \"%.0f GB\", $2/1048576}' /proc/meminfo)\"; " +
            "echo \"disk=$(df -h --output=size,fstype / | tail -1 | awk '{print $1\" · \"$2}')\"; " +
            "echo \"kernel=$(uname -r)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of text.split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) }
                page.info = o
            }
        }
    }

    readonly property var rows: [
        ["Sürüm", "Vabu " + (info.vabu || "?") + " · Fedora " + (info.fedora || "?") + " tabanlı"],
        ["Kabuk", "Vabu Shell " + (info.shell || "?") + " · niri " + (info.niri || "?")],
        ["İşlemci", info.cpu || "-"],
        ["Grafik", (info.gpu || "-").split(";").join("\n")],
        ["Bellek", info.mem || "-"],
        ["Disk", info.disk || "-"],
        ["Çekirdek", info.kernel || "-"]
    ]

    function asText() {
        return ["Bilgisayar: " + (info.host || "")].concat(rows.map(r => r[0] + ": " + r[1].replace(/\n/g, ", "))).join("\n")
    }

    // Kimlik
    RowLayout {
        Layout.fillWidth: true
        spacing: 18
        Image {
            Layout.preferredWidth: 76
            Layout.preferredHeight: 76
            source: "/usr/share/icons/hicolor/scalable/apps/vabu-logo.svg"
            sourceSize: Qt.size(152, 152)
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { textFormat: Text.PlainText;
                text: "Vabu " + (page.info.vabu || "")
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: Math.round((24) * Config.textScale)
                font.weight: Font.DemiBold
                font.letterSpacing: -0.3
            }
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                text: "Fedora " + (page.info.fedora || "") + " tabanlı. Uygulamalar Fedora, RPM Fusion ve Flathub'dan gelir."
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: Theme.textSmall
                wrapMode: Text.Wrap
                lineHeight: 1.2
            }
        }
    }

    Group {
        title: Lang.t("Bu bilgisayar")

        // Bilgisayar adı (düzenlenebilir)
        SettingRow {
            label: Lang.t("Bilgisayar adı")
            sub: page.editingHost ? "" : (page.info.host || "-")
            Field {
                id: hostField
                visible: page.editingHost
                implicitWidth: 240
                implicitHeight: 38
                text: page.info.host || ""
                onAccepted: saveHost.clicked()
            }
            PillButton {
                id: saveHost
                implicitHeight: 38
                primary: page.editingHost
                label: page.editingHost ? Lang.t("Kaydet") : Lang.t("Değiştir")
                onClicked: {
                    if (page.editingHost && hostField.text.trim()) {
                        Quickshell.execDetached(["pkexec", "hostnamectl", "set-hostname", hostField.text.trim()])
                        page.info = Object.assign({}, page.info, { host: hostField.text.trim() })
                    }
                    page.editingHost = !page.editingHost
                    if (page.editingHost) hostField.focusField()
                }
            }
        }

        Repeater {
            model: page.rows
            delegate: Item {
                id: line
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Math.max(46, value.implicitHeight + 26)
                Rectangle { x: 16; width: parent.width - 32; height: 1; color: Theme.line }
                Text { textFormat: Text.PlainText;
                    x: 16
                    y: 14
                    width: 120
                    text: line.modelData[0]
                    color: Theme.muted
                    font.family: Theme.sans
                    font.pixelSize: Math.round((14) * Config.textScale)
                }
                Text { textFormat: Text.PlainText;
                    id: value
                    x: 152
                    y: 14
                    width: parent.width - 168
                    text: line.modelData[1]
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: Math.round((14) * Config.textScale)
                    lineHeight: 1.25
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 8
        PillButton {
            label: Lang.t("Sistem bilgisini kopyala")
            icon: "content_copy"
            onClicked: { Quickshell.execDetached(["wl-copy", page.asText()]); label = "Kopyalandı" }
        }
        PillButton {
            label: Lang.t("Hata bildir")
            icon: "bug_report"
            onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/ii-las/vabu/issues"])
        }
    }
}
