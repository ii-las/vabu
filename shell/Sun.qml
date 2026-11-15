pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real latitude: 41.01
    property real longitude: 28.98
    property real sunrise: 7      // yerel saat (ondalık)
    property real sunset: 17
    // 0 = doğuş, 1 = batış; dışı gece
    property real progress: 0
    readonly property bool night: progress < 0 || progress > 1

    function fmt(h) {
        const hh = Math.floor(h), mm = Math.round((h - hh) * 60)
        return String(hh % 24).padStart(2, "0") + ":" + String(mm % 60).padStart(2, "0")
    }
    readonly property string sunriseText: fmt(sunrise)
    readonly property string sunsetText: fmt(sunset)

    // NOAA gün doğumu algoritması (yaklaşık, ±2 dk)
    function solar(date, rising) {
        const rad = Math.PI / 180
        const start = new Date(date.getFullYear(), 0, 0)
        const n = Math.floor((date - start) / 86400000)
        const lngHour = longitude / 15
        const t = n + ((rising ? 6 : 18) - lngHour) / 24
        const M = 0.9856 * t - 3.289
        let L = M + 1.916 * Math.sin(M * rad) + 0.020 * Math.sin(2 * M * rad) + 282.634
        L = (L + 360) % 360
        let RA = Math.atan(0.91764 * Math.tan(L * rad)) / rad
        RA = (RA + 360) % 360
        RA = (RA + Math.floor(L / 90) * 90 - Math.floor(RA / 90) * 90) / 15
        const sinDec = 0.39782 * Math.sin(L * rad)
        const cosDec = Math.cos(Math.asin(sinDec))
        const cosH = (Math.cos(90.833 * rad) - sinDec * Math.sin(latitude * rad)) / (cosDec * Math.cos(latitude * rad))
        if (cosH > 1 || cosH < -1) return rising ? 6 : 18
        let H = rising ? 360 - Math.acos(cosH) / rad : Math.acos(cosH) / rad
        H /= 15
        const T = H + RA - 0.06571 * t - 6.622
        let ut = (T - lngHour) % 24
        if (ut < 0) ut += 24
        let local = ut - date.getTimezoneOffset() / 60
        return (local + 24) % 24
    }

    function update() {
        const now = clock.date
        sunrise = solar(now, true)
        sunset = solar(now, false)
        const h = now.getHours() + now.getMinutes() / 60
        progress = (h - sunrise) / Math.max(0.1, sunset - sunrise)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: root.update()
    }

    // ±DDMM(SS)±DDDMM(SS) biçimini ondalık dereceye çevirir
    function parseIso6709(s) {
        const m = s.match(/^([+-])(\d{2})(\d{2})(\d{2})?([+-])(\d{3})(\d{2})(\d{2})?$/)
        if (!m) return null
        const lat = (m[1] === "-" ? -1 : 1) * (+m[2] + m[3] / 60 + (m[4] ? m[4] / 3600 : 0))
        const lon = (m[5] === "-" ? -1 : 1) * (+m[6] + m[7] / 60 + (m[8] ? m[8] / 3600 : 0))
        return { lat, lon }
    }

    Process {
        id: tz
        running: !Config.location
        command: ["sh", "-c",
            "z=$(timedatectl show -p Timezone --value 2>/dev/null); " +
            "awk -v z=\"$z\" -F'\\t' '$3==z {print $2; exit}' /usr/share/zoneinfo/zone1970.tab"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = root.parseIso6709(text.trim())
                if (p) { root.latitude = p.lat; root.longitude = p.lon }
                root.update()
            }
        }
    }

    Connections {
        target: Config
        function onLocationChanged() {
            if (Config.location) {
                root.latitude = Config.location.lat
                root.longitude = Config.location.lon
                root.update()
            }
        }
    }

    Component.onCompleted: update()
}
