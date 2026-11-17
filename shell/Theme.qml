pragma Singleton
import QtQuick
import Quickshell

// Vabu görsel dili: sakin yüzeyler, okunur metin, tek vurgu rengi.
// Görünüm Ayarlar > Görünüm'den seçilir: açık, koyu ya da otomatik (gün batımında koyu).
Singleton {
    id: root

    readonly property bool dark: Config.theme === "koyu" || (Config.theme === "otomatik" && Sun.night)
    function pick(light, darkValue) { return root.dark ? darkValue : light }

    // Opak yüzey varsayılan; kullanıcı efektleri açarsa isteğe bağlı cam katmanı.
    readonly property color panel: Config.highContrast || !Config.effects ? panelSolid : pick(Qt.rgba(248 / 255, 249 / 255, 252 / 255, 0.5), Qt.rgba(26 / 255, 25 / 255, 31 / 255, 0.42))
    readonly property color panelDeep: Config.highContrast || !Config.effects ? panelSolid : pick(Qt.rgba(248 / 255, 249 / 255, 252 / 255, 0.66), Qt.rgba(22 / 255, 21 / 255, 27 / 255, 0.6))
    readonly property color edge: pick(Qt.rgba(1, 1, 1, 0.72), Qt.rgba(1, 1, 1, 0.1))          // iç kenar ışığı
    readonly property color outline: pick(Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.07), Qt.rgba(0, 0, 0, 0.25))
    readonly property color shadow: pick(Qt.rgba(28 / 255, 38 / 255, 60 / 255, 0.22), Qt.rgba(0, 0, 0, 0.45))
    readonly property color scrim: pick(Qt.rgba(30 / 255, 40 / 255, 60 / 255, 0.2), Qt.rgba(0, 0, 0, 0.38))
    readonly property color scrimDeep: pick(Qt.rgba(30 / 255, 40 / 255, 60 / 255, 0.34), Qt.rgba(0, 0, 0, 0.5))

    // Düz yüzeyler: uygulama pencereleri (Ayarlar)
    readonly property color panelSolid: pick("#F4F3EF", "#202420")
    readonly property color nav: pick("#E9EBE4", "#191D19")
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
    readonly property color paper: pick("#222725", "#F0EEE9")
    readonly property color soft: pick("#414749", "#CFCBC4")
    readonly property color muted: Config.highContrast ? paper : pick("#585F5B", "#A9A49D")
    readonly property color faint: Config.highContrast ? paper : pick("#5F675E", "#B4BCAE")
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

    readonly property int textSmall: Math.round(14 * Config.textScale)
    readonly property int textBody: Math.round(15 * Config.textScale)

    // Ölçüler
    readonly property int gap: 10
    readonly property int sidebarWidth: Config.sidebarWidth
    readonly property int sidebarCompactWidth: 72
    readonly property int sidebarNow: Config.sidebarCompact ? sidebarCompactWidth : sidebarWidth
    readonly property int radiusPanel: 18
    readonly property int radiusCard: 16
    readonly property int radiusTile: 12
    readonly property int radiusRow: 12
    readonly property int radiusControl: 11
    readonly property int pad: 14

    // Hareket: girişte yumuşak yavaşlama, çıkışta kısa hızlanma
    readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property int enter: Config.reducedMotion ? 0 : 240
    readonly property int exit: Config.reducedMotion ? 0 : 140
    readonly property int state: Config.reducedMotion ? 0 : 160
    readonly property int fast: Config.reducedMotion ? 0 : 120

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
