import QtQuick
import QtQuick.Layouts

// Disk: kurulacak disk bütünüyle silinir. İstenirse disk şifrelenir.
InstallerPage {
    id: page
    key: "disks"
    step: 2
    heading: InstallerState.s.disks
    sub: InstallerState.disks.length > 0 ? InstallerState.s.eraseNote : ""
    nextEnabled: InstallerState.diskOk

    onShownChanged: if (shown) InstallerState.scanDisks()

    Connections {
        target: InstallerState
        function onSecretsCleared() { pass1.clear(); pass2.clear() }
    }

    RowLayout {
        visible: InstallerState.disksState === "loading" && InstallerState.disks.length === 0
        Layout.fillWidth: true
        Layout.preferredHeight: 68
        spacing: 12
        Spinner { size: 20; color: Theme.soft }
        Text {
            Layout.fillWidth: true
            text: InstallerState.s.scanning
            color: Theme.soft
            font.family: Theme.sans
            font.pixelSize: 14
        }
    }

    Rectangle {
        visible: InstallerState.disksState !== "loading" && InstallerState.disks.length === 0
        Layout.fillWidth: true
        implicitHeight: 68
        radius: 14
        color: InstallerState.group
        border.width: 1
        border.color: Theme.groupEdge
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 11
            spacing: 14
            Icon { name: "hard_drive"; size: 24; color: Theme.muted }
            Text {
                Layout.fillWidth: true
                text: InstallerState.s.noDisks
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 14
                font.weight: Font.Medium
                wrapMode: Text.Wrap
            }
            InstallerButton {
                implicitHeight: 40
                label: InstallerState.s.rescan
                onClicked: InstallerState.scanDisks()
            }
        }
    }

    ColumnLayout {
        visible: InstallerState.disks.length > 0
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: InstallerState.disks
            delegate: InstallerDisk {
                required property var modelData
                objectName: "disk-" + modelData.path
                Layout.fillWidth: true
                disk: modelData
                selected: InstallerState.disk === modelData.path
                onPicked: InstallerState.disk = modelData.path
            }
        }
    }

    InstallerSwitch {
        objectName: "sifrele"
        visible: InstallerState.disks.length > 0
        Layout.fillWidth: true
        label: InstallerState.s.encrypt
        checked: InstallerState.encrypt
        onToggled: {
            InstallerState.encrypt = !InstallerState.encrypt
            if (InstallerState.encrypt) pass1.forceActiveFocus()
        }
    }

    GridLayout {
        visible: InstallerState.encrypt && InstallerState.disks.length > 0
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 14
        rowSpacing: 14
        InstallerField {
            id: pass1
            objectName: "disk-sifre"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            label: InstallerState.s.diskPass
            password: true
            next: pass2
            onTextChanged: InstallerState.passphrase = text
        }
        InstallerField {
            id: pass2
            objectName: "disk-sifre-tekrar"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            label: InstallerState.s.repeat
            password: true
            error: InstallerState.passphraseError
            onTextChanged: InstallerState.passphrase2 = text
        }
    }
}
