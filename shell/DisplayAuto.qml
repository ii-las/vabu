pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Yeni bir ekran görüldüğünde onu doğal çözünürlüğünde ve en yüksek yenileme hızında aç.
// niri'ye yalnızca "GENİŞLİKxYÜKSEKLİK" verilince o çözünürlüğün en yüksek Hz'ini seçer.
// Kullanıcının Ayarlar'da yaptığı seçimlere dokunulmaz; sadece ayarı olmayan ekranlar eklenir.
Singleton {
    id: root

    function run() {
        if (NiriConf.ready) query.running = true
    }

    Connections {
        target: NiriConf
        function onReadyChanged() { if (NiriConf.ready) query.running = true }
    }

    Process {
        id: query
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                let outs = {}
                try { outs = JSON.parse(text) } catch (e) { return }
                const known = new Set(NiriConf.outputs.map(o => o.name))
                const added = []
                for (const name in outs) {
                    const o = outs[name]
                    if (known.has(name) || !o.modes || o.modes.length === 0) continue
                    // Önce ekranın kendi önerdiği çözünürlük, yoksa en büyüğü
                    const pref = o.modes.find(m => m.is_preferred)
                        ?? o.modes.slice().sort((a, b) => b.width * b.height - a.width * a.height)[0]
                    added.push({ name: name, mode: pref.width + "x" + pref.height })
                }
                if (added.length > 0) NiriConf.set("outputs", NiriConf.outputs.concat(added))
            }
        }
    }
}
