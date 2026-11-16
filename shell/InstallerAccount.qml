import QtQuick
import QtQuick.Layouts

// Hesap: addan kullanıcı ve bilgisayar adı önerilir; elle değiştirilince öneri durur.
InstallerPage {
    id: page
    key: "account"
    step: 3
    heading: InstallerState.s.account
    initialFocus: nameField
    nextEnabled: InstallerState.accountOk

    Connections {
        target: InstallerState
        function onSecretsCleared() { passField.clear(); pass2Field.clear() }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 14
        rowSpacing: 14

        InstallerField {
            id: nameField
            objectName: "ad"
            Layout.columnSpan: 2
            Layout.fillWidth: true
            label: InstallerState.s.fullName
            maximumLength: 80
            next: loginField
            onTextChanged: {
                InstallerState.fullName = text
                if (!InstallerState.loginEdited) loginField.text = InstallerState.suggestLogin(text)
            }
        }
        InstallerField {
            id: loginField
            objectName: "kullanici"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            label: InstallerState.s.login
            maximumLength: 32
            error: InstallerState.loginError
            next: hostField
            onEdited: {
                const t = InstallerState.cleanLogin(text)
                if (t !== text) text = t
                InstallerState.loginEdited = text !== ""
            }
            onTextChanged: {
                InstallerState.login = text
                if (!InstallerState.hostEdited) hostField.text = InstallerState.suggestHost(text)
            }
        }
        InstallerField {
            id: hostField
            objectName: "bilgisayar"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            label: InstallerState.s.hostname
            maximumLength: 63
            error: InstallerState.hostError
            next: passField
            onEdited: {
                const t = InstallerState.cleanHost(text)
                if (t !== text) text = t
                InstallerState.hostEdited = text !== ""
            }
            onTextChanged: InstallerState.hostname = text
        }
        InstallerField {
            id: passField
            objectName: "sifre"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            label: InstallerState.s.password
            password: true
            next: pass2Field
            onTextChanged: InstallerState.password = text
        }
        InstallerField {
            id: pass2Field
            objectName: "sifre-tekrar"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            label: InstallerState.s.repeat
            password: true
            error: InstallerState.passwordError
            onTextChanged: InstallerState.password2 = text
        }
    }

    InstallerSwitch {
        objectName: "otomatik-giris"
        Layout.fillWidth: true
        label: InstallerState.s.autologin
        checked: InstallerState.autologin
        onToggled: InstallerState.autologin = !InstallerState.autologin
    }
}
