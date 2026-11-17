// Kurulum bitti: tamamlandı ya da tamamlanamadı
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#F4F3EF"
    readonly property bool failed: (config.failureMessage || "") !== ""

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.y + column.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
    ColumnLayout {
        id: column
        x: Math.round((page.width - width) / 2)
        y: Math.max(24, Math.round((page.height - height) * 0.42))
        width: Math.min(480, page.width - 48)
        spacing: 0

        // Durum simgesi: başarıda vurgu, hatada tehlike rengi
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            radius: 22
            color: page.failed ? "#B93A30" : "#2C56CC"
            Image {
                anchors.centerIn: parent
                width: 34
                height: 34
                source: page.failed ? "assets/close.svg" : "assets/check.svg"
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 18
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: page.failed ? "Kurulum tamamlanamadı" : "Vabu kuruldu"
            color: page.failed ? "#B93A30" : "#222725"
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
            color: "#414749"
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
                    color: "#585F5B"
                    font.family: "Hanken Grotesk"
                    font.pixelSize: 14
                }
            }
        }

        VabuButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28
            Layout.preferredWidth: 220
            visible: !page.failed
            primary: true
            text: "Yeniden başlat"
            onClicked: config.doRestart(true)
        }
    }
    }
}
