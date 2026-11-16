pragma Singleton
import QtQuick
import Quickshell

// Vabu görsel dili: buzlu koyu cam, sakin, renk sadece bir şey söylediğinde.
Singleton {
    // Yüzeyler. Paneller duvar kağıdını bulanık gösterir; `panel` onun üstündeki tondur.
    readonly property color night: "#0F0E11"
    readonly property color panel: Qt.rgba(21 / 255, 19 / 255, 23 / 255, 0.6)
    readonly property color panelDeep: Qt.rgba(17 / 255, 15 / 255, 19 / 255, 0.74)   // açılır paneller, başlatıcı
    readonly property color panelSolid: "#17151A"                                    // arkasında duvar kağıdı olmayan pencereler
    readonly property color well: Qt.rgba(1, 1, 1, 0.06)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.09)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.13)
    readonly property color line: Qt.rgba(1, 1, 1, 0.07)
    readonly property color edge: Qt.rgba(1, 1, 1, 0.1)       // panellerin 1 px kenar ışığı

    // Metin
    readonly property color paper: "#EFECE6"
    readonly property color soft: "#CDC8C0"
    readonly property color muted: "#A39E97"
    readonly property color faint: "#77736E"
    readonly property color ink: "#141316"                     // açık zemin üstündeki yazı

    // Anlam renkleri (az kullanılır)
    readonly property color ok: "#9FD6B0"
    readonly property color warn: "#E8B07A"
    readonly property color danger: "#EC9C90"

    // Seçim ve vurgu: kullanıcı Ayarlar > Görünüm'den seçer (varsayılan kağıt)
    readonly property color accent: Config.accent
    readonly property color accentInk: Config.accentInk

    // Yazı
    readonly property string serif: "Newsreader"
    readonly property string sans: "Hanken Grotesk"
    readonly property string mono: "JetBrains Mono"
    readonly property string icons: "Material Symbols Rounded"

    // Ölçüler
    readonly property int gap: 10
    readonly property int sidebarWidth: 280
    readonly property int radiusPanel: 26
    readonly property int radiusCard: 22
    readonly property int radiusTile: 16
    readonly property int radiusRow: 13
    readonly property int radiusControl: 11
    readonly property int pad: 16

    // Hareket: girişte yumuşak yavaşlama, çıkışta kısa hızlanma
    readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property int enter: 420
    readonly property int exit: 180
    readonly property int state: 220
    readonly property int fast: 120

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // Eski adlarla uyumluluk (Ayarlar sayfaları kullanıyor)
    readonly property color glass: panel
    readonly property color glassStrong: panelDeep
    readonly property color stone: well
    readonly property color stoneHi: Qt.rgba(1, 1, 1, 0.08)
    readonly property color dash: line
    readonly property color mint: ok
    readonly property color mintInk: "#10301F"
    readonly property color sky: "#B9CCF2"
    readonly property color skyInk: "#14223D"
    readonly property color peach: warn
    readonly property color rose: "#EBB4C8"
    readonly property color coral: danger
    readonly property int normal: state
    readonly property int slow: enter
}
