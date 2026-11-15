import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string name: ""
    property color color: Theme.paper
    property real size: 18
    property real stroke: 1.8

    implicitWidth: size
    implicitHeight: size

    readonly property var paths: ({
        "search":   "M11 4a7 7 0 1 1 0 14a7 7 0 1 1 0-14M20 20l-3.5-3.5",
        "wifi":     "M2 8.8a15 15 0 0 1 20 0M5 12.6a10 10 0 0 1 14 0M8.5 16.3a5 5 0 0 1 7 0M12 20h.01",
        "wifi-off": "M2 8.8a15 15 0 0 1 20 0M8.5 16.3a5 5 0 0 1 7 0M12 20h.01M3 3l18 18",
        "ethernet": "M4 14h16v6H4zM8 14v-4h8v4M12 10V4",
        "volume":   "M11 5 6 9H2v6h4l5 4V5zM15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14",
        "volume-low": "M11 5 6 9H2v6h4l5 4V5zM15.5 8.5a5 5 0 0 1 0 7",
        "mute":     "M11 5 6 9H2v6h4l5 4V5zM22 9l-6 6M16 9l6 6",
        "sun":      "M12 8a4 4 0 1 1 0 8a4 4 0 1 1 0-8M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
        "bell":     "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.94 1.94 0 0 0 3.4 0",
        "bell-off": "M6 8a6 6 0 0 1 9.3-5M18 8c0 7 3 9 3 9H9M10.3 21a1.94 1.94 0 0 0 3.4 0M3 3l18 18",
        "sliders":  "M4 7h10M18 7h2M4 17h4M12 17h8M16 5a2 2 0 1 1 0 4a2 2 0 1 1 0-4M10 15a2 2 0 1 1 0 4a2 2 0 1 1 0-4",
        "power":    "M12 3v9M6.3 6.3a8 8 0 1 0 11.4 0",
        "lock":     "M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4",
        "logout":   "M15 4h4v16h-4M10 8l-4 4 4 4M6 12h11",
        "moon":     "M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z",
        "restart":  "M20 12a8 8 0 1 1-2.34-5.66M20 4v5h-5",
        "play":     "M7 4l13 8-13 8z",
        "pause":    "M9 5v14M15 5v14",
        "next":     "M5 4l10 8-10 8zM19 5v14",
        "prev":     "M19 20 9 12l10-8zM5 19V5",
        "download": "M12 4v12M6 11l6 6 6-6M5 20h14",
        "check":    "M5 12l5 5 9-10",
        "close":    "M6 6l12 12M18 6 6 18",
        "plus":     "M12 5v14M5 12h14",
        "terminal": "M5 7l5 5-5 5M12 17h7",
        "arrow-left": "M19 12H5M11 18l-6-6 6-6",
        "arrow-right": "M5 12h14M13 6l6 6-6 6",
        "keyboard": "M3 7h18v10H3zM7 11h.01M11 11h.01M15 11h.01M7 14h10",
        "update":   "M20 12a8 8 0 1 1-2.34-5.66M20 4v5h-5M12 8v4l3 2",
        "chip":     "M7 7h10v10H7zM10 3v4M14 3v4M10 17v4M14 17v4M3 10h4M3 14h4M17 10h4M17 14h4",
        "camera":   "M4 8h4l2-3h4l2 3h4v11H4zM12 10a3 3 0 1 1 0 6a3 3 0 1 1 0-6",
        "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17"
    })

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: root.size / 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.paths[root.name] ?? "" }
        }
    }
}
