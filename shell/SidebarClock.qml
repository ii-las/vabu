import QtQuick
import QtQuick.Layouts
import Quickshell

// Saat ve tarih. Tıklayınca takvim açılır.
Card {
    id: root
    property string screenName: ""
    readonly property bool active: Ui.popover === "calendar" && Ui.popoverScreen === screenName
    implicitHeight: col.implicitHeight + 38
    edgeColor: active ? Qt.rgba(1, 1, 1, 0.22) : Theme.edge

    readonly property var days: ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
    readonly property var months: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

    SystemClock {
        id: clock
        precision: Config.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 18
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: Qt.formatTime(clock.date, Config.showSeconds ? "HH:mm:ss" : "HH:mm")
            color: Theme.paper
            font.family: Theme.serif
            font.weight: Font.Light
            font.pixelSize: Config.showSeconds ? 54 : 82
            font.letterSpacing: Config.showSeconds ? -1 : -2
            font.features: ({ "tnum": 1, "lnum": 1 })
            lineHeight: 0.92
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.days[clock.date.getDay()]
                color: Theme.soft
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Text {
                text: clock.date.getDate() + " " + root.months[clock.date.getMonth()]
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 13
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Ui.togglePopover("calendar", root.screenName)
    }
    Accessible.role: Accessible.Button
    Accessible.name: "Takvim"
}
