import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

// Çalan parça. Sadece bir şey çalarken ya da duraklatılmışken görünür.
Card {
    id: root
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property real progress: player && player.length > 0 ? Math.max(0, Math.min(1, player.position / player.length)) : 0
    visible: Config.showMedia && player !== null
    implicitHeight: 68

    Timer {
        running: root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 12

        ClippingRectangle {
            implicitWidth: 46
            implicitHeight: 46
            radius: 12
            color: Theme.well
            Icon { anchors.centerIn: parent; name: "music_note"; size: 22; color: Theme.muted }
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
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Bilinmeyen parça"
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: Math.round((13) * Config.textScale)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                text: root.player?.trackArtist || root.player?.identity || ""
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: Theme.textSmall
                elide: Text.ElideRight
            }
        }

        IconButton {
            implicitWidth: 34; implicitHeight: 34
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            iconSize: 24
            filled: true
            tooltip: root.player?.isPlaying ? "Duraklat" : "Oynat"
            onClicked: root.player?.togglePlaying()
        }
        IconButton {
            implicitWidth: 34; implicitHeight: 34
            visible: root.player?.canGoNext ?? false
            icon: "skip_next"
            iconSize: 22
            filled: true
            iconColor: Theme.soft
            tooltip: Lang.t("Sonraki")
            onClicked: root.player?.next()
        }
    }

    // ilerleme: kartın alt kenarında ince bir çizgi
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.bottomMargin: 1
        height: 2
        visible: root.progress > 0
        Rectangle {
            width: parent.width * root.progress
            height: 2
            radius: 1
            color: Theme.alpha(Theme.paper, 0.55)
            Behavior on width { NumberAnimation { duration: Config.reducedMotion ? 0 : 900 } }
        }
    }
}
