import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

ColumnLayout {
    id: page
    spacing: 24

    // Duvar kağıdı
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10
        Text { textFormat: Text.PlainText; Layout.leftMargin: 4; text: Lang.t("Duvar kağıdı"); color: Theme.muted; font.family: Theme.sans; font.pixelSize: Theme.textSmall; font.weight: Font.Medium }
        GridLayout {
            id: wallpaperGrid
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            columns: Math.max(1, Math.min(5, Math.floor(width / (140 * Config.textScale))))
            columnSpacing: 12
            uniformCellWidths: true
            Repeater {
                // "auto": görünüme göre gündüz ya da alacakaranlık
                model: [{ name: Lang.t("Otomatik"), path: "auto" }].concat(Config.wallpapers).concat([{ name: Lang.t("Kendi resmin"), path: "" }])
                delegate: ColumnLayout {
                    id: wp
                    required property var modelData
                    readonly property bool custom: modelData.path === ""
                    readonly property bool auto: modelData.path === "auto"
                    readonly property string choice: Config.wallpaperChoice
                    readonly property bool isOn: custom ? (choice !== "auto" && !Config.wallpapers.some(w => w.path === choice))
                        : choice === modelData.path
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 8
                    Item {
                        id: wallpaperChoice
                        activeFocusOnTab: true
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: wp.modelData.name
                        Accessible.checked: wp.isOn
                        function choose() { wp.custom ? picker.open() : Config.set("wallpaper", wp.auto ? null : wp.modelData.path) }
                        Keys.onSpacePressed: choose()
                        Keys.onReturnPressed: choose()
                        Keys.onEnterPressed: choose()
                        Layout.fillWidth: true
                        implicitHeight: Math.round(width * 0.6)
                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Theme.well
                            // otomatik: yarısı gündüz, yarısı alacakaranlık
                            Row {
                                visible: wp.auto
                                anchors.fill: parent
                                Repeater {
                                    model: wp.auto ? [Config.wallpapers[0].path, Config.wallpapers[1].path] : []
                                    delegate: Image {
                                        required property string modelData
                                        width: parent.width / 2
                                        height: parent.height
                                        source: modelData
                                        sourceSize: Qt.size(240, 300)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }
                            }
                            Image {
                                anchors.fill: parent
                                visible: !wp.auto && (!wp.custom || wp.isOn)
                                source: wp.auto ? "" : wp.custom ? (wp.isOn ? Config.wallpaper : "") : wp.modelData.path
                                sourceSize: Qt.size(480, 300)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Icon { visible: wp.custom && !wp.isOn; anchors.centerIn: parent; name: "add_photo_alternate"; color: Theme.muted; size: 24 }
                        }
                        // seçili: dışta ince bir halka
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -4
                            radius: 18
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.accent
                            opacity: wp.isOn || wallpaperChoice.activeFocus ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.state } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { wallpaperChoice.forceActiveFocus(Qt.MouseFocusReason); wallpaperChoice.choose() }
                        }
                    }
                    Text { textFormat: Text.PlainText;
                        Layout.leftMargin: 2
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        wrapMode: Text.Wrap
                        text: Lang.t(wp.modelData.name)
                        color: wp.isOn ? Theme.paper : Theme.soft
                        font.family: Theme.sans
                        font.pixelSize: Theme.textSmall
                        font.weight: wp.isOn ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }
    }

    FileDialog {
        id: picker
        title: Lang.t("Duvar kağıdı seç")
        nameFilters: ["Resimler (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: Config.set("wallpaper", String(selectedFile).replace(/^file:\/\//, ""))
    }

    Group {
        title: Lang.t("Tema")
        SettingRow {
            label: Lang.t("Görünüm")
            Segmented {
                options: [Lang.t("Açık"), Lang.t("Koyu"), Lang.t("Otomatik")]
                currentIndex: ["acik", "koyu", "otomatik"].indexOf(Config.theme)
                onPicked: i => Config.set("theme", ["acik", "koyu", "otomatik"][i])
            }
        }
        SettingRow {
            label: Lang.t("Vurgu rengi")
            Repeater {
                model: Object.keys(Config.accents)
                delegate: Item {
                    id: swatch
                    required property var modelData
                    readonly property bool isOn: Config.accentName === modelData
                    readonly property color tone: Theme.dark ? Config.accents[modelData].dark : Config.accents[modelData].light
                    width: 36; height: 36
                    activeFocusOnTab: true
                    function choose() { Config.set("accent", modelData); NiriConf.apply(false) }
                    Keys.onSpacePressed: choose()
                    Keys.onReturnPressed: choose()
                    Keys.onEnterPressed: choose()
                    Accessible.checked: isOn
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: Lang.t(Config.accents[modelData].name)
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "transparent"
                        border.width: 2
                        border.color: swatch.tone
                        opacity: swatch.activeFocus ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.state } }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: width
                        radius: width / 2
                        color: swatch.tone
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: swatch.isOn
                        name: "check"
                        size: 18
                        color: Theme.dark ? Config.accents[swatch.modelData].darkInk : "#FFFFFF"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { swatch.forceActiveFocus(Qt.MouseFocusReason); swatch.choose() }
                    }
                }
            }
        }
    }

    Group {
        title: Lang.t("Yan panel")
        SettingRow {
            label: Lang.t("Konum")
            Segmented {
                options: [Lang.t("Sol"), Lang.t("Sağ")]
                currentIndex: Config.sidebarSide === "right" ? 1 : 0
                onPicked: i => Config.set("sidebarSide", i === 1 ? "right" : "left")
            }
        }
        SettingRow {
            label: Lang.t("Dar görünüm")
            Toggle { checked: Config.sidebarCompact; onToggled: Config.set("sidebarCompact", !Config.sidebarCompact) }
        }
        SettingRow {
            label: Lang.t("Saatte saniyeler")
            Toggle { checked: Config.showSeconds; onToggled: Config.set("showSeconds", !Config.showSeconds) }
        }
        SettingRow {
            label: Lang.t("Çalan medya")
            Toggle { checked: Config.showMedia; onToggled: Config.set("showMedia", !Config.showMedia) }
        }
    }

    Group {
        title: Lang.t("Pencereler")
        SettingRow {
            label: Lang.t("Köşeler")
            sub: NiriConf.radius + " px"
            VSlider { implicitWidth: 260; from: 0; to: 24; stepSize: 1; value: NiriConf.radius; onMoved: v => NiriConf.set("radius", v) }
        }
        SettingRow {
            label: Lang.t("Aralık")
            sub: NiriConf.gaps + " px"
            VSlider { implicitWidth: 260; from: 0; to: 32; stepSize: 2; value: NiriConf.gaps; onMoved: v => NiriConf.set("gaps", v) }
        }
        SettingRow {
            label: Lang.t("Animasyonlar")
            Toggle { checked: NiriConf.animations; onToggled: NiriConf.set("animations", !NiriConf.animations) }
        }
    }

    NiriStatus { Layout.fillWidth: true }

    // Sabitlenmiş uygulamalar
    Group {
        title: Lang.t("Yan panelde sabitlenenler")
        Flow {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 8
            Repeater {
                model: Apps.pinnedEntries
                delegate: Rectangle {
                    id: pin
                    required property var modelData
                    width: Math.min(pinRow.implicitWidth + 18, parent.width)
                    height: Math.max(40, pinRow.implicitHeight + 18)
                    radius: 12
                    color: Theme.well
                    RowLayout {
                        id: pinRow
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 8
                        IconImage { Layout.alignment: Qt.AlignVCenter; implicitSize: 22; source: Quickshell.iconPath(pin.modelData.icon, "application-x-executable") }
                        Text { textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight; text: pin.modelData.name; color: Theme.paper; font.family: Theme.sans; font.pixelSize: Theme.textSmall; font.weight: Font.Medium }
                        IconButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 24; implicitHeight: 24
                            radius: 8
                            icon: "close"; iconSize: 15; iconColor: Theme.muted; tooltip: Lang.t("Kaldır")
                            onClicked: Config.set("pinned", Config.pinned.filter(id => Apps.byId(id) !== pin.modelData))
                        }
                    }
                }
            }
        }
        Flow {
            id: pinAdd
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 12
            spacing: 8
            Field { id: pinSearch; width: Math.min(260 * Config.textScale, pinAdd.width); implicitHeight: 40; placeholder: Lang.t("Eklemek için uygulama ara") }
            Repeater {
                model: pinSearch.text.length > 1 ? Apps.search(pinSearch.text).filter(e => !Apps.pinnedEntries.includes(e)).slice(0, 3) : []
                delegate: PillButton {
                    required property var modelData
                    width: Math.min(implicitWidth, pinAdd.width)
                    implicitHeight: 40
                    icon: "add"
                    label: modelData.name
                    enabled: Config.pinned.length < 12
                    onClicked: { Config.set("pinned", Config.pinned.concat([modelData.id.replace(/\.desktop$/, "")])); pinSearch.text = "" }
                }
            }
        }
    }
}
