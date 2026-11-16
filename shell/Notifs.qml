pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property bool effectiveDnd: dnd || Config.focusMode
    property bool dnd: false                      // rahatsız etme
    property var popups: []                       // ekranda gösterilenler
    readonly property var visiblePopups: popups.filter(p => p)   // kapatılıp silinmişleri atla
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
            for (const old of root.all.slice(0, Math.max(0, root.all.length - 99))) old.dismiss()
            n.tracked = true
            // Uygulama kapatınca ya da merkezden silinince nesne yok edilir; listeden de çıkar
            n.closed.connect(() => root.dismissPopup(n))
            const critical = n.urgency === NotificationUrgency.Critical
            if (root.effectiveDnd && !critical) return
            root.popups = [n].concat(root.popups).slice(0, 4)
        }
    }
}
