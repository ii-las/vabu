import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

ColumnLayout {
    id: page
    spacing: 22

    property string gtkScheme: "prefer-dark"
    Process {
        running: true
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        stdout: StdioCollector { onStreamFinished: page.gtkScheme = text.trim().replace(/'/g, "") }
    }
    function setScheme(dark) {
        gtkScheme = dark ? "prefer-dark" : "default"
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", gtkScheme])
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", dark ? "adw-gtk3-dark" : "adw-gtk3"])
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", dark ? "Papirus-Dark" : "Papirus"])
    }

    // Duvar kağıdı
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10
        SectionLabel { text: "Duvar kağıdı" }
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 12
            Repeater {
                model: Config.wallpapers.concat([{ name: "Kendi resmin", path: "" }])
                delegate: ColumnLayout {
                    id: wp
                    required property var modelData
                    readonly property bool custom: modelData.path === ""
                    readonly property bool on: custom ? !Config.wallpapers.some(w => w.path === Config.wallpaper) : Config.wallpaper === modelData.path
                    Layout.fillWidth: true
                    spacing: 8
                    ClippingRectangle {
                        Layout.fillWidth: true
                        implicitHeight: 116
                        radius: 16
                        color: wp.custom ? "transparent" : Theme.stone
                        border.width: wp.on ? 3 : (wp.custom ? 1 : 0)
                        border.color: wp.on ? Theme.accent : Qt.rgba(1, 1, 1, 0.3)
                        Image {
                            anchors.fill: parent
                            visible: !wp.custom || wp.on
                            source: wp.custom ? (wp.on ? "file://" + Config.wallpaper : "") : wp.modelData.path
                            sourceSize: Qt.size(400, 240)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Icon { visible: wp.custom && !wp.on; anchors.centerIn: parent; name: "plus"; color: Theme.muted; size: 22 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wp.custom ? picker.open() : Config.set("wallpaper", wp.modelData.path)
                        }
                    }
                    Text { text: wp.modelData.name; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 13 }
                }
            }
        }
    }

    FileDialog {
        id: picker
        title: "Duvar kağıdı seç"
        nameFilters: ["Resimler (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: Config.set("wallpaper", String(selectedFile).replace(/^file:\/\//, ""))
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        DashLine { Layout.fillWidth: true }

        SettingRow {
            label: "Vurgu rengi"
            sub: "Seçim, odak halkası ve düğmeler"
            Repeater {
                model: Object.keys(Config.accents)
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: Config.accentName === modelData
                    width: 34; height: 34; radius: 17
                    color: Config.accents[modelData].color
                    border.width: on ? 3 : 0
                    border.color: "#16161B"
                    Rectangle {
                        visible: parent.on
                        anchors.centerIn: parent
                        width: 42; height: 42; radius: 21
                        color: "transparent"
                        border.width: 2
                        border.color: parent.color
                    }
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: Config.accents[modelData].name
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Config.set("accent", parent.modelData); NiriConf.apply(false) }
                    }
                }
            }
        }
        SettingRow {
            label: "Uygulama teması"
            sub: "GTK ve Qt uygulamalarının rengi. Vabu kabuğu her zaman koyudur."
            Segmented {
                options: ["Koyu", "Açık"]
                currentIndex: page.gtkScheme === "prefer-dark" ? 0 : 1
                onPicked: i => page.setScheme(i === 0)
            }
        }
        SettingRow {
            label: "Yan çubuk konumu"
            sub: "Pencere kolonları diğer taraftan akar"
            Segmented {
                options: ["Sol", "Sağ"]
                currentIndex: Config.sidebarSide === "right" ? 1 : 0
                onPicked: i => Config.set("sidebarSide", i === 1 ? "right" : "left")
            }
        }
        SettingRow {
            label: "Saatte saniyeler"
            Toggle { checked: Config.showSeconds; onToggled: Config.set("showSeconds", !Config.showSeconds) }
        }
        SettingRow {
            label: "Yan çubukta çalan medya"
            Toggle { checked: Config.showMedia; onToggled: Config.set("showMedia", !Config.showMedia) }
        }
        SettingRow {
            label: "Pencere köşeleri"
            sub: "Yuvarlaklık · " + NiriConf.radius + " px"
            VSlider { from: 0; to: 24; stepSize: 1; value: NiriConf.radius; onMoved: v => NiriConf.set("radius", v) }
        }
        SettingRow {
            label: "Pencere aralıkları"
            sub: "Kolonlar arası boşluk · " + NiriConf.gaps + " px"
            VSlider { from: 0; to: 32; stepSize: 2; value: NiriConf.gaps; onMoved: v => NiriConf.set("gaps", v) }
        }
        SettingRow {
            label: "Animasyonlar"
            Toggle { checked: NiriConf.animations; onToggled: NiriConf.set("animations", !NiriConf.animations) }
        }
    }

    NiriStatus { Layout.fillWidth: true }

    // Sabitlenmiş uygulamalar
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10
        SectionLabel { text: "Yan panelde sabitlenenler (en fazla 6)" }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: Apps.pinnedEntries
                delegate: Rectangle {
                    required property var modelData
                    width: pinRow.implicitWidth + 20
                    height: 44
                    radius: 14
                    color: Theme.stone
                    Row {
                        id: pinRow
                        anchors.centerIn: parent
                        spacing: 8
                        IconImage { anchors.verticalCenter: parent.verticalCenter; implicitSize: 22; source: Quickshell.iconPath(modelData.icon, "application-x-executable") }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 13 }
                        IconButton {
                            implicitWidth: 26; implicitHeight: 26
                            icon: "close"; iconSize: 12; tooltip: "Kaldır"
                            onClicked: Config.set("pinned", Config.pinned.filter(id => Apps.byId(id) !== modelData))
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Field { id: pinSearch; Layout.preferredWidth: 300; placeholder: "Sabitlemek için uygulama ara" }
            Repeater {
                model: pinSearch.text.length > 1 ? Apps.search(pinSearch.text).filter(e => !Apps.pinnedEntries.includes(e)).slice(0, 3) : []
                delegate: PillButton {
                    required property var modelData
                    implicitHeight: 40
                    icon: "plus"
                    label: modelData.name
                    enabled: Config.pinned.length < 6
                    onClicked: { Config.set("pinned", Config.pinned.concat([modelData.id.replace(/\.desktop$/, "")])); pinSearch.text = "" }
                }
            }
        }
    }
}
