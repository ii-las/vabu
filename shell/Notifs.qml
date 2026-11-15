pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false                      // rahatsız etme
    property var popups: []                       // ekranda gösterilenler
    readonly property var all: server.trackedNotifications.values
    readonly property int count: all.length

    function dismissPopup(n) {
        popups = popups.filter(p => p !== n)
    }
    function clearAll() {
        for (const n of all.slice()) n.dismiss()
        popups = []
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: false
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            const critical = n.urgency === NotificationUrgency.Critical
            if (root.dnd && !critical) return
            root.popups = [n].concat(root.popups).slice(0, 4)
        }
    }
}
