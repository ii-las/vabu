// Kurulum bitti: tamamlandı ya da tamamlanamadı
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#F4F5F7"
    readonly property bool failed: (config.failureMessage || "") !== ""

    ColumnLayout {
        id: column
        x: Math.round((page.width - width) / 2)
        y: Math.max(24, Math.round((page.height - height) * 0.42))
        width: Math.min(480, page.width - 48)
        spacing: 0
        transform: Translate { id: shift }

        // Durum simgesi: başarıda vurgu, hatada tehlike rengi
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 22
            color: page.failed ? "#B93A30" : "#2C56CC"
            Text {
                anchors.centerIn: parent
                width: 34
                height: 34
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: page.failed ? "close" : "check"
                color: "#FFFFFF"
                font.family: "Material Symbols Rounded"
                font.weight: Font.Normal
                font.pixelSize: 34
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 18
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: page.failed ? "Kurulum tamamlanamadı" : "Vabu kuruldu"
            color: page.failed ? "#B93A30" : "#15181E"
            font.family: "Hanken Grotesk"
            font.pixelSize: 28
            font.weight: Font.DemiBold
            font.letterSpacing: -0.4
        }

        // Hata iletisi ve ayrıntısı (ayrıntı uzun olabilir; kart içinde kaydırılır)
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 10
            visible: page.failed
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            lineHeight: 1.2
            text: config.failureMessage || ""
            color: "#3B4250"
            font.family: "Hanken Grotesk"
            font.pixelSize: 14
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 20
            visible: page.failed && (config.failureDetails || "") !== ""
            implicitHeight: Math.min(details.implicitHeight + 28, 240)
            radius: 14
            color: "#FFFFFF"
            border.width: 1
            border.color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.07)

            Flickable {
                id: detailsView
                anchors.fill: parent
                anchors.margins: 14
                contentWidth: width
                contentHeight: details.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Text {
                    id: details
                    width: detailsView.width
                    wrapMode: Text.Wrap
                    text: config.failureDetails || ""
                    color: "#566070"
                    font.family: "Hanken Grotesk"
                    font.pixelSize: 13
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28
            Layout.preferredWidth: Math.max(200, restartText.implicitWidth + 48)
            Layout.preferredHeight: 46
            visible: !page.failed
            radius: 13
            color: restartMouse.pressed ? "#2347AE" : restartMouse.containsMouse ? "#284EBD" : "#2C56CC"
            Behavior on color { ColorAnimation { duration: 120 } }
            Accessible.role: Accessible.Button
            Accessible.name: "Yeniden başlat"

            Text {
                id: restartText
                anchors.centerIn: parent
                text: "Yeniden başlat"
                color: "#FFFFFF"
                font.family: "Hanken Grotesk"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: restartMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: config.doRestart(true)
            }
        }
    }

    // Sayfa açılırken hafifçe belirip yükselir
    ParallelAnimation {
        id: enter
        NumberAnimation { target: column; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation {
            target: shift; property: "y"; from: 12; to: 0; duration: 400
            easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
        }
    }
    // Calamares sayfa her açıldığında çağırır
    function onActivate() { enter.restart() }
}
