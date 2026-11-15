// Kurulum: kullanıcı bilgileri
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#121216"
    property int focusRow: 0

    component PairRow: RowLayout {
        id: row
        property string label
        property int rowIndex
        property alias text: input.text
        property bool secret: false
        property bool monoFont: false
        signal edited(string text)
        function focusField() { input.forceActiveFocus() }
        readonly property bool isOn: page.focusRow === rowIndex
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 250
            implicitHeight: 70
            radius: 20
            color: row.isOn ? "#A9C7F7" : "#26242C"
            Behavior on color { ColorAnimation { duration: 160 } }
            Text { anchors.verticalCenter: parent.verticalCenter; x: 24; text: row.label; color: row.isOn ? "#14243F" : "#F3F1EC"; font.family: "Instrument Serif"; font.pixelSize: 24 }
            MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 70
            radius: 20
            color: row.isOn ? "#A9C7F7" : "#26242C"
            Behavior on color { ColorAnimation { duration: 160 } }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: 13
                color: row.isOn ? "#1B2433" : "#34313B"
                // Calamares'in kendi QML sayfaları gibi Controls.TextField: klavye odağı
                // QQuickWidget içinde güvenilir şekilde buraya gelir
                TextField {
                    id: input
                    anchors.fill: parent
                    leftPadding: 18
                    rightPadding: 18
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#F3F1EC"
                    font.family: row.monoFont ? "Geist Mono" : "Geist"
                    font.pixelSize: 16
                    font.letterSpacing: row.secret ? 3 : 0
                    echoMode: row.secret ? TextInput.Password : TextInput.Normal
                    passwordCharacter: "●"
                    selectByMouse: true
                    selectionColor: "#A9C7F7"
                    background: Item {}
                    onActiveFocusChanged: if (activeFocus) page.focusRow = row.rowIndex
                    onTextEdited: row.edited(text)
                }
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(20, parent.height * 0.05)
        width: Math.min(720, parent.width - 80)
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 26
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.StyledText
            text: "Seni<br>tanıyalım"
            color: "#F3F1EC"
            font.family: "Instrument Serif"
            font.pixelSize: 56
            lineHeight: 0.95
        }

        PairRow { id: first; rowIndex: 0; label: "Adın"; text: config.fullName; onEdited: t => config.fullName = t }
        PairRow { rowIndex: 1; label: "Kullanıcı adı"; monoFont: true; text: config.loginName; onEdited: t => config.loginName = t }
        PairRow { id: pass1; rowIndex: 2; label: "Şifre"; secret: true; onEdited: t => config.userPassword = t }
        PairRow { id: pass2; rowIndex: 3; label: "Şifre tekrar"; secret: true; onEdited: t => config.userPasswordSecondary = t }
        PairRow { rowIndex: 4; label: "Bilgisayar adı"; monoFont: true; text: config.hostname; onEdited: t => config.hostname = t }

        // Durum: ilk sorunu sade bir cümleyle göster
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 10
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            readonly property string problem: {
                if (config.loginNameStatus) return config.loginNameStatus
                if (config.hostnameStatus) return config.hostnameStatus
                if (pass1.text && pass2.text && pass1.text !== pass2.text) return "Şifreler aynı değil."
                if (config.userPasswordMessage && pass1.text) return config.userPasswordMessage
                return ""
            }
            text: problem || "Şifren bu bilgisayarda yönetici işlemleri için de kullanılır."
            color: problem ? "#F7A8A8" : "#8E8B93"
            font.family: "Geist"
            font.pixelSize: 13
        }
    }

    // Sayfa açılınca ilk alana odaklan
    Component.onCompleted: first.focusField()
    onVisibleChanged: if (visible) first.focusField()
}
