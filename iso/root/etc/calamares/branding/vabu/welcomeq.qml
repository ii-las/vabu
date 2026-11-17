// Kurulum: hoş geldin, dil seçimi, eksik gereksinimler
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Shapes 1.15

Rectangle {
    id: page
    color: "#F4F3EF"

    // Düğmelerin ortası sayfa ortasının 110 px altında durur. Eksik gereksinim çıkınca
    // üstteki blok yukarı kayar, düğmeler yerinde kalır. tests/ekran.sh "Vabu'yu kur"a
    // 1440x900 pencerede (866, 560) noktasından tıklar; burayı değiştirirsen onu da güncelle.
    readonly property int actionsCenter: Math.round(height / 2) + 110

    // Material Symbols Rounded: ikon adı metin olarak yazılır
    component Glyph: Text {
        width: font.pixelSize
        height: font.pixelSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "#222725"
        font.family: "Material Symbols Rounded"
        font.weight: Font.Light
        font.pixelSize: 20
    }

    // Uyuyan kedi: tek siluet, gözler ve burun oyuk (oyuk rengi altındaki zeminin rengi)
    component CatMark: Item {
        id: mark
        property color tint: "#FFFFFF"
        property color cutout: "#2C56CC"
        implicitWidth: 40
        implicitHeight: 40
        // kenarlar yumuşak çıksın diye çoklu örnekleme
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true

        Shape {
            width: 256
            height: 256
            scale: mark.width / 256
            transformOrigin: Item.TopLeft
            ShapePath {
                fillColor: mark.tint
                strokeColor: "transparent"
                PathSvg { path: "M128 232 C62 232 22 202 22 156 C22 136 28 120 36 106 L50 52 Q55 36 69 45 L108 80 Q128 74 148 80 L187 45 Q201 36 206 52 L220 106 C228 120 234 136 234 156 C234 202 194 232 128 232 Z" }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: mark.cutout
                strokeWidth: 13
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M76 150 Q94 168 112 150 M144 150 Q162 168 180 150" }
            }
            ShapePath {
                fillColor: mark.cutout
                strokeColor: mark.cutout
                strokeWidth: 6
                joinStyle: ShapePath.RoundJoin
                PathSvg { path: "M120 180 h16 l-8 9 z" }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.y + column.height + 24
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: column
            x: Math.round((flick.width - width) / 2)
            y: Math.max(24, page.actionsCenter - 23 - actions.y)
            width: Math.min(440, flick.width - 48)
            spacing: 0

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 20
                color: "#2C56CC"
                CatMark {
                    anchors.centerIn: parent
                    width: 42
                    height: 42
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 24
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "Vabu’ya hoş geldin"
                color: "#222725"
                font.family: "Hanken Grotesk"
                font.pixelSize: 30
                font.weight: Font.DemiBold
                font.letterSpacing: -0.5
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 32
                text: "Dil"
                color: "#585F5B"
                font.family: "Hanken Grotesk"
                font.pixelSize: 14
                font.weight: Font.Medium
            }
            ComboBox {
                id: lang
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.preferredHeight: 46
                model: config.languagesModel
                textRole: "label"
                currentIndex: config.localeIndex
                onActivated: config.localeIndex = currentIndex
                font.family: "Hanken Grotesk"
                font.pixelSize: 15
                // stilin kendi boşlukları yerine: solda yazı, sağda oka yer
                leftPadding: 14
                rightPadding: 44
                topPadding: 0
                bottomPadding: 0

                background: Rectangle {
                    radius: 12
                    color: lang.pressed || lang.popup.visible ? Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.13)
                         : lang.hovered ? Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.09)
                         : Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.06)
                    border.width: lang.visualFocus ? 1.5 : 0
                    border.color: "#2C56CC"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                contentItem: Text {
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: lang.displayText
                    color: "#222725"
                    font: lang.font
                }
                indicator: Image {
                    width: 20; height: 20
                    source: "assets/chevron-down.svg"
                    x: lang.width - width - 12
                    y: Math.round((lang.height - height) / 2)
                    rotation: lang.popup.visible ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }
                }
                popup: Popup {
                    y: lang.height + 6
                    width: lang.width
                    height: Math.min(contentItem.implicitHeight + 12, 320)
                    padding: 6
                    topMargin: 12
                    bottomMargin: 12

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: lang.popup.visible ? lang.delegateModel : null
                        currentIndex: lang.highlightedIndex
                        highlightMoveDuration: 0
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollIndicator.vertical: ScrollIndicator {}
                    }
                    background: Rectangle {
                        radius: 12
                        color: "#FFFFFF"
                        border.width: 1
                        border.color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.12)
                    }
                }
                delegate: ItemDelegate {
                    id: option
                    width: lang.width - 12
                    height: 44
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                    highlighted: lang.highlightedIndex === index
                    contentItem: Item {
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: tick.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: model.label
                            color: "#222725"
                            font.family: "Hanken Grotesk"
                            font.pixelSize: 15
                            font.weight: lang.currentIndex === index ? Font.Medium : Font.Normal
                        }
                        Image {
                            width: 20; height: 20
                            source: "assets/check-accent.svg"
                            id: tick
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: lang.currentIndex === index
                        }
                    }
                    background: Rectangle {
                        radius: 8
                        color: option.highlighted ? Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.06) : "transparent"
                    }
                }
            }

            // Karşılanmayan gereksinimler. Denetim bitmeden ya da hepsi tamamsa görünmez.
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                visible: requirements.count > 0 && !config.requirementsModel.satisfiedRequirements
                implicitHeight: requirementRows.implicitHeight
                radius: 14
                color: "#FFFFFF"
                border.width: 1
                border.color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.07)

                ColumnLayout {
                    id: requirementRows
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    Repeater {
                        id: requirements
                        model: config.requirementsModel
                        delegate: Item {
                            id: requirement
                            visible: !satisfied
                            Layout.fillWidth: true
                            implicitHeight: Math.max(52, problem.implicitHeight + 28)

                            Rectangle {
                                visible: requirement.y > 1
                                x: 16
                                width: parent.width - 32
                                height: 1
                                color: Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.08)
                            }
                            // Zorunlu olan kurulumu engeller, diğeri yalnızca uyarıdır
                            Glyph {
                                id: requirementIcon
                                x: 16
                                anchors.verticalCenter: parent.verticalCenter
                                text: mandatory ? "error" : "warning"
                                color: mandatory ? "#B93A30" : "#9A5A14"
                            }
                            Text {
                                id: problem
                                anchors.left: requirementIcon.right
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                wrapMode: Text.Wrap
                                text: negatedText
                                color: "#222725"
                                font.family: "Hanken Grotesk"
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }

            // İki yol: kur ya da kurmadan dene (canlı masaüstüne döner)
            Item {
                id: actions
                Layout.fillWidth: true
                Layout.topMargin: 28
                implicitHeight: 46

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    VabuButton {
                        implicitWidth: 200
                        text: "Kurmadan dene"
                        onClicked: ViewManager.quit()
                    }
                    VabuButton {
                        implicitWidth: 200
                        primary: true
                        text: "Vabu’yu kur"
                        enabled: ViewManager.nextEnabled
                        onClicked: ViewManager.next()
                    }
                }
            }
        }
    }

    function onActivate() { flick.contentY = 0 }
}
