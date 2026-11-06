pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Notifications

Singleton {
    id: root

    // =========================================================================
    // 1. GERENCIAMENTO DE GAVETAS (DRAWERS) E POSIÇÃO DO BOTÃO DE ORIGEM
    // =========================================================================
    property string activePopup: "" // "", "media", "bluetooth", "audio", "hardware", "notifications", "calendar", "spotlight"
    property string activeToolPopup: "" // "", "clipboard", "screenshot", "keybindings", "rbw", "sidepad"
    property real drawerCenterX: 960
    property real drawerButtonWidth: 120
    property bool trayExpanded: false
    property bool mediaExpanded: false

    function toggleMediaExpanded() {
        root.activeToolPopup = "";
        if (root.activePopup === "media" && root.mediaExpanded) {
            root.activePopup = "";
        } else {
            root.mediaExpanded = true;
            root.activePopup = "media";
        }
    }

    onActivePopupChanged: {
        if (root.activePopup === "audio") {
            if (!audioPoll.running) audioPoll.running = true;
        } else if (root.activePopup === "hardware" || root.activePopup === "battery" || root.activePopup === "notifications") {
            if (!drawerSysPoll.running) drawerSysPoll.running = true;
        } else if (root.activePopup === "media") {
            if (!mediaPosPoll.running) mediaPosPoll.running = true;
        }
    }

    function toggleDrawer(name, buttonItem) {
        root.activeToolPopup = "";
        if (buttonItem) {
            const mapped = buttonItem.mapToItem(null, 0, 0);
            root.drawerCenterX = mapped.x + (buttonItem.width / 2) + Config.marginHorizontal;
            root.drawerButtonWidth = Math.max(40, buttonItem.width);
        }
        if (root.activePopup === name) {
            root.activePopup = "";
        } else {
            root.activePopup = name;
        }
    }

    function togglePopup(name) {
        root.activeToolPopup = "";
        if (root.activePopup === name) {
            root.activePopup = "";
        } else {
            root.activePopup = name;
        }
    }

    function toggleToolPopup(name) {
        root.activePopup = "";
        if (root.activeToolPopup === name) {
            root.activeToolPopup = "";
        } else {
            root.activeToolPopup = name;
        }
    }

    function closePopups() {
        root.activePopup = "";
        root.activeToolPopup = "";
    }

    // =========================================================================
    // 2. SERVIDOR DE NOTIFICAÇÕES 100% NATIVO DO QUICKSHELL
    // =========================================================================
    property bool dndEnabled: false
    property var latestToast: null

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (notif) => {
            notif.tracked = true;
            if (!root.dndEnabled) {
                root.latestToast = notif;
                toastTimer.restart();
            }
        }
    }

    Timer {
        id: toastTimer
        interval: 4800
        repeat: false
        onTriggered: {
            root.latestToast = null;
        }
    }

    readonly property var notificationsList: notifServer.trackedNotifications.values
    readonly property int notifCount: notificationsList ? notificationsList.length : 0

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled;
        if (root.dndEnabled) {
            root.latestToast = null;
            toastTimer.stop();
        }
    }

    function dismissToast() {
        root.latestToast = null;
        toastTimer.stop();
    }

    function dismissNotification(notif) {
        if (!notif) return;
        if (root.latestToast === notif) {
            root.latestToast = null;
            toastTimer.stop();
        }
        notif.dismiss();
    }

    function activateNotification(notif) {
        if (!notif) return;

        const rawEntry = (notif.desktopEntry || "").trim();
        const rawApp = (notif.appName || "").trim();
        const rawIcon = (notif.appIcon || "").trim();

        // 1. Dispara a ação padrão ("default") via DBus para o app abrir a conversa/aba específica (ex: Telegram, Discord, Zen)
        if (notif.actions && notif.actions.length > 0) {
            let triggered = false;
            for (let i = 0; i < notif.actions.length; i++) {
                const act = notif.actions[i];
                if (act && (act.identifier === "default" || act.identifier === "activate" || act.identifier === "open")) {
                    act.invoke();
                    triggered = true;
                    break;
                }
            }
            if (!triggered && notif.actions[0]) {
                notif.actions[0].invoke();
            }
        }

        // 2. Foca a janela correspondente no Hyprland (mudando para a workspace dela),
        //    ou abre o aplicativo caso a janela esteja fechada na bandeja (ex: Telegram no tray)
        const token = (rawEntry || rawApp || rawIcon).toLowerCase()
            .replace(/\.desktop$/i, "")
            .replace(/^org\./i, "")
            .replace(/^com\./i, "")
            .replace(/\s+desktop$/i, "")
            .trim();

        if (token !== "" && token !== "notify-send" && token !== "quickshell") {
            const safeToken = token.replace(/'/g, "");
            const focusCmd = `
                TOKEN='${safeToken}'
                # Pega a primeira palavra significativa (ex: telegram.desktop -> telegram)
                SHORT=$(echo "$TOKEN" | awk -F'[. -]' '{print $1}')
                ADDR=$(hyprctl clients -j 2>/dev/null | jq -r --arg t "$TOKEN" --arg s "$SHORT" '
                    .[] | select(
                        ((.class // "") | ascii_downcase | contains($t)) or
                        ((.initialClass // "") | ascii_downcase | contains($t)) or
                        ((.title // "") | ascii_downcase | contains($t)) or
                        (($s != "" and ($s | length) >= 3) and (
                            ((.class // "") | ascii_downcase | contains($s)) or
                            ((.initialClass // "") | ascii_downcase | contains($s)) or
                            ((.title // "") | ascii_downcase | contains($s))
                        ))
                    ) | .address' | head -n1)
                if [ -n "$ADDR" ] && [ "$ADDR" != "null" ]; then
                    hyprctl dispatch focuswindow "address:$ADDR" >/dev/null 2>&1
                fi
            `;
            Quickshell.execDetached(["sh", "-c", focusCmd]);

            // Se o aplicativo (como Telegram) estava apenas no tray sem janela aberta, também tenta executar seu DesktopEntry
            const entries = DesktopEntries.applications.values;
            for (let j = 0; j < entries.length; j++) {
                const de = entries[j];
                if (!de) continue;
                const deId = (de.id || "").toLowerCase().replace(/\.desktop$/, "");
                const deName = (de.name || "").toLowerCase();
                if ((rawEntry !== "" && deId === rawEntry.toLowerCase().replace(/\.desktop$/, "")) ||
                    (token.includes("telegram") && deId.includes("telegram"))) {
                    // Só executa se o app for do tipo single-instance (como Telegram) que abre/foca a janela existente
                    if (deId.includes("telegram")) {
                        de.execute();
                    }
                    break;
                }
            }
        }

        // 3. Fecha o toast/gaveta e remove a notificação lida (se ainda estiver ativa)
        if (root.latestToast === notif) {
            root.latestToast = null;
            toastTimer.stop();
        }
        root.closePopups();
        try {
            if (notif && notif.tracked) {
                notif.dismiss();
            }
        } catch (e) {}
    }

    function clearAllNotifications() {
        root.latestToast = null;
        toastTimer.stop();
        const list = notifServer.trackedNotifications.values;
        if (!list) return;
        const copy = [];
        for (let i = 0; i < list.length; i++) {
            copy.push(list[i]);
        }
        for (let i = 0; i < copy.length; i++) {
            if (copy[i]) copy[i].dismiss();
        }
    }

    // =========================================================================
    // 3. ÁUDIO 100% INTEGRADO (Saídas, Entradas, Apps de Saída e Apps de Mic)
    // =========================================================================
    property int volume: 50
    property bool muted: false
    property int micVolume: 80
    property bool micMuted: false
    property string defaultSink: ""
    property string defaultSource: ""
    property var audioSinks: []
    property var audioSources: []
    property var audioApps: []
    property var micApps: []
    property bool isDraggingAudio: false

    readonly property string volumeIcon: {
        if (muted || volume === 0) return "󰝟";
        if (volume < 35) return "󰕿";
        if (volume < 70) return "󰖀";
        return "󰕾";
    }

    readonly property string micIcon: (micMuted || micVolume === 0) ? "󰍭" : "󰍬"

    function setVolume(val) {
        const clamped = Math.max(0, Math.min(150, Math.round(val)));
        root.volume = clamped;
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", clamped + "%"]);
    }

    function adjustVolume(delta) {
        setVolume(root.volume + delta);
    }

    function toggleMute() {
        root.muted = !root.muted;
        Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]);
        audioPoll.running = true;
    }

    function setMicVolume(val) {
        const clamped = Math.max(0, Math.min(120, Math.round(val)));
        root.micVolume = clamped;
        Quickshell.execDetached(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", clamped + "%"]);
    }

    function toggleMicMute() {
        root.micMuted = !root.micMuted;
        Quickshell.execDetached(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]);
        audioPoll.running = true;
    }

    function setSink(sinkName) {
        root.defaultSink = sinkName;
        Quickshell.execDetached(["pactl", "set-default-sink", sinkName]);
        audioPoll.running = true;
    }

    function setSinkVolume(sinkName, val) {
        const clamped = Math.max(0, Math.min(150, Math.round(val)));
        Quickshell.execDetached(["pactl", "set-sink-volume", sinkName, clamped + "%"]);
    }

    function setSource(sourceName) {
        root.defaultSource = sourceName;
        Quickshell.execDetached(["pactl", "set-default-source", sourceName]);
        audioPoll.running = true;
    }

    function setSourceVolume(sourceName, val) {
        const clamped = Math.max(0, Math.min(120, Math.round(val)));
        Quickshell.execDetached(["pactl", "set-source-volume", sourceName, clamped + "%"]);
    }

    function setAppVolume(appIndex, val) {
        const clamped = Math.max(0, Math.min(150, Math.round(val)));
        Quickshell.execDetached(["pactl", "set-sink-input-volume", String(appIndex), clamped + "%"]);
    }

    function toggleAppMute(appIndex) {
        Quickshell.execDetached(["pactl", "set-sink-input-mute", String(appIndex), "toggle"]);
        audioPoll.running = true;
    }

    function setMicAppVolume(appIndex, val) {
        const clamped = Math.max(0, Math.min(120, Math.round(val)));
        Quickshell.execDetached(["pactl", "set-source-output-volume", String(appIndex), clamped + "%"]);
    }

    function finishAudioDrag() {
        root.isDraggingAudio = false;
        if (!audioPoll.running) audioPoll.running = true;
    }

    function toggleMicAppMute(appIndex) {
        Quickshell.execDetached(["pactl", "set-source-output-mute", String(appIndex), "toggle"]);
        audioPoll.running = true;
    }

    // Leitura ultra-leve (1 único binário wpctl, zero subshells/grep!) p/ atualizar o volume da barra em ~1.5ms
    Process {
        id: quickVolPoll
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.isDraggingAudio) return;
                const txt = this.text.trim();
                // Formato: "Volume: 0.45" ou "Volume: 0.45 [MUTED]"
                if (txt.startsWith("Volume:")) {
                    const parts = txt.split(" ");
                    const v = Math.round(parseFloat(parts[1]) * 100);
                    if (!isNaN(v)) root.volume = v;
                    root.muted = txt.includes("[MUTED]");
                }
            }
        }
    }

    Timer {
        id: quickVolDebounce
        interval: 55
        repeat: false
        onTriggered: {
            if (!quickVolPoll.running && !root.isDraggingAudio) {
                quickVolPoll.running = true;
            }
        }
    }

    Timer {
        id: fullAudioDebounce
        interval: 180
        repeat: false
        onTriggered: {
            if (root.activePopup === "audio" && !audioPoll.running && !root.isDraggingAudio) {
                audioPoll.running = true;
            }
        }
    }

    // Stream em tempo real do PipeWire/PulseAudio: ignora eventos contínuos de sink-input para não gastar CPU!
    Process {
        id: audioSubscribe
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: (line) => {
                if (root.isDraggingAudio) return;
                // Atualiza a barra apenas quando o sink físico ou servidor mudar (ignora sink-input em reprodução)
                if (line.includes("on sink #") || line.includes("on server")) {
                    quickVolDebounce.restart();
                }
                // Só roda o audioPoll completo (jq) se a gaveta de áudio estiver aberta!
                if (root.activePopup === "audio" && (line.includes("sink") || line.includes("source") || line.includes("server"))) {
                    fullAudioDebounce.restart();
                }
            }
        }
        onExited: {
            audioSubRestart.restart();
        }
    }

    Timer {
        id: audioSubRestart
        interval: 1500
        repeat: false
        onTriggered: audioSubscribe.running = true
    }

    Process {
        id: audioPoll
        command: [
            "sh", "-c",
            "VOL=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -n1); " +
            "MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -oP '(yes|no)'); " +
            "MVOL=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '\\d+(?=%)' | head -n1); " +
            "MMUTE=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '(yes|no)'); " +
            "DEFSINK=$(pactl get-default-sink 2>/dev/null); " +
            "DEFSRC=$(pactl get-default-source 2>/dev/null); " +
            "echo \"HDR:${VOL:-50}|${MUTE:-no}|${MVOL:-80}|${MMUTE:-no}|${DEFSINK:-}|${DEFSRC:-}\"; " +
            "pactl -f json list sinks 2>/dev/null | jq -r '.[] | \"SINK:\\(.name)|\\(.description)|\\((.volume | to_entries[0].value.value_percent // \"100%\") | sub(\"%\";\"\"))|\\(.mute)\"' 2>/dev/null; " +
            "pactl -f json list sources 2>/dev/null | jq -r '.[] | select((.name | endswith(\".monitor\")) | not) | \"SRC:\\(.name)|\\(.description)|\\((.volume | to_entries[0].value.value_percent // \"100%\") | sub(\"%\";\"\"))|\\(.mute)\"' 2>/dev/null; " +
            "pactl -f json list sink-inputs 2>/dev/null | jq -r '.[] | \"APP:\\(.index)|\\(.properties[\"application.name\"] // .properties[\"media.name\"] // \"Aplicativo\")|\\((.volume | to_entries[0].value.value_percent // \"100%\") | sub(\"%\";\"\"))|\\(.mute)\"' 2>/dev/null; " +
            "pactl -f json list source-outputs 2>/dev/null | jq -r '.[] | \"MICAPP:\\(.index)|\\(.properties[\"application.name\"] // .properties[\"media.name\"] // \"Captura\")|\\((.volume | to_entries[0].value.value_percent // \"100%\") | sub(\"%\";\"\"))|\\(.mute)\"' 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                if (lines.length === 0) return;

                const sinks = [];
                const sources = [];
                const apps = [];
                const mApps = [];

                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim();
                    if (l.startsWith("HDR:")) {
                        const header = l.substring(4).split("|");
                        if (header.length >= 6) {
                            const v = parseInt(header[0]);
                            if (!isNaN(v)) root.volume = v;
                            root.muted = (header[1].trim() === "yes");
                            const mv = parseInt(header[2]);
                            if (!isNaN(mv)) root.micVolume = mv;
                            root.micMuted = (header[3].trim() === "yes");
                            root.defaultSink = header[4].trim();
                            root.defaultSource = header[5].trim();
                        }
                    } else if (l.startsWith("SINK:")) {
                        const sp = l.substring(5).split("|");
                        if (sp.length >= 4) {
                            sinks.push({
                                name: sp[0].trim(),
                                description: sp[1].trim(),
                                volume: parseInt(sp[2]) || 50,
                                muted: sp[3].trim() === "true",
                                isDefault: sp[0].trim() === root.defaultSink
                            });
                        }
                    } else if (l.startsWith("SRC:")) {
                        const sr = l.substring(4).split("|");
                        if (sr.length >= 4) {
                            sources.push({
                                name: sr[0].trim(),
                                description: sr[1].trim(),
                                volume: parseInt(sr[2]) || 80,
                                muted: sr[3].trim() === "true",
                                isDefault: sr[0].trim() === root.defaultSource
                            });
                        }
                    } else if (l.startsWith("APP:")) {
                        const ap = l.substring(4).split("|");
                        if (ap.length >= 4) {
                            apps.push({
                                index: parseInt(ap[0]),
                                name: ap[1].trim(),
                                volume: parseInt(ap[2]) || 100,
                                muted: ap[3].trim() === "true"
                            });
                        }
                    } else if (l.startsWith("MICAPP:")) {
                        const mp = l.substring(7).split("|");
                        if (mp.length >= 4) {
                            mApps.push({
                                index: parseInt(mp[0]),
                                name: mp[1].trim(),
                                volume: parseInt(mp[2]) || 100,
                                muted: mp[3].trim() === "true"
                            });
                        }
                    }
                }

                if (!root.isDraggingAudio) {
                    root.audioSinks = sinks;
                    root.audioSources = sources;
                    root.audioApps = apps;
                    root.micApps = mApps;
                }
            }
        }
    }

    // =========================================================================
    // 4. BLUETOOTH CENTRAL NATIVO (Quickshell.Bluetooth)
    // =========================================================================
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: btAdapter ? btAdapter.enabled : false
    readonly property var btDevices: Bluetooth.devices.values

    readonly property var connectedBtDevice: {
        const devs = btDevices;
        if (!devs) return null;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].connected) {
                return devs[i];
            }
        }
        return null;
    }

    readonly property bool btIsConnected: connectedBtDevice !== null
    readonly property string btConnectedName: connectedBtDevice ? (connectedBtDevice.name || connectedBtDevice.deviceName || "Dispositivo") : ""

    function getBtDeviceIcon(dev) {
        if (!dev) return "󰂯";
        const ic = (dev.icon || "").toLowerCase();
        const nm = (dev.name || dev.deviceName || "").toLowerCase();
        if (ic.includes("headset") || ic.includes("headphones") || nm.includes("buds") || nm.includes("airpods") || nm.includes("headphone")) return "󰋋";
        if (ic.includes("audio-card") || ic.includes("speaker") || nm.includes("jbl") || nm.includes("echo") || nm.includes("flip")) return "󰓃";
        if (ic.includes("gaming") || ic.includes("joystick") || nm.includes("controller") || nm.includes("xbox") || nm.includes("dualshock")) return "󰊗";
        if (ic.includes("mouse")) return "󰍽";
        if (ic.includes("keyboard")) return "󰌌";
        if (ic.includes("phone")) return "󰄜";
        return "󰂱";
    }

    readonly property string btConnectedTypeIcon: getBtDeviceIcon(connectedBtDevice)

    function toggleBluetoothPower() {
        if (btAdapter) {
            btAdapter.enabled = !btAdapter.enabled;
        } else {
            Quickshell.execDetached(["bluetoothctl", "power", btEnabled ? "off" : "on"]);
        }
    }

    function toggleBtDeviceConnection(dev) {
        if (!dev) return;
        if (dev.connected) {
            dev.disconnect();
        } else {
            dev.connect();
        }
    }

    // =========================================================================
    // 5. HARDWARE / CONSUMO REAL (/proc/stat, /proc/meminfo e /home)
    // =========================================================================
    property int cpuUsage: 0
    property int ramUsage: 0
    property string ramUsedText: "0.0 / 0.0 GB"
    property int diskUsage: 0
    property string diskUsedText: "0 / 0 GB"
    property int cpuTemp: 45
    property string powerProfile: "balanced"
    property bool nightLightEnabled: false
    property int nightLightStrength: 0
    property int brightness: 100
    property bool hasBacklight: true

    readonly property string powerProfileIcon: {
        if (powerProfile === "performance") return "󰓅";
        if (powerProfile === "power-saver") return "󰌪";
        return "󰾅";
    }

    function setPowerProfile(prof) {
        root.powerProfile = prof;
        Quickshell.execDetached(["powerprofilesctl", "set", prof]);
    }

    function cyclePowerProfile() {
        if (powerProfile === "balanced") setPowerProfile("performance");
        else if (powerProfile === "performance") setPowerProfile("power-saver");
        else setPowerProfile("balanced");
    }

    function setBrightness(val) {
        const clamped = Math.max(5, Math.min(100, Math.round(val)));
        root.brightness = clamped;
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"]);
    }

    property bool nlFlip: false

    Timer {
        id: nlApplyTimer
        interval: 45
        repeat: false
        onTriggered: {
            if (root.nightLightStrength <= 2) {
                Quickshell.execDetached(["hyprctl", "eval", 'hl.config({ decoration = { screen_shader = "" } })']);
            } else {
                root.nlFlip = !root.nlFlip;
                const slot = root.nlFlip ? "/tmp/qs_nl_a.glsl" : "/tmp/qs_nl_b.glsl";
                const strength = (root.nightLightStrength / 100.0).toFixed(2);
                const cmd = `sed "s/const float temperatureStrength = 1.0;/const float temperatureStrength = ${strength};/" /usr/share/hyprshade/shaders/blue-light-filter.glsl > ${slot} && hyprctl eval 'hl.config({ decoration = { screen_shader = "${slot}" } })'`;
                Quickshell.execDetached(["sh", "-c", cmd]);
            }
        }
    }

    function setNightLightStrength(val) {
        const clamped = Math.max(0, Math.min(100, Math.round(val)));
        root.nightLightStrength = clamped;
        root.nightLightEnabled = clamped > 2;
        nlApplyTimer.restart();
    }

    function toggleNightLight() {
        if (root.nightLightEnabled) {
            setNightLightStrength(0);
        } else {
            setNightLightStrength(65);
        }
    }

    property real prevCpuAct: 0
    property real prevCpuTot: 0

    // Leitura ultra-leve em 1 único processo awk (sem bash, sem sleep, sem jq, sem subshells!)
    Process {
        id: sysPoll
        command: [
            "awk",
            `FILENAME == "/proc/stat" && $1 == "cpu" { act = $2+$3+$4+$7+$8; tot = act+$5+$6 }
             FILENAME == "/proc/meminfo" && $1 == "MemTotal:" { mt = $2 }
             FILENAME == "/proc/meminfo" && $1 == "MemAvailable:" { ma = $2 }
             FILENAME ~ /temp$/ { temp = int($1 / 1000) }
             FILENAME ~ /capacity$/ { cap = int($1) }
             FILENAME ~ /status$/ { st = $0 }
             END {
                 ramPct = mt > 0 ? int((mt - ma) * 100 / mt) : 0
                 printf "%d|%d|%d|%.1f / %.1f GB|%d|%d|%s\\n", act, tot, ramPct, (mt-ma)/1048576, mt/1048576, temp, cap, st
             }`,
            "/proc/stat",
            "/proc/meminfo",
            "/sys/class/thermal/thermal_zone0/temp",
            "/sys/class/power_supply/BAT0/capacity",
            "/sys/class/power_supply/BAT0/status"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split("|");
                if (p.length >= 7) {
                    const act = parseFloat(p[0]);
                    const tot = parseFloat(p[1]);
                    if (root.prevCpuTot > 0 && tot > root.prevCpuTot) {
                        root.cpuUsage = Math.max(0, Math.min(100, Math.round((act - root.prevCpuAct) * 100 / (tot - root.prevCpuTot))));
                    }
                    root.prevCpuAct = act;
                    root.prevCpuTot = tot;

                    const r = parseInt(p[2]);
                    if (!isNaN(r)) root.ramUsage = r;
                    root.ramUsedText = p[3].trim();
                    const t = parseInt(p[4]);
                    if (!isNaN(t) && t > 0) root.cpuTemp = t;
                    const bCap = parseInt(p[5]);
                    if (!isNaN(bCap) && bCap > 0) root.sysfsBatPercent = bCap;
                    if (p[6].trim() !== "") root.sysfsBatStatus = p[6].trim();
                }
            }
        }
    }

    // Leitura sob demanda (apenas ao abrir as gavetas de Hardware/Bateria/Notificações)
    Process {
        id: drawerSysPoll
        command: [
            "sh", "-c",
            "DISK_INFO=$(df -h /home | awk 'NR==2 {gsub(\"%\",\"\",$5); print $5 \"|\" $3 \" / \" $2}'); " +
            "PP=$(powerprofilesctl get 2>/dev/null); " +
            "BRI=$(brightnessctl -m 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%'); " +
            "BAT_W=$(awk '{printf(\"%.1f\", $1/1000000)}' /sys/class/power_supply/BAT*/power_now 2>/dev/null | head -n1); " +
            "echo \"${DISK_INFO}|${PP:-balanced}|${BRI:-100}|${BAT_W:-0.0}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split("|");
                if (p.length >= 5) {
                    const d = parseInt(p[0]);
                    if (!isNaN(d)) root.diskUsage = d;
                    root.diskUsedText = p[1].trim();
                    if (p[2].trim() !== "") root.powerProfile = p[2].trim();
                    const b = parseInt(p[3]);
                    if (!isNaN(b)) {
                        root.brightness = b;
                        root.hasBacklight = true;
                    }
                    root.batteryWatts = p[4].trim();
                }
            }
        }
    }

    // =========================================================================
    // 6. BATERIA (UPower nativo + Sysfs BAT0 fallback em tempo real)
    // =========================================================================
    property int sysfsBatPercent: 92
    property string sysfsBatStatus: "Discharging"
    property string batteryWatts: "0.0"

    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool hasBattery: true
    readonly property int batteryPercent: (batteryDevice && batteryDevice.isPresent && batteryDevice.percentage > 0)
        ? Math.round(batteryDevice.percentage * 100)
        : sysfsBatPercent
    readonly property bool batteryCharging: (batteryDevice && batteryDevice.isPresent)
        ? (batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.FullyCharged || batteryDevice.state === UPowerDeviceState.PendingCharge)
        : (sysfsBatStatus === "Charging" || sysfsBatStatus === "Full" || sysfsBatStatus === "Not charging")

    readonly property string batteryIcon: {
        if (batteryCharging) return "󰂄";
        if (batteryPercent >= 90) return "󰁹";
        if (batteryPercent >= 70) return "󰂀";
        if (batteryPercent >= 50) return "󰁾";
        if (batteryPercent >= 30) return "󰁼";
        if (batteryPercent >= 15) return "󰁺";
        return "󰂎";
    }

    // =========================================================================
    // 7. MULTIMÍDIA INTELIGENTE: NETFLIX, YOUTUBE, PRIME VIDEO, DISNEY+, SPOTIFY E MP3 DO SISTEMA
    // =========================================================================
    readonly property var playersList: Mpris.players.values
    property int selectedPlayerIndex: -1
    property string zenWindowTitles: ""

    readonly property bool zenPlayingAudio: {
        for (let i = 0; i < root.audioApps.length; i++) {
            const nm = (root.audioApps[i].name || "").toLowerCase();
            if (nm.includes("zen") || nm.includes("firefox") || nm.includes("mozilla")) {
                return true;
            }
        }
        return false;
    }

    // Detecta streaming no Zen Browser mesmo quando o DRM (Netflix/Prime/Disney+) omite metadados MPRIS
    readonly property var zenStreamingInfo: {
        const titles = (root.zenWindowTitles || "").split(" ;; ");
        for (let i = 0; i < titles.length; i++) {
            const raw = titles[i].trim();
            if (!raw) continue;
            const low = raw.toLowerCase();
            const clean = raw
                .replace(/\s*[—–-]\s*Zen Browser$/i, "")
                .replace(/\s*[—–-]\s*Mozilla Firefox$/i, "")
                .replace(/^\(\d+\)\s*/, "")
                .trim();

            if (low.includes("netflix")) {
                const show = clean.replace(/\s*[—–-]\s*Netflix$/i, "").trim();
                return { platform: "netflix", title: show || "Netflix", subtitle: "Netflix • Zen Browser" };
            }
            if (low.includes("prime video") || low.includes("amazon prime")) {
                const show = clean.replace(/\s*[—–-|]\s*(Amazon\s*)?Prime Video.*$/i, "").trim();
                return { platform: "prime", title: show || "Prime Video", subtitle: "Prime Video • Zen Browser" };
            }
            if (low.includes("disney+")) {
                const show = clean.replace(/\s*[—–-|]\s*Disney\+.*$/i, "").trim();
                return { platform: "disney", title: show || "Disney+", subtitle: "Disney+ • Zen Browser" };
            }
            if (low.includes("youtube")) {
                const show = clean.replace(/\s*[—–-]\s*YouTube$/i, "").trim();
                return { platform: "youtube", title: show || "YouTube", subtitle: "YouTube • Zen Browser" };
            }
        }
        return null;
    }

    readonly property var activePlayer: {
        const list = playersList;
        if (!list || list.length === 0) return null;

        if (root.selectedPlayerIndex >= 0 && root.selectedPlayerIndex < list.length) {
            return list[root.selectedPlayerIndex];
        }

        // Prioriza qualquer player que esteja ativamente reproduzindo (isPlaying)
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i];
        }
        return list[0];
    }

    function getPlayerUrl(p) {
        if (!p || !p.metadata) return "";
        return String(p.metadata["xesam:url"] || "").toLowerCase();
    }

    function classifyPlayer(p) {
        if (!p) {
            if (zenStreamingInfo) return zenStreamingInfo.platform;
            return "mp3";
        }
        const id = (p.identity || "").toLowerCase();
        const entry = (p.desktopEntry || "").toLowerCase();
        const url = getPlayerUrl(p);
        const titleLow = (p.trackTitle || "").toLowerCase();
        const artistLow = (p.trackArtist || "").toLowerCase();

        if (id.includes("spotify") || entry.includes("spotify") || url.includes("spotify.com")) {
            return "spotify";
        }

        const isBrowser = id.includes("firefox") || id.includes("zen") || id.includes("mozilla") || entry.includes("zen") || entry.includes("firefox") || url.startsWith("http");
        if (isBrowser) {
            if (url.includes("netflix.com") || titleLow.includes("netflix") || artistLow.includes("netflix")) return "netflix";
            if (url.includes("primevideo.com") || url.includes("amazon.") || titleLow.includes("prime video")) return "prime";
            if (url.includes("disneyplus.com") || url.includes("starplus.com") || titleLow.includes("disney+")) return "disney";
            if (url.includes("youtube.com") || url.includes("youtu.be") || artistLow.includes("youtube")) return "youtube";
            if (zenStreamingInfo) return zenStreamingInfo.platform;
            return "youtube";
        }

        // Players locais de música / MP3 do sistema (mpv, vlc, amberol, elisa, lollypop, audacious, rhythmbox, etc.)
        return "mp3";
    }

    readonly property string mediaPlatform: classifyPlayer(activePlayer)

    // Metadados visuais e Tema Específico de cada Plataforma
    readonly property var platformTheme: {
        switch (mediaPlatform) {
            case "netflix":
                return {
                    id: "netflix",
                    name: "Netflix",
                    badge: "Netflix",
                    icon: "󰝆",
                    accent: Qt.color("#ff2632"),
                    secondary: Qt.color("#990f17"),
                    useCoverAccent: false
                };
            case "youtube":
                return {
                    id: "youtube",
                    name: "YouTube",
                    badge: "YouTube",
                    icon: "󰗃",
                    accent: Qt.color("#ff2b45"),
                    secondary: Qt.color("#b31227"),
                    useCoverAccent: true
                };
            case "prime":
                return {
                    id: "prime",
                    name: "Prime Video",
                    badge: "Prime Video",
                    icon: "󰐌",
                    accent: Qt.color("#00b4f5"),
                    secondary: Qt.color("#006699"),
                    useCoverAccent: false
                };
            case "disney":
                return {
                    id: "disney",
                    name: "Disney+",
                    badge: "Disney+",
                    icon: "󰓎",
                    accent: Qt.color("#528bff"),
                    secondary: Qt.color("#113ccf"),
                    useCoverAccent: false
                };
            case "spotify":
                return {
                    id: "spotify",
                    name: "Spotify",
                    badge: "Spotify",
                    icon: "󰓇",
                    accent: Qt.color("#1ed760"),
                    secondary: Qt.color("#128038"),
                    useCoverAccent: true
                };
            default: // "mp3" (MP3 do Sistema)
                return {
                    id: "mp3",
                    name: activePlayer && activePlayer.identity ? activePlayer.identity : "MP3",
                    badge: activePlayer && activePlayer.identity ? activePlayer.identity : "MP3",
                    icon: "󰀥",
                    accent: Qt.color("#f59e0b"),
                    secondary: Qt.color("#b45309"),
                    useCoverAccent: true
                };
        }
    }

    readonly property string mediaIcon: platformTheme.icon
    readonly property string mediaBadgeText: platformTheme.badge

    readonly property bool hasMedia: (activePlayer !== null && (activePlayer.trackTitle !== "")) || (zenStreamingInfo !== null)
    readonly property bool isPlaying: (activePlayer && activePlayer.isPlaying) || (!activePlayer && zenStreamingInfo !== null && zenPlayingAudio)
    readonly property string trackTitle: {
        if (activePlayer && activePlayer.trackTitle) return activePlayer.trackTitle;
        if (zenStreamingInfo) return zenStreamingInfo.title;
        return "Sem reprodução";
    }
    readonly property string trackArtist: {
        if (activePlayer && activePlayer.trackArtist) return activePlayer.trackArtist;
        if (zenStreamingInfo) return zenStreamingInfo.subtitle;
        if (activePlayer && activePlayer.identity) return activePlayer.identity;
        return "";
    }
    readonly property string trackAlbum: activePlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string trackArtUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property string playerIdentity: platformTheme.name
    readonly property bool isSpotify: mediaPlatform === "spotify"
    readonly property bool isLocalMp3: mediaPlatform === "mp3"

    // Nome exato do player para o playerctl (-p firefox para Zen Browser, -p spotify para Spotify, etc.)
    readonly property string targetPlayerctlName: {
        if (!activePlayer) return "firefox";
        const id = (activePlayer.identity || "").toLowerCase();
        const entry = (activePlayer.desktopEntry || "").toLowerCase();
        if (id.includes("spotify") || entry.includes("spotify")) return "spotify";
        if (id.includes("firefox") || id.includes("zen") || id.includes("mozilla") || entry.includes("zen") || entry.includes("firefox")) return "firefox";
        return (entry || id || "playerctld").split(" ")[0];
    }

    property real livePosition: 0
    property real liveLength: 1
    property bool isSeekingMedia: false

    readonly property real trackPosition: livePosition
    readonly property real trackLength: liveLength > 0 ? liveLength : 1

    Process {
        id: mediaPosPoll
        command: [
            "playerctl",
            "-p", root.targetPlayerctlName,
            "metadata",
            "-f", "{{status}}|{{position}}|{{mpris:length}}"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.isSeekingMedia) return;
                const txt = this.text.trim();
                if (!txt) return;
                const parts = txt.split("|");
                if (parts.length >= 3) {
                    const posUs = parseFloat(parts[1]);
                    const lenUs = parseFloat(parts[2]);
                    if (!isNaN(posUs) && posUs >= 0) {
                        root.livePosition = posUs / 1000000.0;
                    }
                    if (!isNaN(lenUs) && lenUs > 0) {
                        root.liveLength = lenUs / 1000000.0;
                    } else if (root.activePlayer && root.activePlayer.length > 0) {
                        root.liveLength = root.activePlayer.length;
                    }
                }
            }
        }
    }

    // Só consulta a posição do playerctl quando o drawer de mídia está aberto!
    Timer {
        interval: 1000
        running: root.activePopup === "media" && root.hasMedia
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!mediaPosPoll.running && !root.isSeekingMedia) {
                mediaPosPoll.running = true;
            }
        }
    }

    onActivePlayerChanged: {
        root.livePosition = 0;
        if (!mediaPosPoll.running) mediaPosPoll.running = true;
    }

    property string localCoverFile: ""
    property int coverSeq: 0

    function updateCoverArt() {
        if (trackArtUrl === "") {
            root.localCoverFile = "";
        } else if (trackArtUrl.startsWith("file://")) {
            root.localCoverFile = trackArtUrl;
        } else if (trackArtUrl.startsWith("http://") || trackArtUrl.startsWith("https://")) {
            if (coverDownloader.running) coverDownloader.running = false;
            root.coverSeq = (root.coverSeq + 1) % 10000;
            coverDownloader.targetUrl = trackArtUrl;
            coverDownloader.targetPath = `/tmp/qs_album_cover_${root.coverSeq}.jpg`;
            coverDownloader.running = true;
        }
    }

    onTrackArtUrlChanged: updateCoverArt()
    Component.onCompleted: {
        updateCoverArt();
        quickVolPoll.running = true;
        drawerSysPoll.running = true;
    }

    Process {
        id: coverDownloader
        property string targetUrl: ""
        property string targetPath: "/tmp/qs_album_cover_0.jpg"
        command: ["sh", "-c", `rm -f /tmp/qs_album_cover_*.jpg 2>/dev/null; curl -sL "${targetUrl}" -o "${targetPath}" && echo "OK"`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "OK") {
                    root.localCoverFile = "file://" + coverDownloader.targetPath;
                }
            }
        }
    }

    ColorQuantizer {
        id: coverQuantizer
        source: root.localCoverFile
        depth: 4
    }

    // Escolhe a cor mais expressiva da paleta da capa (fugindo do fundo preto/escuro dominante em colors[0])
    function pickBestCoverColor(paletteColors) {
        if (!paletteColors || paletteColors.length === 0) return platformTheme.accent;
        let bestColor = paletteColors[0];
        let bestScore = -1;

        for (let i = 0; i < paletteColors.length; i++) {
            const c = Qt.color(paletteColors[i]);
            const l = c.hslLightness;
            const s = c.hslSaturation;

            // Ignora pixels praticamente 100% pretos
            if (l < 0.06) continue;

            // Prioriza cores saturadas e com luminosidade visível, mas aceita tons claros/médios se a capa for P&B
            const lightWeight = (l >= 0.16 && l <= 0.85) ? 1.0 : 0.45;
            const score = (s * 3.2 + 0.25) * lightWeight + (i === 0 ? 0.15 : 0);

            if (score > bestScore) {
                bestScore = score;
                bestColor = c;
            }
        }
        return Theme.ensureLuminousLight(bestColor);
    }

    // Cor do Spotlight e Tema:
    // - Para Netflix, Prime Video e Disney+ (DRM sem capa), usa a cor oficial do serviço!
    // - Para Spotify, YouTube e MP3 do sistema, extrai a cor viva real da capa da música/vídeo!
    readonly property color mediaCoverColor: {
        if (!platformTheme.useCoverAccent) {
            return platformTheme.accent;
        }
        if (root.localCoverFile !== "" && coverQuantizer.colors && coverQuantizer.colors.length > 0) {
            return root.pickBestCoverColor(coverQuantizer.colors);
        }
        return Theme.ensureLuminousLight(platformTheme.accent);
    }

    readonly property bool canSkipTrack: activePlayer !== null && activePlayer.canGoNext

    function mediaPlayPause() {
        Quickshell.execDetached(["playerctl", "-p", root.targetPlayerctlName, "play-pause"]);
        mediaPosPoll.running = true;
    }

    function mediaNext() {
        if (!root.canSkipTrack) {
            root.livePosition = Math.min(root.liveLength, root.livePosition + 10);
            Quickshell.execDetached(["playerctl", "-p", root.targetPlayerctlName, "position", "10+"]);
        } else {
            Quickshell.execDetached(["playerctl", "-p", root.targetPlayerctlName, "next"]);
        }
        mediaPosPoll.running = true;
    }

    function mediaPrev() {
        if (!root.canSkipTrack) {
            root.livePosition = Math.max(0, root.livePosition - 10);
            Quickshell.execDetached(["playerctl", "-p", root.targetPlayerctlName, "position", "10-"]);
        } else {
            Quickshell.execDetached(["playerctl", "-p", root.targetPlayerctlName, "previous"]);
        }
        mediaPosPoll.running = true;
    }

    function mediaSeek(targetSeconds) {
        const clamped = Math.max(0, Math.min(root.trackLength, targetSeconds));
        root.livePosition = clamped;
        Quickshell.execDetached(["playerctl", "-p", root.targetPlayerctlName, "position", String(Math.round(clamped))]);
    }

    function finishMediaSeek() {
        root.isSeekingMedia = false;
        if (!mediaPosPoll.running) mediaPosPoll.running = true;
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0) return "0:00";
        const totalSec = Math.floor(seconds);
        const mins = Math.floor(totalSec / 60);
        const secs = totalSec % 60;
        return mins + ":" + (secs < 10 ? "0" + secs : secs);
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!sysPoll.running) sysPoll.running = true;
            if ((root.activePopup === "hardware" || root.activePopup === "battery") && !drawerSysPoll.running) {
                drawerSysPoll.running = true;
            }
        }
    }
}
