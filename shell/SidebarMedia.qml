import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

Card {
    id: root
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    visible: Config.showMedia && player !== null
    implicitHeight: 72

    Timer {
        running: root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            implicitWidth: 48
            implicitHeight: 48
            radius: 12
            color: Theme.peach
            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Bilinmeyen parça"
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: [root.player?.trackArtist, root.player?.trackAlbum].filter(x => x).join(" · ")
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 5
                implicitHeight: 3
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.14)
                Rectangle {
                    width: parent.width * (root.player && root.player.length > 0 ? Math.min(1, root.player.position / root.player.length) : 0)
                    height: 3
                    radius: 2
                    color: Theme.paper
                }
            }
        }

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 18
            color: Theme.paper
            Icon {
                anchors.centerIn: parent
                name: root.player?.isPlaying ? "pause" : "play"
                color: "#16161B"
                size: 14
                stroke: 2.4
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player?.togglePlaying()
            }
            Accessible.role: Accessible.Button
            Accessible.name: root.player?.isPlaying ? "Duraklat" : "Oynat"
        }
    }
}
