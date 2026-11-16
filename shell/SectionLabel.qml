import QtQuick
import QtQuick.Layouts

// Bölüm başlığı: küçük, sakin, cümle düzeninde.
Text { textFormat: Text.PlainText;
    Layout.fillWidth: true
    Layout.topMargin: 14
    Layout.bottomMargin: 2
    color: Theme.muted
    font.family: Theme.sans
    font.pixelSize: Math.round((12) * Config.textScale)
    font.weight: Font.Medium
    font.letterSpacing: 0.1
}
