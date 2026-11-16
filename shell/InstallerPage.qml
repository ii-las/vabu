import QtQuick
import QtQuick.Layouts

// Kurulum kartındaki bir sayfa: başlık ve içerik. İleri giderken yeni sayfa sağdan,
// geri dönerken soldan kayarak gelir; eskisi kısa bir hızlanmayla çekilir.
FocusScope {
    id: page

    property string key: ""
    property int step: 0                        // üst şeritteki nokta
    property string heading: ""
    property string sub: ""
    property int headingSize: 26
    property bool canBack: true
    property string nextLabel: InstallerState.s.next
    property bool nextEnabled: true
    property string altLabel: ""
    property Item initialFocus: null
    property bool shown: false
    property int dir: 1
    default property alias content: body.data

    implicitHeight: column.implicitHeight
    visible: false
    enabled: false
    opacity: 0
    transform: Translate { id: shift }

    onShownChanged: {
        if (shown) {
            leaving.stop()
            page.visible = true
            page.enabled = true
            entering.restart()
            const target = page.initialFocus ?? page
            target.forceActiveFocus()
        } else {
            page.enabled = false
            entering.stop()
            leaving.restart()
        }
    }

    ParallelAnimation {
        id: entering
        NumberAnimation { target: page; property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation {
            target: shift; property: "x"; from: 28 * page.dir; to: 0
            duration: Theme.enter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized
        }
    }
    ParallelAnimation {
        id: leaving
        onFinished: if (!page.shown) page.visible = false
        NumberAnimation {
            target: page; property: "opacity"; to: 0
            duration: Theme.exit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate
        }
        NumberAnimation {
            target: shift; property: "x"; to: -20 * page.dir
            duration: Theme.exit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate
        }
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 20

        ColumnLayout {
            visible: page.heading !== ""
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: page.heading
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: page.headingSize
                font.weight: Font.DemiBold
                font.letterSpacing: page.headingSize >= 30 ? -0.5 : -0.4
                wrapMode: Text.Wrap
            }
            Text {
                visible: page.sub !== ""
                Layout.fillWidth: true
                text: page.sub
                color: Theme.soft
                font.family: Theme.sans
                font.pixelSize: 15
                lineHeight: 1.3
                wrapMode: Text.Wrap
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 14
        }
    }
}
