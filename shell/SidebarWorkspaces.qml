import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Çalışma alanları. Her satır bir alandır ve içindeki pencereleri, şeritteki sırasıyla
// (soldan sağa kolonlar, üst üste binenler bitişik) uygulama simgeleriyle gösterir.
// Satıra tıklamak o alana, simgeye tıklamak o pencereye götürür; tekerlek alanlar arasında gezer.
Card {
    id: root
    property string output: ""
    visible: Niri.available && rows.length > 0
    implicitHeight: col.implicitHeight + 16

    readonly property var rows: Niri.rowsFor(output)
    readonly property int activeIndex: rows.findIndex(r => r.ws.is_active)
    readonly property int maxIcons: 6

    function rowHeight(r) { return r.spare && !r.ws.is_active ? 34 : 42 }
    readonly property real activeY: {
        let y = 0
        for (let i = 0; i < activeIndex; i++) y += rowHeight(rows[i]) + col.spacing
        return y
    }

    // Seçili satırın zemini: satırdan satıra kayarak geçer
    Rectangle {
        id: pill
        visible: root.activeIndex >= 0
        x: 8
        y: col.y + root.activeY
        width: parent.width - 16
        height: 42
        radius: Theme.radiusRow
        color: Theme.accent
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }

    ColumnLayout {
        id: col
        x: 8
        y: 8
        width: parent.width - 16
        spacing: 2

        // Satırlar sayıya bağlıdır, içerik sıra numarasıyla okunur: niri'den gelen her olayda
        // satırlar yeniden kurulmaz, sadece değişen yer güncellenir.
        Repeater {
            model: root.rows.length
            delegate: Item {
                id: row
                required property int index
                readonly property var modelData: root.rows[index] ?? ({ ws: {}, columns: [], count: 0, spare: false })
                readonly property var ws: modelData.ws
                readonly property bool isOn: ws.is_active === true
                readonly property bool spare: modelData.spare && !isOn
                readonly property color fg: isOn ? Theme.accentInk : Theme.paper
                readonly property var wins: {
                    const out = []
                    for (const c of modelData.columns)
                        for (let i = 0; i < c.windows.length; i++)
                            out.push({ win: c.windows[i], first: i === 0 })
                    return out
                }

                Layout.fillWidth: true
                implicitHeight: spare ? 34 : 42

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusRow
                    visible: !row.isOn
                    color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspace(row.ws)
                }

                // Yedek alan: yeni pencereler için hazır bekleyen boş alan
                RowLayout {
                    visible: row.spare
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 4
                    spacing: 10
                    Icon { name: "add"; size: 17; color: Theme.faint }
                    Text {
                        Layout.fillWidth: true
                        text: "Yeni alan"
                        color: Theme.faint
                        font.family: Theme.sans
                        font.pixelSize: 13
                    }
                    IconButton {
                        implicitWidth: 28; implicitHeight: 28
                        radius: 9
                        icon: "overview_key"
                        iconSize: 17
                        iconColor: Theme.muted
                        active: Niri.overviewOpen
                        tooltip: "Genel bakış"
                        onClicked: Niri.toggleOverview()
                    }
                }

                RowLayout {
                    visible: !row.spare
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 10
                        text: row.ws.idx ?? ""
                        color: row.fg
                        opacity: row.isOn ? 1 : 0.75
                        font.family: Theme.sans
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.features: ({ "tnum": 1 })
                        Behavior on color { ColorAnimation { duration: Theme.state } }
                    }

                    Row {
                        spacing: 0
                        Repeater {
                            model: Math.min(row.wins.length, root.maxIcons)
                            delegate: Item {
                                id: cell
                                required property int index
                                readonly property var entry: row.wins[index] ?? null
                                readonly property var win: entry ? entry.win : ({})
                                // aynı kolondaki pencereler bitişik, yeni kolon biraz aralıklı
                                width: 22 + (index === 0 ? 0 : entry && entry.first ? 7 : 1)
                                height: 26
                                IconImage {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 22
                                    source: Apps.iconFor(cell.win.app_id ?? "")
                                    opacity: cell.win.id === row.ws.active_window_id || iconMouse.containsMouse ? 1 : 0.55
                                    scale: iconMouse.pressed ? 0.88 : 1
                                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                                    Behavior on scale { NumberAnimation { duration: Theme.fast } }
                                }
                                // dikkat isteyen pencere
                                Rectangle {
                                    visible: cell.win.is_urgent === true
                                    width: 6; height: 6; radius: 3
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    color: Theme.warn
                                }
                                MouseArea {
                                    id: iconMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    onClicked: e => {
                                        if (cell.win.id === undefined) return
                                        if (e.button === Qt.MiddleButton) Niri.closeWindow(cell.win.id)
                                        else Niri.focusWindow(cell.win.id)
                                    }
                                }
                            }
                        }
                        Text {
                            visible: row.wins.length > root.maxIcons
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 6
                            text: "+" + (row.wins.length - root.maxIcons)
                            color: row.fg
                            opacity: 0.7
                            font.family: Theme.sans
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    // Tekerlek: alanlar arasında gez
    WheelHandler {
        property double last: 0
        onWheel: event => {
            const now = Date.now()
            if (now - last < 160) return
            last = now
            Niri.action([event.angleDelta.y > 0 ? "focus-workspace-up" : "focus-workspace-down"])
        }
    }
}
