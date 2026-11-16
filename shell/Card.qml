import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

// Buzlu cam yüzey. Arkasında, ekrandaki yerine denk gelen duvar kağıdı parçasını
// bulanık gösterir, üstüne koyu bir ton ve 1 px kenar ışığı koyar. Bulanıklık duvar
// kağıdının küçük bir kopyasında hesaplanır; bu yüzden yükü yok denecek kadar azdır.
Item {
    id: root
    property real radius: Theme.radiusCard
    property color tint: Theme.panel
    property color edgeColor: Theme.edge
    property bool frosted: true
    property bool shadow: false
    // Pencerenin ekrandaki sol üst köşesi. Tam ekran ve kenara yaslı pencereler 0 bırakır.
    property real originX: 0
    property real originY: 0
    default property alias content: holder.data

    // Kartın ekrandaki yeri: arkadaki görüntü buna göre hizalanır
    property real sx: 0
    property real sy: 0
    // Dönüşümler (kayma, ölçek) bilerek hesaba katılmaz: kart hareket ederken arkası yerinde kalır
    function locate() {
        let px = originX, py = originY
        for (let it = root; it; it = it.parent) { px += it.x; py += it.y }
        sx = px
        sy = py
    }
    onXChanged: locate()
    onYChanged: locate()
    onWidthChanged: locate()
    onHeightChanged: locate()
    onOriginXChanged: locate()
    onOriginYChanged: locate()
    onVisibleChanged: if (visible) locate()

    // Üstteki öğelerden biri yer değiştirince de (liste kayması, yerleşim) yeniden hizalan
    property var watched: []
    function watch() {
        for (let it = root.parent; it; it = it.parent) {
            it.xChanged.connect(root.locate)
            it.yChanged.connect(root.locate)
            watched.push(it)
        }
    }
    Component.onCompleted: { watch(); locate() }
    Component.onDestruction: {
        for (const it of watched) {
            try { it.xChanged.disconnect(root.locate); it.yChanged.disconnect(root.locate) } catch (e) {}
        }
    }

    readonly property int k: 8      // küçültme oranı

    RectangularShadow {
        visible: root.shadow
        anchors.fill: parent
        radius: root.radius
        blur: 56
        spread: -4
        offset: Qt.vector2d(0, 18)
        color: Qt.rgba(0, 0, 0, 0.42)
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.frosted ? "#1B191E" : "transparent"

        Item {
            visible: root.frosted
            x: -root.sx
            y: -root.sy
            width: Screen.width / root.k
            height: Screen.height / root.k
            scale: root.k
            transformOrigin: Item.TopLeft

            Image {
                id: small
                anchors.fill: parent
                source: Config.wallpaper
                sourceSize.width: 480
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: small
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 14
                saturation: 0.28
            }
        }

        Rectangle { anchors.fill: parent; color: root.tint }

        // üstten gelen hafif ışık
        Rectangle {
            width: parent.width
            height: Math.min(parent.height, 120)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.045) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: root.edgeColor
    }

    Item { id: holder; anchors.fill: parent }
}
