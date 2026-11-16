pragma Singleton
import QtQuick
import Quickshell

// Vabu görsel dili: buzlu cam, açık ve koyu görünüm, tek vurgu rengi.
// Görünüm Ayarlar > Görünüm'den seçilir: açık, koyu ya da otomatik (gün batımında koyu).
Singleton {
    id: root

    readonly property bool dark: Config.theme === "koyu" || (Config.theme === "otomatik" && Sun.night)
    function pick(light, darkValue) { return root.dark ? darkValue : light }

    // Cam yüzeyler: arkadaki duvar kağıdı bulanık görünür, üstüne bu ton gelir
    readonly property color panel: pick(Qt.rgba(248 / 255, 249 / 255, 252 / 255, 0.5), Qt.rgba(26 / 255, 25 / 255, 31 / 255, 0.42))
    readonly property color panelDeep: pick(Qt.rgba(248 / 255, 249 / 255, 252 / 255, 0.66), Qt.rgba(22 / 255, 21 / 255, 27 / 255, 0.6))
    readonly property color edge: pick(Qt.rgba(1, 1, 1, 0.72), Qt.rgba(1, 1, 1, 0.1))          // iç kenar ışığı
    readonly property color outline: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.07), Qt.rgba(0, 0, 0, 0.25))
    readonly property color shadow: pick(Qt.rgba(28 / 255, 38 / 255, 60 / 255, 0.22), Qt.rgba(0, 0, 0, 0.45))
    readonly property color scrim: pick(Qt.rgba(30 / 255, 40 / 255, 60 / 255, 0.2), Qt.rgba(0, 0, 0, 0.38))
    readonly property color scrimDeep: pick(Qt.rgba(30 / 255, 40 / 255, 60 / 255, 0.34), Qt.rgba(0, 0, 0, 0.5))

    // Düz yüzeyler: uygulama pencereleri (Ayarlar)
    readonly property color panelSolid: pick("#F4F5F7", "#1B1A1F")
    readonly property color nav: pick("#ECEEF2", "#161519")
    readonly property color group: pick("#FFFFFF", Qt.rgba(1, 1, 1, 0.045))
    readonly property color groupEdge: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.07), Qt.rgba(1, 1, 1, 0.06))
    readonly property color night: pick("#E9ECF1", "#0F0E11")

    // Etkileşim
    readonly property color well: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.055), Qt.rgba(1, 1, 1, 0.07))
    readonly property color hover: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.085), Qt.rgba(1, 1, 1, 0.1))
    readonly property color pressed: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.13), Qt.rgba(1, 1, 1, 0.14))
    readonly property color line: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.09), Qt.rgba(1, 1, 1, 0.09))
    readonly property color track: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.14), Qt.rgba(1, 1, 1, 0.16))
    readonly property color knob: pick("#FFFFFF", "#F0EEE9")
    readonly property color segOn: pick("#FFFFFF", Qt.rgba(1, 1, 1, 0.14))

    // Yazı (eski adlar korunuyor: paper ana yazı rengidir)
    readonly property color paper: pick("#15181E", "#F0EEE9")
    readonly property color soft: pick("#3B4250", "#CFCBC4")
    readonly property color muted: pick("#566070", "#A9A49D")
    readonly property color faint: pick("#7A8494", "#7F7A74")
    readonly property color ink: pick("#FFFFFF", "#141316")

    // Anlam renkleri
    readonly property color ok: pick("#1E7A52", "#8FD4AE")
    readonly property color warn: pick("#9A5A14", "#E8B07A")
    readonly property color danger: pick("#B93A30", "#F09A8E")

    // Vurgu: Ayarlar > Görünüm'den seçilir
    readonly property color accent: dark ? Config.accentDark : Config.accentLight
    readonly property color accentInk: dark ? Config.accentDarkInk : "#FFFFFF"

    // Yazı tipleri
    readonly property string sans: "Hanken Grotesk"
    readonly property string serif: sans
    readonly property string mono: "JetBrains Mono"
    readonly property string icons: "Material Symbols Rounded"

    // Ölçüler
    readonly property int gap: 10
    readonly property int sidebarWidth: 280
    readonly property int radiusPanel: 22
    readonly property int radiusCard: 20
    readonly property int radiusTile: 15
    readonly property int radiusRow: 12
    readonly property int radiusControl: 11
    readonly property int pad: 14

    // Hareket: girişte yumuşak yavaşlama, çıkışta kısa hızlanma
    readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property int enter: 420
    readonly property int exit: 180
    readonly property int state: 220
    readonly property int fast: 120

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // Eski adlar
    readonly property color glass: panel
    readonly property color glassStrong: panelDeep
    readonly property color stone: well
    readonly property color stoneHi: hover
    readonly property color dash: line
    readonly property color mint: ok
    readonly property color peach: warn
    readonly property color coral: danger
    readonly property color sky: accent
    readonly property int normal: state
    readonly property int slow: enter
}
