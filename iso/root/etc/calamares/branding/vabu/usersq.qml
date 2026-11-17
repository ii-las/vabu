// Kurulum: kullanıcı hesabı
import io.calamares.core 1.0
import io.calamares.ui 1.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Rectangle {
    id: page
    color: "#F4F3EF"

    // Üstte ad, altında alan
    component LabeledField: Column {
        id: field
        property string label
        property alias text: input.text
        property bool secret: false
        signal edited(string text)
        function focusField() { input.forceActiveFocus() }
        spacing: 6

        Text {
            width: parent.width
            text: field.label
            color: "#585F5B"
            font.family: "Hanken Grotesk"
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        // Calamares'in kendi QML sayfaları gibi Controls.TextField: düz TextInput
        // Calamares penceresinde klavye odağını alamıyor
        TextField {
            id: input
            width: parent.width
            height: 46
            leftPadding: 14
            rightPadding: 14
            topPadding: 0
            bottomPadding: 0
            verticalAlignment: TextInput.AlignVCenter
            color: "#222725"
            font.family: "Hanken Grotesk"
            font.pixelSize: 15
            echoMode: field.secret ? TextInput.Password : TextInput.Normal
            passwordCharacter: "●"
            selectByMouse: true
            selectionColor: "#2C56CC"
            selectedTextColor: "#FFFFFF"
            background: Rectangle {
                radius: 12
                color: input.hovered && !input.activeFocus ? Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.09)
                     : Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.06)
                border.width: input.activeFocus ? 1.5 : 0
                border.color: "#2C56CC"
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            onTextEdited: field.edited(text)
        }
    }

    ColumnLayout {
        id: column
        x: Math.round((page.width - width) / 2)
        y: 32
        width: Math.min(640, page.width - 48)
        spacing: 0
        transform: Translate { id: shift }

        Text {
            Layout.fillWidth: true
            text: "Hesabını oluştur"
            color: "#222725"
            font.family: "Hanken Grotesk"
            font.pixelSize: 26
            font.weight: Font.DemiBold
            font.letterSpacing: -0.4
        }

        // İki sütun: ad tam genişlikte, altında ikişer alan
        Column {
            id: form
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 14
            readonly property real half: (column.width - 14) / 2

            LabeledField { id: first; width: column.width; label: "Adın"; text: config.fullName; onEdited: t => config.fullName = t }
            Row {
                spacing: 14
                LabeledField { width: form.half; label: "Kullanıcı adı"; text: config.loginName; onEdited: t => config.loginName = t }
                LabeledField { width: form.half; label: "Bilgisayar adı"; text: config.hostname; onEdited: t => config.hostname = t }
            }
            Row {
                spacing: 14
                LabeledField { id: pass1; width: form.half; label: "Şifre"; secret: true; onEdited: t => config.userPassword = t }
                LabeledField { id: pass2; width: form.half; label: "Şifre tekrar"; secret: true; onEdited: t => config.userPasswordSecondary = t }
            }
        }

        // Durum: sorun varsa ilkini göster, yoksa satır hiç görünmez
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 14
            spacing: 8
            visible: status.problem !== ""

            Text {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "error"
                color: "#B93A30"
                font.family: "Material Symbols Rounded"
                font.weight: Font.Light
                font.pixelSize: 18
            }
            Text {
                id: status
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                readonly property string problem: {
                    if (config.loginNameStatus) return config.loginNameStatus
                    if (config.hostnameStatus) return config.hostnameStatus
                    if (pass1.text && pass2.text && pass1.text !== pass2.text) return "Şifreler aynı değil."
                    if (config.userPasswordMessage && pass1.text) return config.userPasswordMessage
                    return ""
                }
                text: problem
                color: "#B93A30"
                font.family: "Hanken Grotesk"
                font.pixelSize: 14
            }
        }
    }

    // Sayfa açılırken hafifçe belirip yükselir
    ParallelAnimation {
        id: enter
        NumberAnimation { target: column; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation {
            target: shift; property: "y"; from: 12; to: 0; duration: 400
            easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
        }
    }

    // Sayfa açılınca ilk alana odaklan
    Component.onCompleted: first.focusField()
    onVisibleChanged: if (visible) first.focusField()
    // Calamares sayfa her açıldığında çağırır
    function onActivate() {
        enter.restart()
        first.focusField()
    }
}
