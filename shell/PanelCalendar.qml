import QtQuick
import QtQuick.Layouts
import Quickshell

// Takvim: ay görünümü ve günün ışığı (gün doğumu, gün batımı).
ColumnLayout {
    id: root
    spacing: 6

    readonly property var months: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
    readonly property var weekdays: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property date today: clock.date
    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    readonly property bool thisMonth: year === today.getFullYear() && month === today.getMonth()

    function shift(n) {
        const d = new Date(year, month + n, 1)
        year = d.getFullYear()
        month = d.getMonth()
    }

    // 6 hafta x 7 gün; hafta pazartesi başlar
    readonly property var cells: {
        const first = new Date(year, month, 1)
        const lead = (first.getDay() + 6) % 7
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - lead + i)
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                today: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate(),
                weekend: i % 7 >= 5
            })
        }
        // son hafta tümüyle sonraki aya aitse gösterme
        return out[35].inMonth ? out : out.slice(0, 35)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.bottomMargin: 6
        spacing: 2
        Text {
            text: root.months[root.month]
            color: Theme.paper
            font.family: Theme.serif
            font.pixelSize: 28
            font.letterSpacing: -0.4
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.alignment: Qt.AlignBaseline
            text: root.year
            color: Theme.muted
            font.family: Theme.serif
            font.pixelSize: 28
            font.weight: Font.Light
            font.features: ({ "lnum": 1 })
        }
        IconButton {
            visible: !root.thisMonth
            implicitWidth: 34; implicitHeight: 34
            icon: "today"; iconSize: 19; iconColor: Theme.soft
            tooltip: "Bugüne dön"
            onClicked: { root.year = root.today.getFullYear(); root.month = root.today.getMonth() }
        }
        IconButton {
            implicitWidth: 34; implicitHeight: 34
            icon: "chevron_left"; iconSize: 22
            tooltip: "Önceki ay"
            onClicked: root.shift(-1)
        }
        IconButton {
            implicitWidth: 34; implicitHeight: 34
            icon: "chevron_right"; iconSize: 22
            tooltip: "Sonraki ay"
            onClicked: root.shift(1)
        }
    }

    Grid {
        id: grid
        Layout.fillWidth: true
        columns: 7
        readonly property real cell: Math.floor(width / 7)

        Repeater {
            model: root.weekdays
            delegate: Text {
                required property string modelData
                required property int index
                width: grid.cell
                height: 28
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: index >= 5 ? Theme.faint : Theme.muted
                font.family: Theme.sans
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
        Repeater {
            model: root.cells
            delegate: Item {
                required property var modelData
                width: grid.cell
                height: 42
                Rectangle {
                    anchors.centerIn: parent
                    width: 36; height: 36; radius: 18
                    color: modelData.today ? Theme.accent : "transparent"
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData.day
                    color: modelData.today ? Theme.accentInk
                        : !modelData.inMonth ? Theme.alpha(Theme.paper, 0.22)
                        : modelData.weekend ? Theme.muted : Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 14
                    font.weight: modelData.today ? Font.DemiBold : Font.Normal
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }

    // Günün ışığı
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 8
        implicitHeight: 58
        radius: Theme.radiusTile
        color: Theme.well

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Column {
                spacing: 1
                Text { text: "Gün doğumu"; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 11.5 }
                Text { text: Sun.sunriseText; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 14; font.weight: Font.Medium; font.features: ({ "tnum": 1 }) }
            }
            // gündüzün neresindeyiz
            Item {
                Layout.fillWidth: true
                implicitHeight: 14
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; radius: 1; color: Qt.rgba(1, 1, 1, 0.14) }
                Rectangle {
                    visible: !Sun.night
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.max(0, Math.min(1, Sun.progress))
                    height: 2; radius: 1
                    color: Theme.warn
                }
                Rectangle {
                    x: (parent.width - width) * Math.max(0, Math.min(1, Sun.progress))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10; height: 10; radius: 5
                    color: Sun.night ? Theme.faint : Theme.warn
                }
            }
            Column {
                spacing: 1
                Text { anchors.right: parent.right; text: "Gün batımı"; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 11.5 }
                Text { anchors.right: parent.right; text: Sun.sunsetText; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 14; font.weight: Font.Medium; font.features: ({ "tnum": 1 }) }
            }
        }
    }
}
