import QtQuick
import QtQuick.Layouts

// Saat dilimi: yazdıkça daralan liste. Oklar seçimi gezdirir, Enter seçer.
InstallerPage {
    id: page
    key: "zone"
    step: 1
    heading: InstallerState.s.timezone
    nextLabel: ""
    initialFocus: search
    readonly property var results: InstallerState.findZones(search.text)
    signal chosen()

    function choose(i) {
        const z = page.results[i]
        if (!z) return
        InstallerState.chooseZone(z.id)
        page.chosen()
    }
    function placeCurrent() {
        const i = page.results.findIndex(z => z.id === InstallerState.timezone)
        list.currentIndex = Math.max(0, i)
        list.positionViewAtIndex(list.currentIndex, ListView.Center)
    }

    onShownChanged: if (shown) { search.clear(); Qt.callLater(page.placeCurrent) }
    onResultsChanged: if (search.text !== "") list.currentIndex = 0

    InstallerField {
        id: search
        objectName: "saat-ara"
        Layout.fillWidth: true
        icon: "search"
        placeholder: InstallerState.s.search
        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onReturnPressed: page.choose(list.currentIndex)
        Keys.onEnterPressed: page.choose(list.currentIndex)
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 316
        radius: 14
        color: InstallerState.group
        border.width: 1
        border.color: Theme.groupEdge

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            model: page.results
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            keyNavigationEnabled: false

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool isOn: modelData.id === InstallerState.timezone
                width: ListView.view.width
                height: 54

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: row.ListView.isCurrentItem ? Theme.well : mouse.containsMouse ? Theme.hover : "transparent"
                }
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: check.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.city
                        color: Theme.paper
                        font.family: Theme.sans
                        font.pixelSize: 14
                        font.weight: row.isOn ? Font.DemiBold : Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: row.modelData.region !== ""
                        Layout.fillWidth: true
                        text: row.modelData.region
                        color: Theme.muted
                        font.family: Theme.sans
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
                Icon {
                    id: check
                    visible: row.isOn
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    name: "check"
                    size: 20
                    color: Theme.accent
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.choose(row.index)
                }
            }
        }

        Text {
            visible: page.results.length === 0
            anchors.centerIn: parent
            text: InstallerState.s.noResults
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: 14
        }
    }
}
