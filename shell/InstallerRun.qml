import QtQuick
import QtQuick.Layouts

// Kuruluyor: ilerleme çubuğu ve adımlar. Hata olursa ileti olduğu gibi gösterilir.
InstallerPage {
    id: page
    key: "run"
    step: 5
    readonly property bool failed: InstallerState.runState === "error"
    heading: failed ? InstallerState.s.failed : InstallerState.s.installing
    canBack: false
    nextLabel: failed ? InstallerState.s.retry : ""
    altLabel: failed ? InstallerState.s.goBack : ""

    ColumnLayout {
        visible: !page.failed
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            id: track
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Theme.track
            Rectangle {
                height: parent.height
                radius: 3
                color: Theme.accent
                width: Math.max(6, track.width * InstallerState.progress / 100)
                Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: InstallerState.stepLabel
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                text: InstallerState.s.percent(InstallerState.progress)
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 13
                font.features: ({ "tnum": 1 })
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: steps.implicitHeight + 8
        radius: 14
        color: InstallerState.group
        border.width: 1
        border.color: Theme.groupEdge

        ColumnLayout {
            id: steps
            y: 4
            width: parent.width
            spacing: 0
            Repeater {
                model: InstallerState.stepKeys
                delegate: Item {
                    id: row
                    required property string modelData
                    required property int index
                    // done | active | error | wait
                    readonly property string phase: InstallerState.runState === "done" || index < InstallerState.stepIndex ? "done"
                        : index > InstallerState.stepIndex ? "wait"
                        : page.failed ? "error" : "active"
                    Layout.fillWidth: true
                    implicitHeight: 44

                    Item {
                        x: 16
                        width: 22
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        // biten adım: dolu daire ve tik; hatalı adım: kırmızı daire; sıradaki: ince halka
                        Rectangle {
                            anchors.centerIn: parent
                            visible: row.phase === "done" || row.phase === "error"
                            width: 20
                            height: 20
                            radius: 10
                            color: row.phase === "error" ? Theme.danger : Theme.accent
                            Icon {
                                anchors.centerIn: parent
                                name: row.phase === "error" ? "priority_high" : "check"
                                size: 15
                                weight: 500
                                color: row.phase === "error" ? Theme.ink : Theme.accentInk
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            visible: row.phase === "wait"
                            width: 18
                            height: 18
                            radius: 9
                            color: "transparent"
                            border.width: 1.5
                            border.color: Theme.alpha(Theme.faint, 0.8)
                        }
                        Spinner {
                            anchors.centerIn: parent
                            visible: row.phase === "active"
                            running: visible
                            size: 19
                            color: Theme.accent
                        }
                    }
                    Text {
                        x: 50
                        width: parent.width - 66
                        anchors.verticalCenter: parent.verticalCenter
                        text: InstallerState.s.steps[row.modelData]
                        color: row.phase === "wait" ? Theme.muted : Theme.paper
                        font.family: Theme.sans
                        font.pixelSize: 14
                        font.weight: row.phase === "active" ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Rectangle {
        visible: page.failed
        Layout.fillWidth: true
        implicitHeight: message.implicitHeight + 28
        radius: 14
        color: Theme.alpha(Theme.danger, Theme.dark ? 0.12 : 0.07)
        border.width: 1
        border.color: Theme.alpha(Theme.danger, 0.24)

        Icon {
            x: 14
            y: 13
            name: "error"
            size: 20
            color: Theme.danger
        }
        TextEdit {
            id: message
            x: 46
            y: 14
            width: parent.width - 62
            readOnly: true
            selectByMouse: true
            activeFocusOnTab: false
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            text: InstallerState.runError
            color: Theme.paper
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            font.family: Theme.sans
            font.pixelSize: 14
        }
    }
}
