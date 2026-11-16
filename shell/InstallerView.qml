import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell

// Kurulumun bütün yüzeyi: bulanık duvar kağıdı, üstte işaret ve adım noktaları,
// ortada cam kart. Kartın yüksekliği sayfadan sayfaya yumuşakça değişir.
FocusScope {
    id: view

    readonly property var s: InstallerState.s
    property Item current: welcome
    property bool ready: false
    readonly property bool hasButtons: current.canBack || current.altLabel !== "" || current.nextLabel !== ""
    property real tail: hasButtons ? 66 : 0
    Behavior on tail { enabled: view.ready; NumberAnimation { duration: Theme.enter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

    function go(page, dir) {
        if (page === current) return
        const old = current
        old.dir = dir
        page.dir = dir
        current = page
        old.shown = false
        page.shown = true
    }
    function next() {
        if (confirm.open || current.nextLabel === "" || !current.nextEnabled) return
        switch (current.key) {
        case "welcome": go(region, 1); break
        case "region": InstallerState.applyKeyboard(); go(disks, 1); break
        case "disks": go(account, 1); break
        case "account": go(summary, 1); break
        case "summary": confirm.show(); break
        case "run": InstallerState.install(); break
        case "done": InstallerState.reboot(); break
        }
    }
    function back() {
        if (confirm.open || !current.canBack) return
        switch (current.key) {
        case "region": go(welcome, -1); break
        case "zone": go(region, -1); break
        case "disks": go(region, -1); break
        case "account": go(disks, -1); break
        case "summary": go(account, -1); break
        }
    }
    function alt() {
        switch (current.key) {
        case "welcome":
        case "done": Qt.quit(); break
        case "run": go(summary, -1); break
        }
    }
    function start() {
        confirm.close()
        go(run, 1)
        InstallerState.install()
    }
    // Test ve hata ayıklama için (qs ipc call installer state)
    function describe() {
        const f = view.Window.activeFocusItem
        return {
            page: current.key,
            focus: f ? (f.objectName || String(f)) : "",
            typed: region.typed,
            lang: InstallerState.lang,
            timezone: InstallerState.timezone,
            keyboard: InstallerState.keyboards[InstallerState.keyboard].layout + (InstallerState.keyboards[InstallerState.keyboard].variant ? "/" + InstallerState.keyboards[InstallerState.keyboard].variant : ""),
            disk: InstallerState.disk,
            encrypt: InstallerState.encrypt,
            fullName: InstallerState.fullName,
            login: InstallerState.login,
            hostname: InstallerState.hostname,
            run: InstallerState.runState,
            progress: InstallerState.progress
        }
    }

    Keys.onReturnPressed: view.next()
    Keys.onEnterPressed: view.next()
    Keys.onEscapePressed: {
        if (confirm.open) confirm.close()
        else if (current.key === "zone") view.back()
    }

    Connections {
        target: InstallerState
        function onRunStateChanged() { if (InstallerState.runState === "done") view.go(done, 1) }
    }

    Component.onCompleted: welcome.shown = true
    Timer { interval: 80; running: true; onTriggered: view.ready = true }

    // Zemin: duvar kağıdı, bulanık ve hafif bir tülle
    Rectangle { anchors.fill: parent; color: Theme.night }
    Image {
        id: wall
        anchors.fill: parent
        source: Config.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 960
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 0.7
        blurMax: 32
    }
    Rectangle { anchors.fill: parent; color: InstallerState.veil }

    // Üst şerit: işaret ve adımlar
    Item {
        id: strip
        width: parent.width
        height: 64
        enabled: !confirm.open

        Row {
            x: 32
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            InstallerLogo { size: 30; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: view.s.brand
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: 7
                delegate: Rectangle {
                    required property int index
                    width: index === view.current.step ? 28 : 10
                    height: 5
                    radius: 2.5
                    color: index <= view.current.step ? Theme.accent : InstallerState.dotOff
                    Behavior on width { NumberAnimation { duration: Theme.enter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                    Behavior on color { ColorAnimation { duration: Theme.state } }
                }
            }
        }
    }

    Card {
        id: card
        enabled: !confirm.open
        readonly property real inner: stage.height - 8
        width: Math.min(640, view.width - 32)
        height: 32 + inner + view.tail + 32
        x: Math.round((view.width - width) / 2)
        y: Math.round(Math.max(72, Math.min(104, view.height - height - 24)))
        radius: Theme.radiusPanel
        tint: Theme.panelDeep
        shadow: true
        opacity: view.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        // Sayfalar üst üste durur; geçişte kayan sayfa kartın kenarında kırpılır
        Item {
            id: stage
            y: 28
            width: card.width
            height: view.current.implicitHeight + 8
            clip: true
            Behavior on height {
                enabled: view.ready
                NumberAnimation { duration: Theme.enter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            }

            InstallerWelcome { id: welcome; x: 32; y: 4; width: stage.width - 64 }
            InstallerRegion { id: region; x: 32; y: 4; width: stage.width - 64; onZoneRequested: view.go(zone, 1) }
            InstallerZone { id: zone; x: 32; y: 4; width: stage.width - 64; onChosen: view.go(region, -1) }
            InstallerDisks { id: disks; x: 32; y: 4; width: stage.width - 64 }
            InstallerAccount { id: account; x: 32; y: 4; width: stage.width - 64 }
            InstallerSummary { id: summary; x: 32; y: 4; width: stage.width - 64 }
            InstallerRun { id: run; x: 32; y: 4; width: stage.width - 64 }
            InstallerDone { id: done; x: 32; y: 4; width: stage.width - 64 }
        }

        RowLayout {
            id: buttons
            x: 32
            y: 32 + card.inner + 20
            width: card.width - 64
            spacing: 10
            opacity: view.hasButtons ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Theme.state } }

            InstallerButton {
                objectName: "geri"
                visible: view.current.canBack
                icon: "arrow_back"
                Accessible.name: view.s.back
                onClicked: view.back()
            }
            Item { Layout.fillWidth: true }
            InstallerButton {
                objectName: "ikincil"
                visible: view.current.altLabel !== ""
                label: view.current.altLabel
                onClicked: view.alt()
            }
            InstallerButton {
                objectName: "ileri"
                visible: view.current.nextLabel !== ""
                primary: true
                enabled: view.current.nextEnabled
                label: view.current.nextLabel
                onClicked: view.next()
            }
        }
    }

    // Silme onayı
    FocusScope {
        id: confirm
        property bool open: false
        anchors.fill: parent
        visible: open || opacity > 0.01
        opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: confirm.open ? Theme.state : Theme.exit; easing.type: Easing.OutCubic } }

        function show() {
            open = true
            cancelButton.forceActiveFocus()
        }
        function close() {
            if (!open) return
            open = false
            view.current.forceActiveFocus()
        }

        Rectangle { anchors.fill: parent; color: Theme.scrim }
        MouseArea { anchors.fill: parent; onClicked: confirm.close() }

        Card {
            id: box
            width: Math.min(460, view.width - 48)
            height: boxColumn.implicitHeight + 56
            anchors.centerIn: parent
            radius: Theme.radiusPanel
            tint: Theme.panelDeep
            shadow: true
            scale: confirm.open ? 1 : 0.96
            Behavior on scale { NumberAnimation { duration: Theme.enter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: boxColumn
                x: 28
                y: 28
                width: parent.width - 56
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: view.s.confirmTitle
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.2
                }
                Text {
                    Layout.fillWidth: true
                    text: InstallerState.diskInfo
                        ? view.s.confirmText(InstallerState.diskName(InstallerState.diskInfo) + " (" + InstallerState.sizeText(InstallerState.diskInfo.size) + ")")
                        : ""
                    color: Theme.soft
                    font.family: Theme.sans
                    font.pixelSize: 15
                    lineHeight: 1.3
                    wrapMode: Text.Wrap
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    spacing: 10
                    Item { Layout.fillWidth: true }
                    InstallerButton {
                        id: cancelButton
                        objectName: "vazgec"
                        label: view.s.cancel
                        onClicked: confirm.close()
                    }
                    InstallerButton {
                        objectName: "sil-ve-kur"
                        danger: true
                        label: view.s.erase
                        onClicked: view.start()
                    }
                }
            }
        }
    }
}
