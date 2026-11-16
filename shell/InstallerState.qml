pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Vabu kurulumunun durumu: seçimler, metinler ve kurulum arka ucuyla konuşma.
// Arka uç: /usr/libexec/vabu/install-system (VABU_INSTALL_BACKEND ile değişir).
//   --disks         diskleri JSON olarak verir (kullanıcı olarak)
//   (seçeneksiz)    sudo -n ile çalışır, ayarları stdin'den tek JSON olarak okur,
//                   STEP / PROGRESS / ERROR / DONE satırları yazar
Singleton {
    id: root

    readonly property string backend: Quickshell.env("VABU_INSTALL_BACKEND") || "/usr/libexec/vabu/install-system"
    readonly property bool dryRun: Quickshell.env("VABU_INSTALL_DRYRUN") === "1"

    // Dil: canlı sistemde yalnızca Türkçe ve İngilizce dil paketleri var
    property string lang: "tr"
    readonly property var s: lang === "en" ? textEn : textTr

    readonly property var textTr: ({
        brand: "Vabu kurulumu",
        welcome: "Vabu'ya hoş geldin",
        language: "Dil",
        tryLive: "Kurmadan dene",
        install: "Vabu'yu kur",
        next: "Devam et",
        back: "Geri",
        region: "Bölge ve klavye",
        timezone: "Saat dilimi",
        keyboard: "Klavye düzeni",
        tryKeyboard: "Klavyeyi dene",
        search: "Ara",
        noResults: "Sonuç yok",
        disks: "Nereye kurulsun?",
        eraseNote: "Seçtiğin diskteki her şey silinir.",
        scanning: "Diskler aranıyor",
        noDisks: "Kurulabilecek disk bulunamadı",
        rescan: "Yeniden tara",
        tooSmall: "çok küçük",
        sdCard: "SD kart",
        encrypt: "Diski şifrele",
        diskPass: "Disk şifresi",
        repeat: "Şifre tekrar",
        mismatch: "Şifreler aynı değil",
        account: "Hesabını oluştur",
        fullName: "Adın",
        login: "Kullanıcı adı",
        hostname: "Bilgisayar adı",
        password: "Şifre",
        autologin: "Otomatik giriş",
        loginStart: "Harfle başlamalı",
        loginTaken: "Bu ad kullanılamaz",
        hostInvalid: "Geçersiz bilgisayar adı",
        summary: "Özet",
        sumRegion: "Dil ve bölge",
        sumDisk: "Disk",
        sumAccount: "Hesap",
        sumSources: "Uygulama kaynakları",
        keyboardWord: "klavye",
        wholeDisk: "tüm disk silinecek",
        encrypted: "şifreli",
        plain: "şifresiz",
        admin: "yönetici",
        autologinShort: "otomatik giriş",
        installButton: "Kur",
        confirmTitle: "Disk silinsin mi?",
        confirmText: d => d + " üzerindeki her şey silinecek. Bu geri alınamaz.",
        cancel: "Vazgeç",
        erase: "Sil ve kur",
        installing: "Vabu kuruluyor",
        steps: {
            disk: "Disk hazırlanıyor",
            copy: "Sistem kopyalanıyor",
            system: "Sistem ayarlanıyor",
            boot: "Önyükleyici kuruluyor",
            finish: "Son dokunuşlar"
        },
        percent: n => "%" + n,
        failed: "Kurulum tamamlanamadı",
        failedCode: c => "Kurulum beklenmedik biçimde durdu (çıkış kodu " + c + ").",
        noStart: "Kurulum başlatılamadı.",
        goBack: "Geri dön",
        retry: "Yeniden dene",
        done: "Vabu kuruldu",
        close: "Kapat",
        restart: "Yeniden başlat",
        regions: {
            Europe: "Avrupa", Asia: "Asya", Africa: "Afrika", America: "Amerika",
            Antarctica: "Antarktika", Arctic: "Arktik", Atlantic: "Atlas Okyanusu",
            Australia: "Avustralya", Indian: "Hint Okyanusu", Pacific: "Pasifik"
        }
    })

    readonly property var textEn: ({
        brand: "Vabu setup",
        welcome: "Welcome to Vabu",
        language: "Language",
        tryLive: "Try without installing",
        install: "Install Vabu",
        next: "Continue",
        back: "Back",
        region: "Region and keyboard",
        timezone: "Time zone",
        keyboard: "Keyboard layout",
        tryKeyboard: "Try your keyboard",
        search: "Search",
        noResults: "No results",
        disks: "Where should Vabu go?",
        eraseNote: "Everything on the selected disk will be erased.",
        scanning: "Looking for disks",
        noDisks: "No disk to install on",
        rescan: "Scan again",
        tooSmall: "too small",
        sdCard: "SD card",
        encrypt: "Encrypt the disk",
        diskPass: "Disk passphrase",
        repeat: "Repeat it",
        mismatch: "They don't match",
        account: "Create your account",
        fullName: "Your name",
        login: "Username",
        hostname: "Computer name",
        password: "Password",
        autologin: "Log in automatically",
        loginStart: "Must start with a letter",
        loginTaken: "This name is reserved",
        hostInvalid: "Not a valid computer name",
        summary: "Summary",
        sumRegion: "Language and region",
        sumDisk: "Disk",
        sumAccount: "Account",
        sumSources: "Software sources",
        keyboardWord: "keyboard",
        wholeDisk: "whole disk will be erased",
        encrypted: "encrypted",
        plain: "not encrypted",
        admin: "administrator",
        autologinShort: "automatic login",
        installButton: "Install",
        confirmTitle: "Erase the disk?",
        confirmText: d => "Everything on " + d + " will be erased. This can't be undone.",
        cancel: "Cancel",
        erase: "Erase and install",
        installing: "Installing Vabu",
        steps: {
            disk: "Preparing the disk",
            copy: "Copying the system",
            system: "Setting up the system",
            boot: "Installing the boot loader",
            finish: "Finishing up"
        },
        percent: n => n + "%",
        failed: "Installation failed",
        failedCode: c => "The installer stopped unexpectedly (exit code " + c + ").",
        noStart: "The installer could not be started.",
        goBack: "Go back",
        retry: "Try again",
        done: "Vabu is installed",
        close: "Close",
        restart: "Restart",
        regions: {}
    })

    // Cam kart üzerindeki gruplar ve üst şerit
    readonly property color group: Theme.dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.7)
    readonly property color veil: Theme.dark ? Qt.rgba(10 / 255, 9 / 255, 13 / 255, 0.4) : Qt.rgba(244 / 255, 246 / 255, 250 / 255, 0.3)
    readonly property color dotOff: Theme.dark ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(22 / 255, 28 / 255, 40 / 255, 0.18)

    // Klavye: seçilen düzen canlı oturuma da hemen uygulanır, sonradan yazılan şifreler tutsun
    readonly property var keyboards: [
        { layout: "tr", variant: "", tr: "Türkçe Q", en: "Turkish Q" },
        { layout: "tr", variant: "f", tr: "Türkçe F", en: "Turkish F" },
        { layout: "us", variant: "", tr: "İngilizce", en: "English (US)" }
    ]
    property int keyboard: 0
    property bool keyboardChosen: false
    onLangChanged: if (!keyboardChosen) keyboard = lang === "en" ? 2 : 0

    function chooseKeyboard(i) {
        keyboard = i
        keyboardChosen = true
        applyKeyboard()
    }
    function applyKeyboard() {
        const k = keyboards[keyboard]
        if (NiriConf.xkbLayout === k.layout && NiriConf.xkbVariant === k.variant) return
        NiriConf.setMany({ xkbLayout: k.layout, xkbVariant: k.variant })
    }

    // Saat dilimi
    property string timezone: "Europe/Istanbul"
    property bool zoneChosen: false
    property string zoneTab: ""
    property string countryTab: ""
    readonly property var fallbackZones: ["Europe/Istanbul", "Europe/London", "Europe/Berlin", "America/New_York", "Asia/Tokyo"]
    readonly property var citiesTr: ({
        Istanbul: "İstanbul", Moscow: "Moskova", London: "Londra", Athens: "Atina", Vienna: "Viyana",
        Brussels: "Brüksel", Rome: "Roma", Warsaw: "Varşova", Prague: "Prag", Bucharest: "Bükreş",
        Sofia: "Sofya", Belgrade: "Belgrad", Lisbon: "Lizbon", Copenhagen: "Kopenhag", Kyiv: "Kiev",
        Kiev: "Kiev", Baku: "Bakü", Tbilisi: "Tiflis", Nicosia: "Lefkoşa", Famagusta: "Gazimağusa",
        Tehran: "Tahran", Baghdad: "Bağdat", Damascus: "Şam", Riyadh: "Riyad", Cairo: "Kahire",
        Jerusalem: "Kudüs", Beirut: "Beyrut", Shanghai: "Şanghay", Tashkent: "Taşkent", Bishkek: "Bişkek",
        Ashgabat: "Aşkabat", Dushanbe: "Duşanbe", Yerevan: "Erivan", Chisinau: "Kişinev", Zurich: "Zürih",
        Budapest: "Budapeşte", Tirane: "Tiran", Skopje: "Üsküp", Sarajevo: "Saraybosna",
        Luxembourg: "Lüksemburg", Kabul: "Kabil", Karachi: "Karaçi", Kolkata: "Kalküta", Dhaka: "Dakka",
        Singapore: "Singapur", Seoul: "Seul", Mexico_City: "Meksiko", Algiers: "Cezayir", Tunis: "Tunus",
        Tripoli: "Trablus", Casablanca: "Kazablanka", Qatar: "Katar", Kuwait: "Kuveyt", Bahrain: "Bahreyn",
        Muscat: "Maskat", Amman: "Amman"
    })

    // Aramada ve adlarda büyük/küçük harf ve Türkçe harfler fark etmesin
    function translit(t) {
        const map = { "ı": "i", "ş": "s", "ğ": "g", "ü": "u", "ö": "o", "ç": "c", "â": "a", "î": "i", "û": "u" }
        let r = String(t).replace(/[İI]/g, "i").toLowerCase().replace(/[ışğüöçâîû]/g, c => map[c])
        if (r.normalize) r = r.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        return r
    }
    function norm(t) { return translit(t).replace(/_/g, " ") }
    function zoneEntry(id, country) {
        const parts = id.split("/")
        const last = parts[parts.length - 1]
        const cityRaw = last.replace(/_/g, " ")
        const city = lang === "tr" ? (citiesTr[last] ?? cityRaw) : cityRaw
        let region = parts.length > 1 ? (s.regions[parts[0]] ?? parts[0]) : ""
        if (parts.length > 2) region += " / " + parts[1].replace(/_/g, " ")
        return { id, city, region, key: norm([city, cityRaw, region, parts[0], country, id].join(" ")), sort: norm(city) }
    }
    readonly property var zones: {
        const countries = {}
        for (const l of countryTab.split("\n")) {
            if (!l || l[0] === "#") continue
            const p = l.split("\t")
            countries[p[0]] = p[1] || ""
        }
        const out = [], seen = {}
        for (const l of zoneTab.split("\n")) {
            if (!l || l[0] === "#") continue
            const p = l.split("\t")
            const id = p[2]
            if (!id || seen[id] || id.indexOf("/") < 0) continue
            seen[id] = true
            out.push(zoneEntry(id, countries[p[0]] ?? ""))
        }
        if (!out.length) for (const id of fallbackZones) out.push(zoneEntry(id, ""))
        out.push(zoneEntry("UTC", ""))
        out.sort((a, b) => a.sort < b.sort ? -1 : a.sort > b.sort ? 1 : 0)
        return out
    }
    function findZones(query) {
        const q = norm(query.trim())
        if (!q) return zones
        const hits = zones.filter(z => z.key.indexOf(q) >= 0)
        // Adı aranan sözle başlayanlar öne
        return hits.filter(z => z.sort.indexOf(q) === 0).concat(hits.filter(z => z.sort.indexOf(q) !== 0))
    }
    function zoneLabel(id) {
        const z = zones.find(e => e.id === id) ?? zoneEntry(id, "")
        return z.region ? z.region + " / " + z.city : z.city
    }
    function chooseZone(id) {
        timezone = id
        zoneChosen = true
    }

    FileView {
        path: "/usr/share/zoneinfo/zone.tab"
        printErrors: false
        onLoaded: root.zoneTab = text()
    }
    FileView {
        path: "/usr/share/zoneinfo/iso3166.tab"
        printErrors: false
        onLoaded: root.countryTab = text()
    }
    // Canlı sistemin saat dilimi; yoksa ya da UTC ise İstanbul kalır
    Process {
        running: true
        command: ["readlink", "/etc/localtime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/zoneinfo\/(.+)$/)
                if (m && !/^(Etc\/)?UTC$/.test(m[1]) && !root.zoneChosen) root.timezone = m[1]
            }
        }
    }

    // Diskler
    property var disks: []
    property string disksState: "idle"          // idle | loading | ready | error
    property bool diskExited: false
    property string disk: ""
    readonly property var diskInfo: disks.find(d => d.path === disk) ?? null
    property bool encrypt: false
    property string passphrase: ""
    property string passphrase2: ""
    readonly property string passphraseError: passphrase2 !== "" && passphrase !== passphrase2 ? s.mismatch : ""
    readonly property bool diskOk: diskInfo !== null && !diskInfo.tooSmall
        && (!encrypt || (passphrase !== "" && passphrase === passphrase2))

    function scanDisks() {
        if (diskProc.running) return
        disksState = "loading"
        diskExited = false
        diskProc.running = true
    }
    function sizeText(bytes) {
        const tb = bytes >= 1e12
        const v = bytes / (tb ? 1e12 : 1e9)
        let t = v >= 10 ? String(Math.round(v)) : v.toFixed(1).replace(/\.0$/, "")
        if (lang === "tr") t = t.replace(".", ",")
        return t + (tb ? " TB" : " GB")
    }
    function diskName(d) { return d.model || d.path }
    function diskSub(d) {
        const names = { nvme: "NVMe", sata: "SATA", ata: "SATA", usb: "USB", virtio: "VirtIO", scsi: "SCSI", mmc: s.sdCard }
        const parts = d.model ? [sizeText(d.size), d.path] : [sizeText(d.size)]
        if (d.transport) parts.push(names[d.transport] ?? d.transport.toUpperCase())
        if (d.tooSmall) parts.push(s.tooSmall)
        return parts.join(" · ")
    }

    Process {
        id: diskProc
        command: [root.backend, "--disks"]
        stdout: StdioCollector { id: diskOut }
        onExited: code => {
            root.diskExited = true
            let list = null
            try { list = JSON.parse(diskOut.text) } catch (e) {}
            if (code !== 0 || !Array.isArray(list)) {
                root.disks = []
                root.disksState = "error"
                return
            }
            root.disks = list
            root.disksState = "ready"
            const usable = list.filter(d => !d.tooSmall)
            if (!usable.some(d => d.path === root.disk)) root.disk = usable.length === 1 ? usable[0].path : ""
        }
        onRunningChanged: if (!diskProc.running && !root.diskExited) root.disksState = "error"
    }

    // Hesap
    property string fullName: ""
    property string login: ""
    property string hostname: ""
    property string password: ""
    property string password2: ""
    property bool autologin: false
    property bool loginEdited: false
    property bool hostEdited: false
    readonly property var reserved: ["root", "bin", "daemon", "adm", "lp", "sync", "shutdown", "halt", "mail",
        "operator", "games", "ftp", "nobody", "liveuser", "dbus", "polkitd", "tss", "sshd", "chrony", "avahi",
        "geoclue", "pipewire", "rtkit", "greeter", "flatpak", "colord", "saned", "unbound", "dnsmasq", "usbmuxd"]

    function cleanLogin(t) { return translit(t).replace(/[^a-z0-9_-]/g, "").slice(0, 32) }
    function cleanHost(t) { return translit(t).replace(/[^a-z0-9-]/g, "").slice(0, 63) }
    function suggestLogin(name) { return cleanLogin(translit(name).trim().split(/\s+/)[0] ?? "") }
    function suggestHost(l) { return l ? cleanHost(l + "-vabu") : "" }

    readonly property string loginError: login === "" ? ""
        : !/^[a-z_]/.test(login) ? s.loginStart
        : reserved.indexOf(login) >= 0 || /^systemd-/.test(login) ? s.loginTaken : ""
    readonly property string hostError: hostname === "" || /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/.test(hostname) ? "" : s.hostInvalid
    readonly property string passwordError: password2 !== "" && password !== password2 ? s.mismatch : ""
    readonly property bool accountOk: login !== "" && loginError === "" && hostname !== "" && hostError === ""
        && password !== "" && password === password2

    signal secretsCleared()
    function clearSecrets() {
        password = ""
        password2 = ""
        passphrase = ""
        passphrase2 = ""
        secretsCleared()
    }

    readonly property var summaryRows: {
        const k = keyboards[keyboard]
        const d = diskInfo
        const who = fullName.trim() ? [fullName.trim()] : []
        return [
            { icon: "language", label: s.sumRegion,
              sub: [lang === "en" ? "English" : "Türkçe", zoneLabel(timezone), (lang === "en" ? k.en : k.tr) + " " + s.keyboardWord].join(" · ") },
            { icon: "hard_drive", label: s.sumDisk,
              sub: d ? diskName(d) + " (" + sizeText(d.size) + "): " + s.wholeDisk + ", " + (encrypt ? s.encrypted : s.plain) : "" },
            { icon: "person", label: s.sumAccount,
              sub: who.concat([login, s.admin]).concat(autologin ? [s.autologinShort] : []).join(" · ") },
            { icon: "apps", label: s.sumSources, sub: "Fedora, RPM Fusion, Flathub" }
        ]
    }

    // Kurulum
    property string runState: "idle"            // idle | running | error | done
    readonly property var stepKeys: ["disk", "copy", "system", "boot", "finish"]
    property string step: ""
    property string stepMessage: ""
    readonly property int stepIndex: Math.max(0, stepKeys.indexOf(step))
    readonly property string stepLabel: s.steps[step] ?? (stepMessage || s.steps.disk)
    property int progress: 0
    property string runError: ""
    property var tail: []
    property bool doneSeen: false
    property bool runExited: false
    property string pending: ""

    function install() {
        if (installProc.running) return
        const k = keyboards[keyboard]
        pending = JSON.stringify({
            disk: disk,
            encrypt: encrypt,
            passphrase: encrypt ? passphrase : "",
            fullName: fullName.trim(),
            login: login,
            password: password,
            hostname: hostname,
            autologin: autologin,
            locale: lang === "en" ? "en_US.UTF-8" : "tr_TR.UTF-8",
            keymap: k.layout,
            keymapVariant: k.variant,
            timezone: timezone
        })
        step = ""
        stepMessage = ""
        progress = 0
        runError = ""
        tail = []
        doneSeen = false
        runExited = false
        runState = "running"
        installProc.command = ["sudo", "-n", backend].concat(dryRun ? ["--dry-run"] : [])
        installProc.stdinEnabled = true
        installProc.running = true
    }
    function reboot() {
        if (dryRun) Qt.quit()
        else Quickshell.execDetached(["systemctl", "reboot"])
    }
    function readLine(line) {
        const sp = line.indexOf(" ")
        const word = sp < 0 ? line.trim() : line.slice(0, sp)
        const rest = sp < 0 ? "" : line.slice(sp + 1).trim()
        if (word === "STEP") {
            const key = rest.split(" ")[0]
            step = key
            stepMessage = rest.slice(key.length).trim()
        } else if (word === "PROGRESS") {
            const n = parseInt(rest)
            if (!isNaN(n)) progress = Math.max(0, Math.min(100, n))
        } else if (word === "ERROR") {
            if (rest) runError = rest
        } else if (word === "DONE") {
            doneSeen = true
        }
    }

    Process {
        id: installProc
        stdout: SplitParser { onRead: line => root.readLine(line) }
        stderr: SplitParser {
            onRead: line => {
                if (!line.trim()) return
                root.tail = root.tail.concat([line.trim()]).slice(-4)
            }
        }
        // Ayarlar yalnızca stdin'den gider: komut satırında ya da dosyada şifre olmaz
        onStarted: {
            installProc.write(root.pending + "\n")
            root.pending = ""
            installProc.stdinEnabled = false
        }
        onExited: code => {
            root.runExited = true
            if (code === 0 && root.doneSeen) {
                root.progress = 100
                root.runState = "done"
                root.clearSecrets()
                return
            }
            if (!root.runError) root.runError = root.tail.length ? root.tail.join("\n") : root.s.failedCode(code)
            root.runState = "error"
        }
        onRunningChanged: {
            if (installProc.running || root.runExited || root.runState !== "running") return
            root.pending = ""
            root.runError = root.s.noStart
            root.runState = "error"
        }
    }
}
