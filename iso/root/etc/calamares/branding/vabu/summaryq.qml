// Vabu kurulum · Özet: kurulumdan önce yapılacakların listesi.
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#151318"

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 60
        clip: true

        ColumnLayout {
            id: col
            x: (parent.width - width) / 2
            y: 30
            width: Math.min(820, page.width - 80)
            spacing: 12

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 20
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.StyledText
                text: "Her şey<br><i>hazır mı?</i>"
                color: "#EFECE6"
                font.family: "Hanken Grotesk"; font.weight: Font.DemiBold
                font.pixelSize: 56
                lineHeight: 0.95
            }

            Repeater {
                model: config.summaryModel
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: item.implicitHeight + 36
                    radius: 22
                    color: "#1B191E"
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    RowLayout {
                        id: item
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 16
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 36; implicitHeight: 36; radius: 18
                            color: "transparent"
                            border.color: Qt.rgba(1, 1, 1, 0.3)
                            Text { anchors.centerIn: parent; text: index + 1; color: "#CDC8C0"; font.family: "Hanken Grotesk"; font.pixelSize: 13 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { Layout.fillWidth: true; text: title; color: "#EFECE6"; font.family: "Hanken Grotesk"; font.weight: Font.DemiBold; font.pixelSize: 24; wrapMode: Text.Wrap }
                            Text {
                                Layout.fillWidth: true
                                text: message
                                textFormat: Text.RichText
                                color: "#CDC8C0"
                                linkColor: "#EFECE6"
                                font.family: "Hanken Grotesk"
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 8
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "“Kurulumu başlat”a bastığında disk değişiklikleri uygulanır; bu adım geri alınamaz."
                color: "#E8B07A"
                font.family: "Hanken Grotesk"
                font.pixelSize: 13
            }
        }
    }
}
