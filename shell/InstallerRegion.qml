import QtQuick
import QtQuick.Layouts

// Bölge ve klavye: saat dilimi (alt sayfada aranır), klavye düzeni ve deneme alanı.
InstallerPage {
    id: page
    key: "region"
    step: 1
    heading: InstallerState.s.region
    initialFocus: tryField
    readonly property string typed: tryField.text
    signal zoneRequested()

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: rows.implicitHeight
        radius: 14
        color: InstallerState.group
        border.width: 1
        border.color: Theme.groupEdge

        ColumnLayout {
            id: rows
            width: parent.width
            spacing: 0

            InstallerRow {
                objectName: "saat-dilimi"
                Layout.fillWidth: true
                label: InstallerState.s.timezone
                value: InstallerState.zoneLabel(InstallerState.timezone)
                onActivated: page.zoneRequested()
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                implicitHeight: 1
                color: Theme.line
            }
            Item {
                Layout.fillWidth: true
                implicitHeight: 56
                Text {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: InstallerState.s.keyboard
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                InstallerChoice {
                    objectName: "klavye"
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    options: InstallerState.keyboards.map(k => InstallerState.lang === "en" ? k.en : k.tr)
                    currentIndex: InstallerState.keyboard
                    onPicked: i => InstallerState.chooseKeyboard(i)
                }
            }
        }
    }

    InstallerField {
        id: tryField
        objectName: "klavye-dene"
        Layout.fillWidth: true
        label: InstallerState.s.tryKeyboard
    }
}
