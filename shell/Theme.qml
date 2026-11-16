pragma Singleton
import QtQuick
import Quickshell

// Vabu görsel dili: mat koyu, sakin, renk sadece bir şey söylediğinde.
Singleton {
    // Yüzeyler
    readonly property color night: "#0F0E11"
    readonly property color panel: Qt.rgba(18 / 255, 16 / 255, 19 / 255, 0.9)
    readonly property color panelSolid: "#151317"
    readonly property color well: Qt.rgba(1, 1, 1, 0.045)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.07)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.1)
    readonly property color line: Qt.rgba(1, 1, 1, 0.06)
    readonly property color edge: Qt.rgba(1, 1, 1, 0.05)      // panellerin 1 px iç kenarı

    // Metin
    readonly property color paper: "#EDEAE3"
    readonly property color soft: "#C9C4BB"
    readonly property color muted: "#9C978F"
    readonly property color faint: "#6F6B66"
    readonly property color ink: "#141316"                     // açık zemin üstündeki yazı

    // Anlam renkleri (az kullanılır)
    readonly property color ok: "#9FD6B0"
    readonly property color warn: "#E8B07A"
    readonly property color danger: "#E89A8E"

    // Seçim ve vurgu: kullanıcı Ayarlar > Görünüm'den seçer (varsayılan kağıt)
    readonly property color accent: Config.accent
    readonly property color accentInk: Config.accentInk

    // Yazı
    readonly property string serif: "Newsreader"
    readonly property string sans: "Hanken Grotesk"
    readonly property string mono: "JetBrains Mono"
    readonly property string icons: "Material Symbols Rounded"

    // Ölçüler
    readonly property int gap: 12
    readonly property int sidebarWidth: 284
    readonly property int radiusPanel: 22
    readonly property int radiusCard: 18
    readonly property int radiusRow: 12
    readonly property int radiusControl: 11

    // Hareket: girişte yumuşak yavaşlama, çıkışta kısa hızlanma
    readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property int enter: 420
    readonly property int exit: 180
    readonly property int state: 220
    readonly property int fast: 120

    // Eski adlarla uyumluluk (Ayarlar sayfaları kullanıyor)
    readonly property color glass: panel
    readonly property color glassStrong: panel
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
