pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Zeminler
    readonly property color night: "#121216"
    readonly property color ink: "#1D1C22"
    readonly property color stone: "#26242C"
    readonly property color stoneHi: "#34313B"
    readonly property color glass: Qt.rgba(20 / 255, 20 / 255, 26 / 255, 0.62)
    readonly property color glassStrong: Qt.rgba(28 / 255, 27 / 255, 33 / 255, 0.84)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.06)
    readonly property color selected: Qt.rgba(1, 1, 1, 0.09)
    readonly property color line: Qt.rgba(1, 1, 1, 0.09)
    readonly property color dash: Qt.rgba(1, 1, 1, 0.16)

    // Metin
    readonly property color paper: "#F3F1EC"
    readonly property color soft: "#CFC9C2"
    readonly property color muted: "#A3A1A8"
    readonly property color faint: "#8E8B93"

    // Vurgular: nane yapar, gök seçer, şeftali dikkat ister
    readonly property color mint: "#8EF0C6"
    readonly property color mintInk: "#0E3B2C"
    readonly property color sky: "#A9C7F7"
    readonly property color skyInk: "#14243F"
    readonly property color peach: "#F2B48A"
    readonly property color peachInk: "#3B2414"
    readonly property color rose: "#F7A8C4"
    readonly property color coral: "#F7A8A8"

    // Kullanıcının seçtiği vurgu (Vabu Ayarlar > Görünüm). Seçim ve odak bunu kullanır.
    readonly property color accent: Config.accent
    readonly property color accentInk: Config.accentInk

    // Yazı
    readonly property string serif: "Instrument Serif"
    readonly property string sans: "Geist"
    readonly property string mono: "Geist Mono"

    // Ölçüler
    readonly property int gap: 12
    readonly property int sidebarWidth: 280
    readonly property int radiusCard: 20
    readonly property int radiusRow: 12
    readonly property int radiusPanel: 28

    // Hareket
    readonly property int fast: 140
    readonly property int normal: 220
    readonly property int slow: 380
}
