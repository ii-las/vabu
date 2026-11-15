// Kurulum: hoş geldin, dil seçimi, gereksinimler
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#121216"

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(30, parent.height * 0.08)
        width: Math.min(720, parent.width - 80)
        spacing: 40

        Text {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.StyledText
            text: "Vabu’ya<br><i>hoş geldin</i>"
            color: "#F3F1EC"
            font.family: "Instrument Serif"
            font.pixelSize: 64
            lineHeight: 0.95
        }

        // İki parçalı satır: Dil
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 250
                implicitHeight: 76
                radius: 22
                color: "#A9C7F7"
                Text { anchors.verticalCenter: parent.verticalCenter; x: 24; text: "Dil"; color: "#14243F"; font.family: "Instrument Serif"; font.pixelSize: 26 }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 76
                radius: 22
                color: "#A9C7F7"
                ComboBox {
                    id: lang
                    anchors.fill: parent
                    anchors.margins: 8
                    model: config.languagesModel
                    textRole: "label"
                    currentIndex: config.localeIndex
                    onActivated: config.localeIndex = currentIndex
                    font.family: "Geist"
                    font.pixelSize: 16
                    background: Rectangle { radius: 15; color: "#1B2433" }
                    contentItem: Text {
                        leftPadding: 18
                        verticalAlignment: Text.AlignVCenter
                        text: lang.displayText
                        color: "#F3F1EC"
                        font: lang.font
                    }
                    indicator: Text { x: lang.width - width - 18; anchors.verticalCenter: parent.verticalCenter; text: "▾"; color: "#8E8B93"; font.pixelSize: 16 }
                    popup.background: Rectangle { color: "#1D1C22"; radius: 14; border.color: Qt.rgba(1, 1, 1, 0.1) }
                    delegate: ItemDelegate {
                        width: lang.width
                        highlighted: lang.highlightedIndex === index
                        contentItem: Text { text: model.label; color: highlighted ? "#14243F" : "#F3F1EC"; font.family: "Geist"; font.pixelSize: 15 }
                        background: Rectangle { color: highlighted ? "#A9C7F7" : "transparent"; radius: 10 }
                    }
                }
            }
        }

        // Gereksinimler: yalnızca karşılanmayanlar gösterilir
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: config.requirementsModel
                delegate: Rectangle {
                    visible: !satisfied
                    Layout.fillWidth: true
                    implicitHeight: visible ? req.implicitHeight + 28 : 0
                    radius: 16
                    color: mandatory ? Qt.rgba(247 / 255, 168 / 255, 168 / 255, 0.1) : Qt.rgba(242 / 255, 180 / 255, 138 / 255, 0.1)
                    border.color: mandatory ? "#F7A8A8" : "#F2B48A"
                    Column {
                        id: req
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4
                        Text { width: parent.width; text: name; color: "#F3F1EC"; font.family: "Geist"; font.pixelSize: 14; wrapMode: Text.Wrap }
                        Text { width: parent.width; text: details; color: "#CFC9C2"; font.family: "Geist"; font.pixelSize: 12; wrapMode: Text.Wrap }
                    }
                }
            }
        }

        // Kurmadan dene: kurulumu kapatıp canlı masaüstüne geçer.
        // Kurulum daha sonra başlatıcıdan "Vabu'yu kur" ile açılabilir.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: tryRow.implicitWidth + 44
            implicitHeight: 52
            radius: 26
            color: tryMouse.containsMouse ? "#34313B" : "#26242C"
            Row {
                id: tryRow
                anchors.centerIn: parent
                spacing: 10
                Text { text: "Kurmadan dene"; color: "#F3F1EC"; font.family: "Geist"; font.pixelSize: 15 }
                Text { text: "→"; color: "#A3A1A8"; font.pixelSize: 15 }
            }
            MouseArea { id: tryMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ViewManager.quit() }
            Accessible.role: Accessible.Button
            Accessible.name: "Kurmadan dene"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "KURULUMU SONRA BAŞLATICIDAN “VABU’YU KUR” İLE AÇABİLİRSİN"
            color: "#8E8B93"
            font.family: "Geist Mono"
            font.pixelSize: 11
            font.letterSpacing: 1.4
        }
    }
}
