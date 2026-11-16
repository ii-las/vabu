import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Çalışma alanları. Her satır bir alandır ve içindeki pencereleri, şeritteki sırasıyla
// (soldan sağa kolonlar, üst üste binenler bitişik) uygulama simgeleriyle gösterir.
// Satıra tıklamak o alana, simgeye tıklamak o pencereye götürür; tekerlek alanlar arasında gezer.
// Simge sürüklenebilir: başka bir satıra bırakmak pencereyi o alana taşır (en alttaki boş satır
// yeni alan demektir), aynı satırda bırakmak kolonu şeritte o sıraya alır.
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

    // Sürükle bırak durumu
    property var dragWin: null
    property int dragRow: -1
    property int dragCol: -1
    property point dragAt: Qt.point(0, 0)
    property int dropRow: -1
    property int dropSlot: -1
    property real dropX: 0
    property real dropY: 0

    function rowAt(y) {
        for (let i = 0; i < rowsRep.count; i++) {
            const it = rowsRep.itemAt(i)
            if (!it) continue
            const top = it.mapToItem(root, 0, 0).y
            if (y >= top - col.spacing && y < top + it.height + col.spacing) return i
        }
        return -1
    }
    function beginDrag(win, row, column, pos) {
        dragWin = win
        dragRow = row
        dragCol = column
        moveDrag(pos)
    }
    function moveDrag(pos) {
        dragAt = pos
        dropRow = pos.x >= 0 && pos.x <= width ? rowAt(pos.y) : -1
        const it = dropRow === dragRow && !dragWin.is_floating ? rowsRep.itemAt(dropRow) : null
        if (it) {
            const slot = it.slotAt(pos.x)
            dropSlot = slot.index
            dropX = slot.x
            dropY = it.mapToItem(root, 0, 0).y
        } else dropSlot = -1
    }
    function endDrag(apply) {
        const win = dragWin
        if (apply && win && dropRow >= 0) {
            if (dropRow !== dragRow) Niri.moveWindowToWorkspace(win.id, rows[dropRow].ws)
            else if (dropSlot >= 0 && dropSlot !== dragCol && dropSlot !== dragCol + 1)
                Niri.moveColumnTo(win.id, dropSlot > dragCol ? dropSlot : dropSlot + 1)
        }
        dragWin = null
        dragRow = -1
        dragCol = -1
        dropRow = -1
        dropSlot = -1
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
            id: rowsRep
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
                    const cols = modelData.columns
                    for (let ci = 0; ci < cols.length; ci++)
                        for (let i = 0; i < cols[ci].windows.length; i++)
                            out.push({ win: cols[ci].windows[i], first: i === 0, col: ci })
                    return out
                }
                readonly property bool dropHere: root.dragWin !== null && root.dropRow === index && root.dragRow !== index

                // Bırakma yeri: kolonların simge aralıklarına göre kaçıncı sıraya girileceği
                function slotAt(px) {
                    const spans = []
                    for (let i = 0; i < iconsRep.count; i++) {
                        const it = iconsRep.itemAt(i)
                        if (!it || !it.entry || it.win.is_floating) continue
                        const left = it.mapToItem(root, it.width - 22, 0).x
                        const c = it.entry.col
                        if (!spans[c]) spans[c] = { l: left, r: left + 22 }
                        else spans[c].r = left + 22
                    }
                    const list = spans.filter(x => x)
                    let k = 0
                    while (k < list.length && px > (list[k].l + list[k].r) / 2) k++
                    const x = list.length === 0 ? 0
                        : k === 0 ? list[0].l - 4
                        : k === list.length ? list[k - 1].r + 3
                        : (list[k - 1].r + list[k].l) / 2
                    return { index: k, x: x }
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

                // Buraya bırakılacak: ince vurgu çerçevesi
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusRow
                    color: row.isOn ? "transparent" : Theme.alpha(Theme.accent, 0.10)
                    border.width: 1.5
                    border.color: row.isOn ? Theme.accentInk : Theme.accent
                    opacity: row.dropHere ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // boş satır: o alana geç ve başlatıcıyı aç
                    onClicked: {
                        Niri.focusWorkspace(row.ws)
                        if (row.spare) Ui.openLauncher("search")
                    }
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
                            id: iconsRep
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
                                    source: Apps.iconFor(cell.win.app_id ?? "", cell.win.title ?? "")
                                    opacity: root.dragWin && root.dragWin.id === cell.win.id ? 0.25
                                        : cell.win.id === row.ws.active_window_id || iconMouse.containsMouse ? 1 : 0.55
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
                                    property point start
                                    property bool dragging: false
                                    property bool moved: false
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    onPressed: e => { start = Qt.point(e.x, e.y); dragging = false; moved = false }
                                    onPositionChanged: e => {
                                        if (!(pressedButtons & Qt.LeftButton) || cell.win.id === undefined) return
                                        const p = mapToItem(root, e.x, e.y)
                                        if (dragging) root.moveDrag(p)
                                        else if (Math.hypot(e.x - start.x, e.y - start.y) > 6) {
                                            dragging = true
                                            moved = true
                                            root.beginDrag(cell.win, row.index, cell.entry.col, p)
                                        }
                                    }
                                    onReleased: if (dragging) { dragging = false; root.endDrag(true) }
                                    onCanceled: if (dragging) { dragging = false; root.endDrag(false) }
                                    onClicked: e => {
                                        if (moved || cell.win.id === undefined) return
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

    // Aynı satırda bırakma yeri
    Rectangle {
        visible: root.dragWin !== null && root.dropSlot >= 0
        x: root.dropX - 1
        y: root.dropY + 9
        width: 2
        height: 24
        radius: 1
        color: root.rows[root.dropRow]?.ws.is_active ? Theme.accentInk : Theme.accent
    }

    // Sürüklenen simge imleçle gelir
    Rectangle {
        visible: root.dragWin !== null
        z: 10
        width: 38
        height: 38
        radius: 12
        x: root.dragAt.x - width / 2
        y: root.dragAt.y - height / 2
        color: Theme.panelSolid
        border.width: 1
        border.color: Theme.edge
        IconImage {
            anchors.centerIn: parent
            implicitSize: 26
            source: root.dragWin ? Apps.iconFor(root.dragWin.app_id ?? "", root.dragWin.title ?? "") : ""
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
