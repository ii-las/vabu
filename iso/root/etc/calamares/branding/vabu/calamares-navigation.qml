// Persistent navigation; each control has a real Qt button and a visible focus ring.
import io.calamares.ui 1.0
import io.calamares.core 1.0
import QtQuick 2.15

Rectangle {
    id: root
    color: "#F4F3EF"
    implicitHeight: 64
    height: implicitHeight
    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#D8DAD3" }
    Row {
        anchors.centerIn: parent
        spacing: 12
        // The first and last pages provide their own primary action.
        visible: ViewManager.backAndNextVisible && ViewManager.currentStepIndex > 0
                 && (ViewManager.nextEnabled || ViewManager.backEnabled)
        VabuButton {
            visible: ViewManager.backEnabled
            text: ViewManager.backLabel.replace("&", "")
            onClicked: ViewManager.back()
        }
        VabuButton {
            implicitWidth: Math.max(160, implicitContentWidth + 40)
            primary: true
            enabled: ViewManager.nextEnabled
            text: ViewManager.nextLabel.replace("&", "")
            onClicked: ViewManager.next()
        }
    }
    VabuButton {
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        visible: ViewManager.quitVisible
        enabled: ViewManager.quitEnabled
        text: ViewManager.quitLabel.replace("&", "")
        onClicked: ViewManager.quit()
    }
}
