import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 20

    property var users: []            // [{name, full, admin, me}]
    property string message: ""
    readonly property string me: Quickshell.env("USER")

    function refresh() { list.running = true }
    Component.onCompleted: refresh()

    Process {
        id: list
        command: ["sh", "-c", "w=$(getent group wheel | cut -d: -f4); awk -F: -v w=\",$w,\" '$3>=1000 && $3<60000 {a = index(w, \",\"$1\",\") ? 1 : 0; print $1\"\\t\"$5\"\\t\"a}' /etc/passwd"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.users = text.split("\n").filter(l => l).map(l => {
                    const [name, gecos, admin] = l.split("\t")
                    return { name, full: (gecos || "").split(",")[0] || name, admin: admin === "1", me: name === page.me }
                }).sort((a, b) => b.me - a.me)
            }
        }
    }
    Process {
        id: adder
        stderr: StdioCollector { id: addErr }
        onExited: code => {
            if (code === 0) {
                page.message = "Kullanıcı eklendi. İlk girişte şifresini kendisi belirleyecek."
                newName.text = ""; newUser.text = ""; newPass.text = ""
                page.refresh()
            } else page.message = addErr.text.trim() || "Kullanıcı eklenemedi."
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        SectionLabel { text: "BU BİLGİSAYARIN KULLANICILARI" }
        DashLine { Layout.fillWidth: true }
        Repeater {
            model: page.users
            delegate: SettingRow {
                required property var modelData
                label: modelData.full + (modelData.me ? "  ·  sen" : "")
                sub: modelData.name + (modelData.admin ? " · yönetici" : " · standart kullanıcı")
                Chip { visible: modelData.admin; text: "YÖNETİCİ"; kind: "info" }
                PillButton {
                    visible: modelData.me
                    implicitHeight: 38
                    label: "Şifremi değiştir"
                    icon: "lock"
                    onClicked: Ui.terminal(["sh", "-c", "passwd; echo; read -p 'Kapatmak için Enter…' _"])
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10
        SectionLabel { text: "YENİ KULLANICI" }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10
            Field { id: newName; Layout.fillWidth: true; placeholder: "Ad Soyad" }
            Field {
                id: newUser
                Layout.fillWidth: true
                mono: true
                placeholder: "kullanıcı adı"
                onTextChanged: { const t = text.toLowerCase().replace(/[^a-z0-9_-]/g, ""); if (t !== text) text = t }
            }
            Field { id: newPass; Layout.fillWidth: true; echoMode: TextInput.Password; placeholder: "Geçici şifre (en az 6 karakter)" }
            RowLayout {
                spacing: 10
                Toggle { id: adminToggle; onToggled: checked = !checked }
                Text { text: "Yönetici olsun"; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 14 }
            }
        }
        RowLayout {
            spacing: 12
            PillButton {
                primary: true
                label: "Kullanıcı ekle"
                icon: "plus"
                enabled: newUser.text.length > 1 && newPass.text.length >= 6
                opacity: enabled ? 1 : 0.5
                onClicked: {
                    // Geçici şifre standart girdiden okunur (süreç listesinde görünmez);
                    // ilk girişte değiştirilmesi zorunlu tutulur.
                    adder.command = ["pkexec", "sh", "-c",
                        "IFS= read -r p && useradd -m -c \"$1\" " + (adminToggle.checked ? "-G wheel " : "") + "\"$2\" && " +
                        "printf '%s:%s\\n' \"$2\" \"$p\" | chpasswd && passwd -e \"$2\" >/dev/null",
                        "vabu-useradd", newName.text || newUser.text, newUser.text]
                    adder.stdinEnabled = true
                    adder.running = true
                    adder.write(newPass.text + "\n")
                }
            }
            Text { Layout.fillWidth: true; text: page.message; color: Theme.soft; font.family: Theme.sans; font.pixelSize: 12; wrapMode: Text.Wrap }
        }
    }
}
