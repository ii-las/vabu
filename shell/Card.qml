import QtQuick

// Vabu yüzeyi: mat koyu, 1 px iç kenar ışığı.
Rectangle {
    id: root
    property bool marks: false        // eski sürümle uyumluluk, kullanılmıyor
    property bool strong: false

    radius: Theme.radiusCard
    color: Theme.panel
    border.color: Theme.edge
    border.width: 1
}
