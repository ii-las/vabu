// Kurulum özeti: kurulumdan önce yapılacakların listesi
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#F4F3EF"

    // Adımın simgesi başlığından seçilir; tanınmayan adımlar genel simgeyi alır
    function iconFor(title) {
        const t = (title || "").toLowerCase()
        if (/klavye|keyboard/.test(t)) return "keyboard"
        if (/bölüm|disk|partition/.test(t)) return "hard_drive"
        if (/kullanıcı|hesap|user/.test(t)) return "person"
        if (/konum|bölge|dil|saat|location|locale|language/.test(t)) return "language"
        if (/paket|uygulama|package/.test(t)) return "apps"
        return "tune"
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.y + column.height + 32
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: column
            x: Math.round((flick.width - width) / 2)
            y: 32
            width: Math.min(640, flick.width - 48)
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: "Özet"
                color: "#222725"
                font.family: "Hanken Grotesk"
                font.pixelSize: 26
                font.weight: Font.DemiBold
                font.letterSpacing: -0.4
            }

            // Her adım bir satır: simge, başlık, açıklama
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 20
                visible: steps.count > 0
                implicitHeight: rows.implicitHeight
                radius: 14
                color: "#FFFFFF"
                border.width: 1
                border.color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.07)

                Column {
                    id: rows
                    width: parent.width

                    Repeater {
                        id: steps
                        model: config.summaryModel
                        delegate: Item {
                            width: rows.width
                            height: Math.max(60, texts.implicitHeight + 24)

                            Rectangle {
                                visible: index > 0
                                x: 16
                                width: parent.width - 32
                                height: 1
                                color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.08)
                            }
                            Text {
                                id: stepIcon
                                x: 16
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: page.iconFor(model.title)
                                color: "#414749"
                                font.family: "Material Symbols Rounded"
                                font.weight: Font.Light
                                font.pixelSize: 20
                            }
                            Column {
                                id: texts
                                anchors.left: stepIcon.right
                                anchors.leftMargin: 14
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: model.title
                                    color: "#222725"
                                    font.family: "Hanken Grotesk"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                }
                                Text {
                                    width: parent.width
                                    visible: text !== ""
                                    wrapMode: Text.Wrap
                                    text: model.message
                                    textFormat: Text.RichText
                                    color: "#585F5B"
                                    linkColor: "#2C56CC"
                                    font.family: "Hanken Grotesk"
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function onActivate() { flick.contentY = 0 }
}
