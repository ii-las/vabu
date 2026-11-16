import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
ColumnLayout {
    id: page
    spacing: 18
    property string message: ""
    property string batteryLid: "suspend"
    property string acLid: "suspend"
    Process { running: true; command: ["/usr/libexec/vabu/desktop-tools", "lid_status"]; stdout: StdioCollector { onStreamFinished: { try { const values=JSON.parse(text); page.batteryLid=values.battery; page.acLid=values.ac } catch(e) {} } } }
    component Policy: Group {
        id: policy
        property string prefix
        Repeater {
            model: [{key:"Lock",title:Lang.t("Ekranı kilitle"),fallback:5}, {key:"Screen",title:Lang.t("Ekranı kapat"),fallback:10}, {key:"Suspend",title:Lang.t("Uyku"),fallback:0}]
            delegate: SettingRow {
                required property var modelData
                id: row
                label: modelData.title
                readonly property string configKey: policy.prefix + modelData.key
                readonly property var choices: [0, 2, 5, 10, 15, 30, 60]
                Row {
                    spacing: 8
                    readonly property int current: Math.max(0, row.choices.indexOf(Config.values[row.configKey] ?? row.modelData.fallback))
                    IconButton { icon: "chevron_left"; tooltip: Lang.t("Azalt"); onClicked: Config.set(row.configKey, row.choices[Math.max(0, parent.current - 1)]) }
                    Text { textFormat: Text.PlainText; anchors.verticalCenter: parent.verticalCenter; text: row.choices[parent.current] === 0 ? Lang.t("Asla") : row.choices[parent.current] + (Config.language === "en" ? " min" : " dk"); color: Theme.paper; font.family: Theme.sans; font.pixelSize: Math.round(14 * Config.textScale) }
                    IconButton { icon: "chevron_right"; tooltip: Lang.t("Artır"); onClicked: Config.set(row.configKey, row.choices[Math.min(row.choices.length - 1, parent.current + 1)]) }
                }
            }
        }
    }
    Policy { title: Lang.t("Pilde"); prefix: "battery" }
    Policy { title: Lang.t("Prize bağlı"); prefix: "ac" }
    // Explicit groups keep settings independent of delegate ancestry.
    Group {
        title: Lang.t("Kapak davranışı")
        note: Lang.t("Sistem genelinde uygulanır. Değişiklik sonraki yeniden başlatmada etkinleşir.")
        SettingRow { label: Lang.t("Pilde"); Segmented { options: [Lang.t("Uyku"), Lang.t("İşlem yapma")]; currentIndex: page.batteryLid === "suspend" ? 0 : 1; onPicked: i => page.batteryLid = i === 0 ? "suspend" : "ignore" } }
        SettingRow { label: Lang.t("Prize bağlı"); Segmented { options: [Lang.t("Uyku"), Lang.t("İşlem yapma")]; currentIndex: page.acLid === "suspend" ? 0 : 1; onPicked: i => page.acLid = i === 0 ? "suspend" : "ignore" } }
        PillButton { label: Lang.t("Kapak ayarını uygula"); enabled: !lid.running; onClicked: { lid.command = ["pkexec", "/usr/libexec/vabu/desktop-tools", "lid", page.batteryLid, page.acLid]; lid.running = true } }
        Text { textFormat: Text.PlainText; text: page.message; color: Theme.soft; wrapMode: Text.Wrap; Layout.fillWidth: true }
    }
    Process { id: lid; stderr: StdioCollector { id: err }; onExited: code => page.message = code === 0 ? Lang.t("Kaydedildi. Yeniden başlatınca uygulanır.") : (err.text.trim() || Lang.t("Ayar kaydedilemedi.")) }
}
