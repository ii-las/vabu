import QtQuick

// Kedi işareti (branding/logo-mark.svg): yüzü oyuk, rengi vurgudan gelir.
Image {
    id: root
    property real size: 30
    property color tint: Theme.accent

    width: size
    height: size
    sourceSize: Qt.size(size * 3, size * 3)
    smooth: true
    mipmap: true
    source: "data:image/svg+xml;charset=utf-8," + encodeURIComponent(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
        + '<defs><mask id="yuz"><rect width="256" height="256" fill="#fff"/>'
        + '<path d="M76 150 Q94 168 112 150" fill="none" stroke="#000" stroke-width="13" stroke-linecap="round"/>'
        + '<path d="M144 150 Q162 168 180 150" fill="none" stroke="#000" stroke-width="13" stroke-linecap="round"/>'
        + '<path d="M120 180 h16 l-8 9 z" fill="#000" stroke="#000" stroke-width="6" stroke-linejoin="round"/>'
        + '</mask></defs>'
        + '<path fill="' + root.tint + '" mask="url(#yuz)" d="M128 232 C62 232 22 202 22 156 C22 136 28 120 36 106 L50 52 Q55 36 69 45 L108 80 Q128 74 148 80 L187 45 Q201 36 206 52 L220 106 C228 120 234 136 234 156 C234 202 194 232 128 232 Z"/>'
        + '</svg>')
}
