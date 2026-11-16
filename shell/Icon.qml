import QtQuick

// Material Symbols Rounded. Dolgu (filled) ve kalınlık değişken eksenlerle animasyonlu değişir.
Text { textFormat: Text.PlainText;
    id: root
    property string name: ""
    property real size: 20
    property bool filled: false
    property real weight: 300
    property real stroke: 0                      // eski çizgi ikonlarıyla uyumluluk, kullanılmıyor

    property real fillAmount: filled ? 1 : 0
    Behavior on fillAmount { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }

    // Eski kısa adlar -> Material Symbols adları; listede yoksa ad olduğu gibi kullanılır
    readonly property var aliases: ({
        "wifi-off": "wifi_off", "ethernet": "lan", "volume": "volume_up", "volume-low": "volume_down",
        "mute": "volume_off", "sun": "light_mode", "bell": "notifications", "bell-off": "notifications_off",
        "sliders": "tune", "power": "power_settings_new", "moon": "bedtime", "restart": "restart_alt",
        "play": "play_arrow", "next": "skip_next", "prev": "skip_previous", "plus": "add",
        "arrow-left": "arrow_back", "arrow-right": "arrow_forward", "update": "system_update_alt",
        "chip": "memory", "camera": "screenshot_monitor"
    })

    text: aliases[name] ?? name
    color: Theme.paper
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fillAmount, "wght": weight, "GRAD": 0, "opsz": Math.max(20, Math.min(48, size)) })
    width: size
    height: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
