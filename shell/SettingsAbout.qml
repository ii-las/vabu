import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: page
    spacing: 36

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

    ColumnLayout {
        Layout.preferredWidth: 260
        Layout.alignment: Qt.AlignTop
        spacing: 14
        Rectangle {
            implicitWidth: 120; implicitHeight: 120; radius: 34
            color: Theme.mint
            Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -8; text: "v"; color: Theme.mintInk; font.family: Theme.serif; font.italic: true; font.pixelSize: 104 }
        }
        Text { text: "Vabu " + (page.info.vabu || ""); color: Theme.paper; font.family: Theme.serif; font.pixelSize: 44 }
        Text {
            Layout.fillWidth: true
            text: "Fedora tabanlı. Uygulamalar Fedora, RPM Fusion ve Flathub’dan gelir."
            color: Theme.soft; font.family: Theme.sans; font.pixelSize: 13; wrapMode: Text.Wrap; lineHeight: 1.2
        }
        PillButton {
            label: "Sistem bilgisini kopyala"
            onClicked: { Quickshell.execDetached(["wl-copy", page.asText()]); label = "Kopyalandı" }
        }
        PillButton {
            label: "Hata bildir"
            onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/ii-las/vabu/issues"])
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 0
        DashLine { Layout.fillWidth: true }

        // Bilgisayar adı (düzenlenebilir)
        Item {
            Layout.fillWidth: true
            implicitHeight: 58
            RowLayout {
                anchors.fill: parent
                spacing: 14
                Rectangle {
                    implicitWidth: 26; implicitHeight: 20; radius: 6; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.18)
                    Text { anchors.centerIn: parent; text: "00"; color: Theme.soft; font.family: Theme.mono; font.pixelSize: 10 }
                }
                Text { Layout.preferredWidth: 110; text: "Bilgisayar"; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 13 }
                Text { visible: !page.editingHost; Layout.fillWidth: true; text: page.info.host || "-"; color: Theme.paper; font.family: Theme.serif; font.pixelSize: 19 }
                Field { id: hostField; visible: page.editingHost; Layout.fillWidth: true; mono: true; text: page.info.host || "" }
                Text {
                    text: page.editingHost ? "Kaydet" : "Değiştir"
                    color: Theme.sky
                    font.family: Theme.sans; font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (page.editingHost && hostField.text.trim()) {
                                Quickshell.execDetached(["pkexec", "hostnamectl", "set-hostname", hostField.text.trim()])
                                page.info = Object.assign({}, page.info, { host: hostField.text.trim() })
                            }
                            page.editingHost = !page.editingHost
                        }
                    }
                }
            }
            DashLine { anchors.bottom: parent.bottom; width: parent.width }
        }

        Repeater {
            model: page.rows
            delegate: Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: Math.max(54, value.implicitHeight + 24)
                RowLayout {
                    anchors.fill: parent
                    spacing: 14
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 20; radius: 6; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.18)
                        Text { anchors.centerIn: parent; text: String(index + 1).padStart(2, "0"); color: Theme.soft; font.family: Theme.mono; font.pixelSize: 10 }
                    }
                    Text { Layout.preferredWidth: 110; text: modelData[0]; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 13 }
                    Text { id: value; Layout.fillWidth: true; text: modelData[1]; color: Theme.paper; font.family: Theme.serif; font.pixelSize: 19; wrapMode: Text.Wrap }
                }
                DashLine { anchors.bottom: parent.bottom; width: parent.width }
            }
        }
    }
}
