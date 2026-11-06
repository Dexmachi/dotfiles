import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import ".."

// Popups Nativos Quickshell com estética Spotlight + Matugen colorido:
// - "spotlight"   (SUPER+CTRL+RETURN) -> Centro da tela (Apps, Arquivos, Calculadora, Comandos)
// - "clipboard"   (SUPER+V)           -> Grudado na barra no lado direito (topo ou base)
// - "keybindings" (SUPER+CTRL+K)      -> Grudado na barra no centro (topo ou base)
// - "rbw"         (SUPER+SHIFT+P)     -> Centro da tela com 100% das features do rofi-rbw (Alt+T TOTP, Alt+U, Alt+C, Alt+1..4 wtype, Alt+M Menu, Alt+S Sync)
// - "screenshot"  (PRINT/SUPER+SHIFT+S)-> Centro da tela
// - "sidepad"     (SUPER+CTRL+S)      -> Centro da tela
PanelWindow {
    id: root

    readonly property string activeTool: SystemState.activeToolPopup
    readonly property bool isOpen: activeTool !== ""
    // Mantém o último modo ativo durante a animação de fechar para não pular para o centro!
    property string mode: "spotlight"
    property real progress: isOpen ? 1.0 : 0.0

    Behavior on progress {
        NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
    }

    visible: progress > 0.01
    focusable: true

    WlrLayershell.namespace: "quickshell-spotlight"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // =========================================================================
    // PALETA DE CORES VIBRANTE POR MODO (MATUGEN PRIMARY / SECONDARY / TERTIARY)
    // =========================================================================
    readonly property bool isBarAttached: mode === "clipboard" || mode === "keybindings"
    readonly property color modeAccent: {
        if (mode === "clipboard") return Theme.secondary;
        if (mode === "keybindings") return Theme.tertiary;
        if (mode === "rbw") return Theme.primary;
        if (mode === "spotlight") return Theme.primary;
        if (mode === "screenshot") return Theme.tertiary;
        return Theme.secondary;
    }
    readonly property color modeSecondaryAccent: {
        if (mode === "clipboard") return Theme.primary;
        if (mode === "keybindings") return Theme.primary;
        if (mode === "rbw") return Theme.tertiary;
        if (mode === "spotlight") return Theme.tertiary;
        if (mode === "screenshot") return Theme.primary;
        return Theme.primary;
    }

    property string searchQuery: ""
    property int selectedIndex: 0
    property var rawItems: []
    property var filteredItems: []

    // Estado do Center Spotlight (abre por padrão apenas em Aplicativos)
    property string spotCategory: "apps" // "apps", "files", "cmds", "all"
    property var spotFileResults: []

    // Estado do Bitwarden / RBW (Paridade total com rofi-rbw)
    property string rbwDefaultAction: "type" // "type" (wtype) ou "copy" (wl-copy)
    property bool rbwSyncing: false
    property bool rbwSubmenuOpen: false
    property var rbwSubmenuEntry: null
    property var rbwSubmenuItems: []

    // Estado do Screenshot
    property int shotDelay: 0 // 0, 3, 5, 10
    property string shotAction: "copy" // "copy", "copysave", "save", "edit"

    // Comandos Rápidos para o Center Spotlight
    readonly property var spotQuickCommands: [
        {
            isSpotlightCmd: true,
            title: "Alternar Posição da Barra (Topo / Base)",
            subtitle: "Muda a barra entre o topo e a parte inferior da tela",
            badge: "Barra",
            iconText: "󰹢",
            accent: Theme.primary,
            run: function() { Config.toggleBarPosition(); }
        },
        {
            isSpotlightCmd: true,
            title: "Trocar Wallpaper & Cores (Waypaper)",
            subtitle: "Abre o seletor de wallpapers e atualiza o tema Matugen",
            badge: "Tema",
            iconText: "󰸉",
            accent: Theme.tertiary,
            run: function() { Quickshell.execDetached(["waypaper"]); }
        },
        {
            isSpotlightCmd: true,
            title: "Cofre de Senhas Bitwarden (RBW)",
            subtitle: "Abre o gerenciador de senhas e códigos TOTP 2FA",
            badge: "Vault",
            iconText: "󰌾",
            accent: Theme.secondary,
            run: function() { SystemState.toggleToolPopup("rbw"); }
        },
        {
            isSpotlightCmd: true,
            title: "Histórico da Área de Transferência",
            subtitle: "Abre o histórico do Cliphist na direita da barra",
            badge: "Clipboard",
            iconText: "󰅍",
            accent: Theme.secondary,
            run: function() { SystemState.toggleToolPopup("clipboard"); }
        },
        {
            isSpotlightCmd: true,
            title: "Atalhos de Teclado do Hyprland",
            subtitle: "Mostra todos os atalhos configurados no centro da barra",
            badge: "Teclas",
            iconText: "󰌌",
            accent: Theme.tertiary,
            run: function() { SystemState.toggleToolPopup("keybindings"); }
        },
        {
            isSpotlightCmd: true,
            title: "Alternar Filtro Luz Noturna (Night Light)",
            subtitle: "Ativa ou desativa o shader quente de proteção ocular",
            badge: "Tela",
            iconText: "󰖔",
            accent: Theme.primary,
            run: function() { SystemState.toggleNightLight(); }
        },
        {
            isSpotlightCmd: true,
            title: "Bloquear Sessão (Hyprlock)",
            subtitle: "Trava a sessão imediatamente",
            badge: "Sistema",
            iconText: "󰌾",
            accent: Theme.error,
            run: function() { Quickshell.execDetached(["hyprlock"]); }
        }
    ]

    // =========================================================================
    // PROCESSOS DE DADOS POR MODO
    // =========================================================================

    // 1. Clipboard (cliphist)
    Process {
        id: clipListProc
        command: ["sh", "-c", "cliphist list | head -n 80"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                const items = [];
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i];
                    if (!l.trim()) continue;
                    const tabIdx = l.indexOf("\t");
                    const idStr = tabIdx > 0 ? l.substring(0, tabIdx).trim() : String(i + 1);
                    const preview = tabIdx > 0 ? l.substring(tabIdx + 1).trim() : l.trim();
                    const isImg = preview.includes("[[ binary data");
                    const isUrl = /^https?:\/\//i.test(preview);
                    items.push({
                        rawLine: l,
                        badge: isImg ? "󰋩 IMG" : (isUrl ? "󰖟 LINK" : "#" + idStr),
                        iconText: isImg ? "󰋩" : (isUrl ? "󰖟" : "󰅍"),
                        itemAccent: isImg ? Theme.tertiary : (isUrl ? Theme.primary : Theme.secondary),
                        title: preview,
                        subtitle: isImg ? "Imagem na área de transferência • Enter p/ restaurar" : "Enter p/ copiar • Del ou 󰅖 p/ apagar"
                    });
                }
                root.rawItems = items;
                root.filterList();
            }
        }
    }

    // 2. Keybindings (lê default.lua)
    Process {
        id: keybindsProc
        command: [
            "awk",
            `/hl\\.bind\\(/ {
                line = $0
                sub(/^.*hl\\.bind\\(/, "", line)
                split(line, parts, ",")
                keys = parts[1]
                gsub(/mainMod/, "SUPER", keys)
                gsub(/"/, "", keys)
                gsub(/\\.\\./, "", keys)
                gsub(/  +/, " ", keys)
                gsub(/^ +| +$/, "", keys)
                current_keys = keys
            }
            /^-- / {
                if (current_keys != "" && $0 !~ /^-- ----/ && $0 !~ /^-- Key bindings/ && $0 !~ /^-- name:/) {
                    desc = substr($0, 4)
                    print current_keys "|" desc
                    current_keys = ""
                }
            }`,
            Quickshell.env("HOME") + "/.config/hypr/conf/keybindings/default.lua"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const items = [];
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim();
                    if (!l) continue;
                    const p = l.split("|");
                    if (p.length >= 2) {
                        const k = p[0].trim();
                        const d = p[1].trim();
                        const isSuperShift = k.includes("SHIFT");
                        const isSuperCtrl = k.includes("CTRL");
                        items.push({
                            badge: k,
                            iconText: isSuperCtrl ? "󰘴" : (isSuperShift ? "󰘶" : "󰌌"),
                            itemAccent: isSuperCtrl ? Theme.primary : (isSuperShift ? Theme.secondary : Theme.tertiary),
                            title: d,
                            subtitle: "Teclas: " + k + " • Enter p/ copiar atalho"
                        });
                    }
                }
                root.rawItems = items;
                root.filterList();
            }
        }
    }

    // 3. Bitwarden / RBW (Lista todas as entradas com UUID, nome, usuário e pasta)
    Process {
        id: rbwProc
        command: ["sh", "-c", "rbw unlocked >/dev/null 2>&1 && rbw list --fields id,name,user,folder || echo '__LOCKED__'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const txt = this.text.trim();
                if (txt === "__LOCKED__") {
                    root.rawItems = [{
                        locked: true,
                        badge: "󰌾 Trancado",
                        iconText: "󰌾",
                        itemAccent: Theme.error,
                        title: "Desbloquear Cofre Bitwarden (rbw unlock)",
                        subtitle: "Pressione Enter para autenticar sua senha mestre no Ghostty"
                    }];
                    root.filterList();
                    return;
                }
                const lines = txt.split("\n");
                const items = [];
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i];
                    if (!l.trim()) continue;
                    const p = l.split("\t");
                    const id = (p[0] || "").trim();
                    const name = (p[1] || "").trim();
                    const user = (p[2] || "").trim();
                    const folder = (p[3] || "").trim();
                    if (!name && !id) continue;
                    items.push({
                        locked: false,
                        entryId: id || name,
                        entryName: name,
                        entryUser: user,
                        entryFolder: folder,
                        badge: folder || "Vault",
                        iconText: "󰌆",
                        itemAccent: (i % 3 === 0) ? Theme.primary : ((i % 3 === 1) ? Theme.secondary : Theme.tertiary),
                        title: name,
                        subtitle: user ? ("󰀄 " + user) : "Sem usuário cadastrado"
                    });
                }
                root.rawItems = items;
                root.filterList();
            }
        }
    }

    // 3b. Bitwarden / RBW: Inspecionar todos os campos de um item (Alt+M / Menu de Targets do rofi-rbw)
    Process {
        id: rbwDetailProc
        property string targetId: ""
        property string targetName: ""
        property string targetUser: ""
        command: [
            "sh", "-c",
            `ID='${targetId.replace(/'/g, "'\\''")}'; RAW=$(rbw get --raw "$ID" 2>/dev/null || echo '{}'); CODE=$(rbw code "$ID" 2>/dev/null || echo ''); printf '%s\n__TOTP_SPLIT__\n%s' "$RAW" "$CODE"`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("\n__TOTP_SPLIT__\n");
                const rawJson = (parts[0] || "{}").trim();
                const totpCode = (parts[1] || "").trim();
                let parsed = {};
                try {
                    parsed = JSON.parse(rawJson);
                } catch (e) {
                    parsed = {};
                }
                const data = parsed.data || {};
                const sub = [];

                // 1. Sequência completa Auto-Type (Username + Tab + Password)
                sub.push({
                    isRbwTarget: true,
                    targetType: "autotype",
                    entryId: rbwDetailProc.targetId,
                    entryName: rbwDetailProc.targetName,
                    badge: "Auto-Type",
                    iconText: "󰌌",
                    itemAccent: Theme.primary,
                    title: "Digitar Usuário + Tab + Senha (wtype)",
                    subtitle: "Atalho rápido: Alt+1 • Também copia o TOTP se existir"
                });

                // 2. Código TOTP 2FA (se disponível)
                if (totpCode !== "" || data.totp) {
                    sub.push({
                        isRbwTarget: true,
                        targetType: "totp",
                        targetValue: totpCode,
                        entryId: rbwDetailProc.targetId,
                        entryName: rbwDetailProc.targetName,
                        badge: "2FA TOTP",
                        iconText: "󰔛",
                        itemAccent: Theme.tertiary,
                        title: totpCode !== "" ? ("Código TOTP: " + totpCode) : "Gerar Código TOTP (2FA)",
                        subtitle: "Enter p/ copiar • Alt+T p/ digitar com wtype"
                    });
                }

                // 3. Senha
                if (data.password) {
                    sub.push({
                        isRbwTarget: true,
                        targetType: "value",
                        label: "Senha",
                        targetValue: data.password,
                        badge: "Senha",
                        iconText: "󰌆",
                        itemAccent: Theme.secondary,
                        title: "•••••••••••• (Senha)",
                        subtitle: "Enter p/ copiar • Alt+T p/ digitar com wtype"
                    });
                }

                // 4. Usuário
                const usr = data.username || rbwDetailProc.targetUser || "";
                if (usr !== "") {
                    sub.push({
                        isRbwTarget: true,
                        targetType: "value",
                        label: "Usuário",
                        targetValue: usr,
                        badge: "Usuário",
                        iconText: "󰀄",
                        itemAccent: Theme.primary,
                        title: usr,
                        subtitle: "Enter p/ copiar • Alt+T p/ digitar com wtype"
                    });
                }

                // 5. URIs
                const uris = data.uris || [];
                for (let i = 0; i < uris.length; i++) {
                    if (uris[i] && uris[i].uri) {
                        sub.push({
                            isRbwTarget: true,
                            targetType: "value",
                            label: "URI",
                            targetValue: uris[i].uri,
                            badge: "URI / Link",
                            iconText: "󰖟",
                            itemAccent: Theme.tertiary,
                            title: uris[i].uri,
                            subtitle: "Enter p/ copiar URL"
                        });
                    }
                }

                // 6. Notas
                if (parsed.notes) {
                    sub.push({
                        isRbwTarget: true,
                        targetType: "value",
                        label: "Notas",
                        targetValue: parsed.notes,
                        badge: "Notas",
                        iconText: "📝",
                        itemAccent: Theme.secondary,
                        title: parsed.notes.replace(/\n+/g, " "),
                        subtitle: "Enter p/ copiar notas"
                    });
                }

                // 7. Campos personalizados (Custom Fields)
                const fields = parsed.fields || [];
                for (let j = 0; j < fields.length; j++) {
                    const f = fields[j];
                    if (f && f.name) {
                        sub.push({
                            isRbwTarget: true,
                            targetType: "value",
                            label: f.name,
                            targetValue: f.value || "",
                            badge: f.name,
                            iconText: "󰓹",
                            itemAccent: Theme.primary,
                            title: f.type === "hidden" ? "••••••••" : (f.value || ""),
                            subtitle: "Campo personalizado (" + f.name + ") • Enter p/ copiar"
                        });
                    }
                }

                root.rbwSubmenuItems = sub;
                root.rbwSubmenuOpen = true;
                root.selectedIndex = 0;
                root.filterList();
            }
        }
    }

    // 3c. Bitwarden / RBW Sync (Alt+S)
    Process {
        id: rbwSyncProc
        command: ["rbw", "sync"]
        onExited: (code) => {
            root.rbwSyncing = false;
            Quickshell.execDetached(["notify-send", "-a", "Bitwarden Vault", code === 0 ? "Cofre Sincronizado" : "Erro no Sync", code === 0 ? "rbw sync concluído com sucesso!" : "Falha ao sincronizar o rbw."]);
            rbwProc.running = true;
        }
    }

    // 4. Sidepad Selector
    Process {
        id: sidepadProc
        command: ["sh", "-c", "ls -1 ~/.config/sidepad/pads 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const items = [];
                for (let i = 0; i < lines.length; i++) {
                    const pad = lines[i].trim();
                    if (!pad) continue;
                    items.push({
                        padName: pad,
                        badge: "Sidepad",
                        iconText: "󰕮",
                        itemAccent: (i % 2 === 0) ? Theme.secondary : Theme.primary,
                        title: pad,
                        subtitle: "Alternar Sidepad ativo para " + pad
                    });
                }
                root.rawItems = items;
                root.filterList();
            }
        }
    }

    // 5. Busca de Arquivos (fd) para o Center Spotlight
    Process {
        id: spotFdProc
        property string pendingQuery: ""
        command: [
            "fd",
            "--max-results", "35",
            "--ignore-case",
            "--exclude", ".git",
            "--exclude", "node_modules",
            "--exclude", ".cache",
            pendingQuery,
            Quickshell.env("HOME")
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const files = [];
                const homeDir = Quickshell.env("HOME");
                for (let i = 0; i < lines.length && files.length < 35; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    const parts = line.replace(/\/$/, "").split("/");
                    const base = parts[parts.length - 1] || line;
                    const isDir = line.endsWith("/");
                    files.push({
                        isSpotlightFile: true,
                        fullPath: line,
                        badge: isDir ? "Pasta" : "Arquivo",
                        iconText: isDir ? "󰉋" : "󰈔",
                        itemAccent: isDir ? Theme.tertiary : Theme.secondary,
                        title: base,
                        subtitle: line.replace(homeDir, "~")
                    });
                }
                root.spotFileResults = files;
                if (root.mode === "spotlight") {
                    root.filterList();
                }
            }
        }
    }

    function triggerSpotlightFileSearch(q) {
        const clean = q.trim().replace(/^[@/]\s*/, "");
        if (clean.length < 2) {
            root.spotFileResults = [];
            root.filterList();
            return;
        }
        if (spotFdProc.running) spotFdProc.running = false;
        spotFdProc.pendingQuery = clean;
        spotFdProc.running = true;
    }

    // Avaliador seguro de expressões matemáticas para o Center Spotlight
    function tryEvalMath(expr) {
        const clean = expr.trim().replace(/^=\s*/, "").replace(/,/g, ".");
        if (!clean || clean.length < 2) return null;
        // Deve conter ao menos um operador matemático ou começar com '='
        if (!/[+\-*/%^()]/.test(clean) && !expr.trim().startsWith("=")) return null;
        if (!/^[0-9+\-*/%.^()\s]+$/.test(clean)) return null;
        try {
            const jsExpr = clean.replace(/\^/g, "**");
            const val = Function("return (" + jsExpr + ")")();
            if (typeof val === "number" && isFinite(val)) {
                const formatted = Number.isInteger(val) ? String(val) : String(Number(val.toFixed(6)));
                return formatted;
            }
        } catch (e) {}
        return null;
    }

    // =========================================================================
    // FILTRAGEM DE RESULTADOS
    // =========================================================================
    function filterList() {
        const rawQ = root.searchQuery.trim();
        const q = rawQ.toLowerCase();

        // Caso especial: Center Spotlight (combina Calculadora, Apps, Comandos e Arquivos)
        if (root.mode === "spotlight") {
            const out = [];
            const isCmdPrefix = rawQ.startsWith(">") || rawQ.startsWith("$") || rawQ.startsWith(":");
            const isFilePrefix = rawQ.startsWith("@") || rawQ.startsWith("/");
            const cleanQ = rawQ.replace(/^[>$:@/]\s*/, "").toLowerCase();

            // 1. Calculadora instantânea
            const mathRes = root.tryEvalMath(rawQ);
            if (mathRes !== null) {
                out.push({
                    isSpotlightMath: true,
                    mathValue: mathRes,
                    badge: "Calculadora",
                    iconText: "󰪚",
                    itemAccent: Theme.tertiary,
                    title: rawQ.replace(/^=\s*/, "") + " = " + mathRes,
                    subtitle: "Pressione Enter para copiar " + mathRes + " para a área de transferência"
                });
            }

            // 2. Aplicativos
            if (!isCmdPrefix && !isFilePrefix && (root.spotCategory === "all" || root.spotCategory === "apps")) {
                const apps = DesktopEntries.applications.values;
                for (let i = 0; i < apps.length; i++) {
                    const app = apps[i];
                    if (!app || app.noDisplay) continue;
                    const nm = (app.name || "").toLowerCase();
                    const gen = (app.genericName || "").toLowerCase();
                    const comm = (app.comment || "").toLowerCase();
                    if (cleanQ === "" || nm.includes(cleanQ) || gen.includes(cleanQ) || comm.includes(cleanQ)) {
                        out.push({
                            isSpotlightApp: true,
                            appEntry: app,
                            appIcon: app.icon || "",
                            badge: "App",
                            iconText: "󰣆",
                            itemAccent: Theme.primary,
                            title: app.name,
                            subtitle: app.comment || app.genericName || "Aplicativo do Sistema"
                        });
                    }
                }
            }

            // 3. Comandos Rápidos & Shell
            if (!isFilePrefix && (isCmdPrefix || root.spotCategory === "all" || root.spotCategory === "cmds")) {
                for (let j = 0; j < root.spotQuickCommands.length; j++) {
                    const qc = root.spotQuickCommands[j];
                    if (cleanQ === "" || qc.title.toLowerCase().includes(cleanQ) || qc.subtitle.toLowerCase().includes(cleanQ)) {
                        out.push({
                            isSpotlightCmd: true,
                            cmdAction: qc.run,
                            badge: qc.badge,
                            iconText: qc.iconText,
                            itemAccent: qc.accent,
                            title: qc.title,
                            subtitle: qc.subtitle
                        });
                    }
                }
                if (cleanQ.length > 0 && (isCmdPrefix || root.spotCategory === "cmds")) {
                    out.push({
                        isSpotlightShell: true,
                        shellCmd: rawQ.replace(/^[>$:]\s*/, ""),
                        badge: "Shell",
                        iconText: "󰆍",
                        itemAccent: Theme.secondary,
                        title: "Executar no Shell: " + rawQ.replace(/^[>$:]\s*/, ""),
                        subtitle: "Executa o comando em segundo plano"
                    });
                }
            }

            // 4. Arquivos (fd)
            if (isFilePrefix || root.spotCategory === "files" || (root.spotCategory === "all" && cleanQ.length >= 2)) {
                for (let k = 0; k < root.spotFileResults.length; k++) {
                    out.push(root.spotFileResults[k]);
                }
            }

            root.filteredItems = out;
            if (root.selectedIndex >= root.filteredItems.length) {
                root.selectedIndex = Math.max(0, root.filteredItems.length - 1);
            }
            toolListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
            return;
        }

        // Caso especial: Submenu de Campos do RBW (Alt+M)
        const sourceList = (root.mode === "rbw" && root.rbwSubmenuOpen) ? root.rbwSubmenuItems : root.rawItems;

        if (q === "") {
            root.filteredItems = sourceList;
        } else {
            const out = [];
            for (let i = 0; i < sourceList.length; i++) {
                const it = sourceList[i];
                const t = (it.title || "").toLowerCase();
                const s = (it.subtitle || "").toLowerCase();
                const b = (it.badge || "").toLowerCase();
                if (t.includes(q) || s.includes(q) || b.includes(q)) {
                    out.push(it);
                }
            }
            root.filteredItems = out;
        }
        if (root.selectedIndex >= root.filteredItems.length) {
            root.selectedIndex = Math.max(0, root.filteredItems.length - 1);
        }
        toolListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    // =========================================================================
    // AÇÕES DO BITWARDEN / RBW (PARIDADE 100% COM ROFI-RBW)
    // =========================================================================
    // actionType: "copy_pass", "copy_user", "copy_totp", "type_both", "type_user", "type_pass", "type_totp", "menu"
    function executeRbwAction(item, actionType) {
        if (!item) return;
        if (item.locked) {
            SystemState.closePopups();
            Quickshell.execDetached(["ghostty", "-e", "rbw", "unlock"]);
            return;
        }

        // Se estivermos dentro do Submenu de Campos (Alt+M)
        if (item.isRbwTarget) {
            if (item.targetType === "autotype") {
                root.executeRbwAction({ entryId: item.entryId, entryName: item.entryName }, "type_both");
                return;
            }
            if (item.targetType === "totp") {
                root.executeRbwAction({ entryId: item.entryId, entryName: item.entryName }, actionType === "type_target" ? "type_totp" : "copy_totp");
                return;
            }
            const valEsc = (item.targetValue || "").replace(/'/g, "'\\''");
            const lblEsc = (item.label || "Campo").replace(/'/g, "'\\''");
            SystemState.closePopups();
            if (actionType === "type_target") {
                Quickshell.execDetached(["sh", "-c", `sleep 0.16 && wtype -- '${valEsc}'`]);
            } else {
                Quickshell.execDetached(["sh", "-c", `printf '%s' '${valEsc}' | wl-copy && notify-send -a 'Bitwarden Vault' '${lblEsc} copiado' 'Copiado para a área de transferência'`]);
            }
            return;
        }

        // Abrir menu de campos (Alt+M / Tab)
        if (actionType === "menu") {
            root.rbwSubmenuEntry = item;
            rbwDetailProc.targetId = item.entryId;
            rbwDetailProc.targetName = item.entryName;
            rbwDetailProc.targetUser = item.entryUser || "";
            root.searchQuery = "";
            toolSearchInput.text = "";
            rbwDetailProc.running = true;
            return;
        }

        const idEsc = (item.entryId || item.entryName || "").replace(/'/g, "'\\''");
        const nmEsc = (item.entryName || "").replace(/'/g, "'\\''");
        const usrEsc = (item.entryUser || "").replace(/'/g, "'\\''");

        SystemState.closePopups();

        if (actionType === "copy_pass") {
            const cmd = `PASS=$(rbw get '${idEsc}' 2>/dev/null | head -n 1 | tr -d '\\n'); if [ -n "$PASS" ]; then printf '%s' "$PASS" | wl-copy; notify-send -a 'Bitwarden Vault' '󰌆 Senha copiada' '${nmEsc}'; else notify-send -a 'Bitwarden Vault' 'Erro ao obter senha' '${nmEsc}'; fi`;
            Quickshell.execDetached(["sh", "-c", cmd]);
        } else if (actionType === "copy_user") {
            const cmd = usrEsc !== ""
                ? `printf '%s' '${usrEsc}' | wl-copy && notify-send -a 'Bitwarden Vault' '󰀄 Usuário copiado' '${usrEsc} (${nmEsc})'`
                : `USR=$(rbw get --field username '${idEsc}' 2>/dev/null | tr -d '\\n'); printf '%s' "$USR" | wl-copy && notify-send -a 'Bitwarden Vault' '󰀄 Usuário copiado' "$USR (${nmEsc})"`;
            Quickshell.execDetached(["sh", "-c", cmd]);
        } else if (actionType === "copy_totp") {
            const cmd = `CODE=$(rbw code '${idEsc}' 2>/dev/null | tr -d '\\n'); if [ -n "$CODE" ]; then printf '%s' "$CODE" | wl-copy; notify-send -a 'Bitwarden Vault' "󰔛 TOTP: $CODE" 'Código 2FA copiado para a área de transferência (${nmEsc})'; else notify-send -a 'Bitwarden Vault' 'Sem TOTP cadastrado' '${nmEsc} não possui chave 2FA'; fi`;
            Quickshell.execDetached(["sh", "-c", cmd]);
        } else if (actionType === "type_user") {
            const cmd = `sleep 0.16; USR='${usrEsc}'; [ -z "$USR" ] && USR=$(rbw get --field username '${idEsc}' 2>/dev/null | tr -d '\\n'); [ -n "$USR" ] && wtype -- "$USR"`;
            Quickshell.execDetached(["sh", "-c", cmd]);
        } else if (actionType === "type_pass") {
            const cmd = `sleep 0.16; PASS=$(rbw get '${idEsc}' 2>/dev/null | head -n 1 | tr -d '\\n'); [ -n "$PASS" ] && wtype -- "$PASS"; CODE=$(rbw code '${idEsc}' 2>/dev/null | tr -d '\\n'); if [ -n "$CODE" ]; then printf '%s' "$CODE" | wl-copy; notify-send -a 'Bitwarden Vault' "󰔛 TOTP copiado: $CODE" 'Pronto para colar (Ctrl+V)'; fi`;
            Quickshell.execDetached(["sh", "-c", cmd]);
        } else if (actionType === "type_totp") {
            const cmd = `sleep 0.16; CODE=$(rbw code '${idEsc}' 2>/dev/null | tr -d '\\n'); if [ -n "$CODE" ]; then wtype -- "$CODE"; else notify-send -a 'Bitwarden Vault' 'Sem TOTP cadastrado' '${nmEsc}'; fi`;
            Quickshell.execDetached(["sh", "-c", cmd]);
        } else if (actionType === "type_both") {
            // Igual ao padrão do rofi-rbw: digita username -> Tab -> password via wtype e já copia o TOTP (se houver) pro clipboard!
            const cmd = `
                sleep 0.16
                USR='${usrEsc}'
                [ -z "$USR" ] && USR=$(rbw get --field username '${idEsc}' 2>/dev/null | tr -d '\\n')
                PASS=$(rbw get '${idEsc}' 2>/dev/null | head -n 1 | tr -d '\\n')
                if [ -n "$USR" ] && [ -n "$PASS" ]; then
                    wtype -- "$USR"
                    wtype -k Tab
                    wtype -- "$PASS"
                elif [ -n "$PASS" ]; then
                    wtype -- "$PASS"
                fi
                CODE=$(rbw code '${idEsc}' 2>/dev/null | tr -d '\\n')
                if [ -n "$CODE" ]; then
                    printf '%s' "$CODE" | wl-copy
                    notify-send -a 'Bitwarden Vault' "󰔛 TOTP copiado: $CODE" 'Auto-type concluído • TOTP pronto no Ctrl+V'
                fi
            `;
            Quickshell.execDetached(["sh", "-c", cmd]);
        }
    }

    // =========================================================================
    // AÇÃO PRINCIPAL (ENTER / CLIQUE)
    // =========================================================================
    function triggerCurrentItem(item) {
        if (!item) return;

        if (root.mode === "spotlight") {
            SystemState.closePopups();
            if (item.isSpotlightMath) {
                const v = item.mathValue.replace(/'/g, "'\\''");
                Quickshell.execDetached(["sh", "-c", `printf '%s' '${v}' | wl-copy && notify-send -a 'Spotlight' 'Resultado copiado' '${v}'`]);
            } else if (item.isSpotlightApp && item.appEntry) {
                item.appEntry.execute();
            } else if (item.isSpotlightFile && item.fullPath) {
                Quickshell.execDetached(["xdg-open", item.fullPath]);
            } else if (item.isSpotlightCmd && item.cmdAction) {
                item.cmdAction();
            } else if (item.isSpotlightShell && item.shellCmd) {
                Quickshell.execDetached(["sh", "-c", item.shellCmd]);
            }
            return;
        }

        if (root.mode === "clipboard") {
            const escaped = item.rawLine.replace(/'/g, "'\\''");
            Quickshell.execDetached(["sh", "-c", `printf '%s' '${escaped}' | cliphist decode | wl-copy`]);
            SystemState.closePopups();
        } else if (root.mode === "rbw") {
            if (root.rbwSubmenuOpen) {
                root.executeRbwAction(item, "copy_target");
            } else {
                const act = root.rbwDefaultAction === "type" ? "type_both" : "copy_pass";
                root.executeRbwAction(item, act);
            }
        } else if (root.mode === "sidepad") {
            const pad = item.padName;
            const cmd = `SIDEPAD_PATH="$HOME/.config/sidepad/sidepad"; SIDEPAD_DATA="$HOME/.config/ml4w/settings/sidepad-active"; SIDEPAD_PADS_FOLDER="$HOME/.config/sidepad/pads"; source "$SIDEPAD_PADS_FOLDER/$(cat "$SIDEPAD_DATA")" 2>/dev/null; eval "$SIDEPAD_PATH --class '$SIDEPAD_CLASS' --kill" 2>/dev/null; echo "${pad}" > "$SIDEPAD_DATA"; source "$SIDEPAD_PADS_FOLDER/${pad}"; eval "$SIDEPAD_PATH --class '$SIDEPAD_CLASS' --init '$SIDEPAD_APP'"`;
            Quickshell.execDetached(["bash", "-c", cmd]);
            SystemState.closePopups();
        } else if (root.mode === "keybindings") {
            const kEsc = (item.badge || "").replace(/'/g, "'\\''");
            Quickshell.execDetached(["sh", "-c", `printf '%s' '${kEsc}' | wl-copy && notify-send -a 'Keybindings' 'Atalho copiado' '${kEsc}'`]);
            SystemState.closePopups();
        }
    }

    function deleteClipItem(item) {
        if (!item || !item.rawLine) return;
        const escaped = item.rawLine.replace(/'/g, "'\\''");
        Quickshell.execDetached(["sh", "-c", `printf '%s\\n' '${escaped}' | cliphist delete`]);
        const nextRaw = [];
        for (let i = 0; i < root.rawItems.length; i++) {
            if (root.rawItems[i].rawLine !== item.rawLine) {
                nextRaw.push(root.rawItems[i]);
            }
        }
        root.rawItems = nextRaw;
        root.filterList();
    }

    function wipeClipboard() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        root.rawItems = [];
        root.filteredItems = [];
    }

    function takeScreenshot(captureType) {
        const delay = root.shotDelay;
        const action = root.shotAction;
        SystemState.closePopups();

        const cmd = `
            source ~/.config/ml4w/settings/screenshot-filename.sh 2>/dev/null
            source ~/.config/ml4w/settings/screenshot-folder.sh 2>/dev/null
            export GRIMBLAST_EDITOR="$(cat ~/.config/ml4w/settings/screenshot-editor.sh 2>/dev/null)"
            sleep 0.25
            if [ "${delay}" -gt 0 ]; then
                for i in $(seq ${delay} -1 1); do
                    notify-send -t 900 -a "Screenshot" "Captura em \${i}s..."
                    sleep 1
                done
            fi
            grimblast --notify "${action}" "${captureType}" "$NAME"
            if [ -n "$NAME" ] && [ -f "$HOME/$NAME" ] && [ -d "$screenshot_folder" ]; then
                mv "$HOME/$NAME" "$screenshot_folder/"
            fi
        `;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    onActiveToolChanged: {
        if (activeTool === "") return;
        root.mode = activeTool;
        root.searchQuery = "";
        toolSearchInput.text = "";
        root.selectedIndex = 0;
        root.rawItems = [];
        root.filteredItems = [];
        root.rbwSubmenuOpen = false;
        root.rbwSubmenuEntry = null;
        root.spotCategory = "apps";
        root.spotFileResults = [];

        if (root.mode === "clipboard") {
            clipListProc.running = true;
            toolSearchInput.forceActiveFocus();
        } else if (root.mode === "keybindings") {
            keybindsProc.running = true;
            toolSearchInput.forceActiveFocus();
        } else if (root.mode === "rbw") {
            rbwProc.running = true;
            toolSearchInput.forceActiveFocus();
        } else if (root.mode === "sidepad") {
            sidepadProc.running = true;
            toolSearchInput.forceActiveFocus();
        } else if (root.mode === "spotlight") {
            root.filterList();
            toolSearchInput.forceActiveFocus();
        } else if (root.mode === "screenshot") {
            shotFocusScope.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: SystemState.closePopups()
    }

    // =========================================================================
    // CONTAINER PRINCIPAL (COM POSICIONAMENTO DINÂMICO E SPOTLIGHT COLORIDO)
    // =========================================================================
    Rectangle {
        id: toolBox

        readonly property bool isShot: root.mode === "screenshot"
        readonly property int maxVisibleRows: root.mode === "spotlight" ? 7 : 6
        readonly property int visibleRows: Math.min(maxVisibleRows, root.filteredItems.length)
        readonly property real rowPitch: root.mode === "rbw" ? 54 : 50
        readonly property real listH: visibleRows > 0 ? (visibleRows * rowPitch) : 64
        readonly property real extraBarH: (root.mode === "spotlight" || root.mode === "rbw") ? 38 : 0

        width: {
            if (isShot) return 450;
            if (root.mode === "spotlight") return 620;
            if (root.mode === "rbw") return 590;
            if (root.mode === "keybindings") return 560;
            if (root.mode === "clipboard") return 460;
            return 500;
        }

        readonly property real targetFullH: isShot ? 255 : (124 + extraBarH + listH)
        height: Math.max(0, targetFullH * root.progress)

        // POSICIONAMENTO EXATO:
        // - clipboard: grudado na barra no lado direito (topo ou base)
        // - keybindings: grudado na barra no centro (topo ou base)
        // - spotlight, rbw, screenshot, sidepad: no centro da tela
        x: {
            if (root.mode === "clipboard") {
                return root.width - width - Config.marginHorizontal;
            }
            return (root.width - width) / 2;
        }

        y: {
            if (root.isBarAttached) {
                return Config.isTop
                    ? (Config.barHeight + Config.marginVertical + 4)
                    : (root.height - Config.barHeight - Config.marginVertical - height - 4);
            }
            return (root.height - height) / 2;
        }

        radius: Config.popupRadius
        color: Theme.popupBg
        border.width: Config.borderWidth
        border.color: Theme.alpha(root.modeAccent, 0.55)
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // =====================================================================
        // GRADIENTE SPOTLIGHT MULTICOLORIDO (FIM DO VISUAL CINZA/SEM VIDA)
        // =====================================================================
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: (!root.isBarAttached || Config.isTop)
                        ? Theme.alpha(root.modeAccent, 0.40)
                        : Theme.alpha(root.modeSecondaryAccent, 0.10)
                }
                GradientStop {
                    position: 0.48
                    color: Theme.alpha(root.modeSecondaryAccent, 0.14)
                }
                GradientStop {
                    position: 1.0
                    color: (root.isBarAttached && !Config.isTop)
                        ? Theme.alpha(root.modeAccent, 0.40)
                        : Theme.alpha(root.modeSecondaryAccent, 0.12)
                }
            }
        }

        // =====================================================================
        // ABA LUMINOSA CONECTANDO NA BARRA (CLIPBOARD À DIREITA, KEYBINDINGS NO MEIO)
        // =====================================================================
        Rectangle {
            visible: root.isBarAttached
            width: root.mode === "keybindings" ? 84 : 56
            height: 3.5
            radius: 2
            color: root.modeAccent
            anchors.top: Config.isTop ? parent.top : undefined
            anchors.bottom: !Config.isTop ? parent.bottom : undefined
            x: root.mode === "clipboard"
                ? (parent.width - width - 28)
                : ((parent.width - width) / 2)
        }

        // Barra luminosa superior nos modais centrais (Spotlight, RBW, Screenshot)
        Rectangle {
            visible: !root.isBarAttached
            width: 96
            height: 3
            radius: 1.5
            color: root.modeAccent
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // =====================================================================
        // A) INTERFACE DE SCREENSHOT (PRINT / SUPER+SHIFT+S)
        // =====================================================================
        FocusScope {
            id: shotFocusScope
            visible: root.mode === "screenshot"
            anchors.fill: parent
            anchors.margins: 16
            opacity: root.progress

            Keys.onEscapePressed: SystemState.closePopups()
            Keys.onReturnPressed: root.takeScreenshot("area")
            Keys.onEnterPressed: root.takeScreenshot("area")

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 30; height: 30; radius: 9
                        color: Theme.alpha(root.modeAccent, 0.25)
                        border.width: 1
                        border.color: root.modeAccent

                        Text {
                            anchors.centerIn: parent
                            text: "󰄀"
                            font.family: Config.fontFamily
                            font.pixelSize: 16
                            color: root.modeAccent
                        }
                    }

                    Text {
                        text: "Captura de Tela"
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 22
                        width: escShotTxt.implicitWidth + 12
                        radius: 6
                        color: Theme.alpha(root.modeAccent, 0.16)
                        Text {
                            id: escShotTxt
                            anchors.centerIn: parent
                            text: "ESC fecha"
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: root.modeAccent
                        }
                    }
                }

                // 3 Grandes Botões Coloridos de Tipo de Captura
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            { id: "area", icon: "󰩭", title: "Seleção", sub: "Recortar área", col: Theme.primary },
                            { id: "output", icon: "󰖯", title: "Monitor", sub: "Tela ativa", col: Theme.secondary },
                            { id: "screen", icon: "󰍹", title: "Tudo", sub: "Todos monitores", col: Theme.tertiary }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: 12
                            color: capMouse.containsMouse
                                ? Theme.alpha(modelData.col, 0.30)
                                : Theme.alpha(modelData.col, 0.14)
                            border.width: Config.borderWidth
                            border.color: capMouse.containsMouse ? modelData.col : Theme.alpha(modelData.col, 0.45)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    font.family: Config.fontFamily
                                    font.pixelSize: 24
                                    color: modelData.col
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.title
                                    font.family: Config.fontFamily
                                    font.pixelSize: Config.fontSizeNormal
                                    font.bold: true
                                    color: Theme.textPrimary
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.sub
                                    font.family: Config.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textSecondary
                                }
                            }

                            MouseArea {
                                id: capMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.takeScreenshot(modelData.id)
                            }
                        }
                    }
                }

                // Linha de Timer (0s, 3s, 5s, 10s)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰔛 Timer:"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: root.modeAccent
                    }

                    Repeater {
                        model: [
                            { sec: 0, label: "Agora" },
                            { sec: 3, label: "3s" },
                            { sec: 5, label: "5s" },
                            { sec: 10, label: "10s" }
                        ]

                        delegate: Rectangle {
                            readonly property bool isSel: root.shotDelay === modelData.sec
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 8
                            color: isSel ? Theme.primary : Theme.alpha(Theme.primary, 0.12)
                            border.width: Config.borderWidth
                            border.color: isSel ? Theme.primary : Theme.alpha(Theme.primary, 0.30)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: isSel ? Theme.contrastColor(Theme.primary) : Theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shotDelay = modelData.sec
                            }
                        }
                    }
                }

                // Linha de Ação (Copiar & Salvar, Copiar, Salvar, Editar)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰆏 Ação:"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.secondary
                    }

                    Repeater {
                        model: [
                            { id: "copy", label: "Copiar" },
                            { id: "copysave", label: "Copiar & Salvar" },
                            { id: "save", label: "Salvar" },
                            { id: "edit", label: "Editar" }
                        ]

                        delegate: Rectangle {
                            readonly property bool isSel: root.shotAction === modelData.id
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 8
                            color: isSel ? Theme.secondary : Theme.alpha(Theme.secondary, 0.12)
                            border.width: Config.borderWidth
                            border.color: isSel ? Theme.secondary : Theme.alpha(Theme.secondary, 0.30)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Config.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: isSel ? Theme.contrastColor(Theme.secondary) : Theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shotAction = modelData.id
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // B) INTERFACE PESQUISÁVEL (SPOTLIGHT CENTRAL, CLIPBOARD, KEYBINDINGS, RBW, SIDEPAD)
        // =====================================================================
        ColumnLayout {
            visible: root.mode !== "screenshot"
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            opacity: root.progress

            // 1. CABEÇALHO COLORIDO DINÂMICO
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Ícone com badge colorido brilhante
                Rectangle {
                    width: 30; height: 30; radius: 9
                    color: Theme.alpha(root.modeAccent, 0.24)
                    border.width: 1
                    border.color: root.modeAccent

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (root.mode === "spotlight") return "󰍉";
                            if (root.mode === "clipboard") return "󰅍";
                            if (root.mode === "keybindings") return "󰌌";
                            if (root.mode === "rbw") return root.rbwSubmenuOpen ? "󰍜" : "󰌾";
                            return "󰕮";
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: 16
                        color: root.modeAccent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: {
                            if (root.mode === "spotlight") return "Spotlight Search";
                            if (root.mode === "clipboard") return "Área de Transferência";
                            if (root.mode === "keybindings") return "Atalhos do Hyprland";
                            if (root.mode === "rbw") {
                                return root.rbwSubmenuOpen && root.rbwSubmenuEntry
                                    ? ("Campos: " + root.rbwSubmenuEntry.entryName)
                                    : "Cofre Bitwarden (RBW)";
                            }
                            return "Selecionar Sidepad";
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                    }

                    Text {
                        text: {
                            if (root.mode === "spotlight") return "Aplicativos, cálculos (=), arquivos (@) e comandos (>)";
                            if (root.mode === "clipboard") return root.filteredItems.length + " itens salvos no histórico";
                            if (root.mode === "keybindings") return root.filteredItems.length + " atalhos ativos no default.lua";
                            if (root.mode === "rbw") {
                                return root.rbwSubmenuOpen
                                    ? "Esc ou Backspace p/ voltar • Enter copia • Alt+T digita"
                                    : (root.rbwSyncing ? "Sincronizando cofre com o servidor..." : (root.filteredItems.length + " credenciais no cofre"));
                            }
                            return "Escolha o sidepad ativo";
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        color: root.modeAccent
                    }
                }

                // Botão Voltar do Submenu RBW
                Rectangle {
                    visible: root.mode === "rbw" && root.rbwSubmenuOpen
                    height: 26
                    width: backRbwTxt.implicitWidth + 16
                    radius: 8
                    color: backRbwMouse.containsMouse ? root.modeAccent : Theme.alpha(root.modeAccent, 0.18)
                    border.width: 1
                    border.color: root.modeAccent

                    Text {
                        id: backRbwTxt
                        anchors.centerIn: parent
                        text: "󰁍 Voltar (Esc)"
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: backRbwMouse.containsMouse ? Theme.contrastColor(root.modeAccent) : root.modeAccent
                    }

                    MouseArea {
                        id: backRbwMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.rbwSubmenuOpen = false;
                            root.selectedIndex = 0;
                            root.filterList();
                            toolSearchInput.forceActiveFocus();
                        }
                    }
                }

                // Botões de Controle do RBW (Alternar Auto-Type vs Copiar + Botão Sync)
                RowLayout {
                    visible: root.mode === "rbw" && !root.rbwSubmenuOpen
                    spacing: 6

                    // Alternar modo padrão do Enter: Auto-Type (wtype) vs Copiar (wl-copy)
                    Rectangle {
                        height: 26
                        width: modeRbwTxt.implicitWidth + 16
                        radius: 8
                        color: Theme.alpha(root.modeAccent, 0.20)
                        border.width: 1
                        border.color: root.modeAccent

                        Text {
                            id: modeRbwTxt
                            anchors.centerIn: parent
                            text: root.rbwDefaultAction === "type" ? "󰌌 Enter: Auto-Type" : "󰆏 Enter: Copiar"
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: root.modeAccent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.rbwDefaultAction = (root.rbwDefaultAction === "type") ? "copy" : "type";
                                toolSearchInput.forceActiveFocus();
                            }
                        }
                    }

                    // Botão Sync (Alt+S)
                    Rectangle {
                        height: 26
                        width: syncRbwTxt.implicitWidth + 14
                        radius: 8
                        color: syncRbwMouse.containsMouse ? Theme.tertiary : Theme.alpha(Theme.tertiary, 0.20)
                        border.width: 1
                        border.color: Theme.tertiary

                        Text {
                            id: syncRbwTxt
                            anchors.centerIn: parent
                            text: root.rbwSyncing ? "󰑐 Sync..." : "󰑐 Sync (Alt+S)"
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: syncRbwMouse.containsMouse ? Theme.contrastColor(Theme.tertiary) : Theme.tertiary
                        }

                        MouseArea {
                            id: syncRbwMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.rbwSyncing) {
                                    root.rbwSyncing = true;
                                    rbwSyncProc.running = true;
                                }
                                toolSearchInput.forceActiveFocus();
                            }
                        }
                    }
                }

                // Botão Limpar Tudo no modo Clipboard
                Rectangle {
                    visible: root.mode === "clipboard" && root.rawItems.length > 0
                    height: 26
                    width: wipeTxt.implicitWidth + 16
                    radius: 8
                    color: wipeMouse.containsMouse ? Theme.error : Theme.alpha(Theme.error, 0.20)
                    border.width: 1
                    border.color: Theme.error

                    Text {
                        id: wipeTxt
                        anchors.centerIn: parent
                        text: "󰎟 Limpar Tudo"
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: wipeMouse.containsMouse ? Theme.contrastColor(Theme.error) : Theme.error
                    }

                    MouseArea {
                        id: wipeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wipeClipboard()
                    }
                }
            }

            // 2. CAMPO DE BUSCA SPOTLIGHT COM BORDA COLORIDA BRILHANTE
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: Theme.alpha(root.modeAccent, 0.13)
                border.width: 1
                border.color: Theme.alpha(root.modeAccent, 0.65)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: ""
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        color: root.modeAccent
                    }

                    TextInput {
                        id: toolSearchInput
                        Layout.fillWidth: true
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeNormal
                        font.bold: true
                        color: Theme.textPrimary
                        selectionColor: root.modeAccent
                        selectedTextColor: Theme.contrastColor(root.modeAccent)
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: toolSearchInput.text === ""
                            text: {
                                if (root.mode === "spotlight") return "Pesquisar apps, cálculos (ex: 25*4), @arquivos ou >comandos...";
                                if (root.mode === "rbw") return root.rbwSubmenuOpen ? "Filtrar campos da credencial..." : "Buscar conta, usuário ou pasta...";
                                if (root.mode === "clipboard") return "Filtrar histórico da área de transferência...";
                                if (root.mode === "keybindings") return "Buscar por tecla (ex: SUPER + V) ou descrição...";
                                return "Filtrar resultados...";
                            }
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeNormal
                            font.bold: false
                            color: Theme.alpha(Theme.textSecondary, 0.75)
                        }

                        onTextChanged: {
                            root.searchQuery = text;
                            root.selectedIndex = 0;
                            if (root.mode === "spotlight") {
                                const trimmed = text.trim();
                                if (trimmed.startsWith("@") || trimmed.startsWith("/") || root.spotCategory === "files" || root.spotCategory === "all") {
                                    root.triggerSpotlightFileSearch(trimmed);
                                }
                            }
                            root.filterList();
                        }

                        // ATALHOS DE TECLADO COMPLETOS (INCLUINDO TODOS OS ATALHOS DO ROFI-RBW!)
                        Keys.onPressed: (event) => {
                            const curItem = (root.filteredItems.length > 0 && root.selectedIndex >= 0)
                                ? root.filteredItems[root.selectedIndex]
                                : null;

                            // Atalhos exclusivos do modo RBW (idênticos ao rofi-rbw!)
                            if (root.mode === "rbw") {
                                const isAlt = (event.modifiers & Qt.AltModifier) !== 0;

                                // Tab abre o menu de campos (Targets) da entrada selecionada
                                if (event.key === Qt.Key_Tab && !root.rbwSubmenuOpen && curItem && !curItem.locked) {
                                    root.executeRbwAction(curItem, "menu");
                                    event.accepted = true;
                                    return;
                                }

                                if (isAlt) {
                                    // Alt+T -> Copia TOTP (ou no submenu digita o campo selecionado)
                                    if (event.key === Qt.Key_T) {
                                        if (root.rbwSubmenuOpen && curItem) {
                                            root.executeRbwAction(curItem, "type_target");
                                        } else if (curItem) {
                                            root.executeRbwAction(curItem, "copy_totp");
                                        }
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+U -> Copia Username
                                    if (event.key === Qt.Key_U && curItem) {
                                        root.executeRbwAction(curItem, "copy_user");
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+C ou Alt+P -> Copia Senha
                                    if ((event.key === Qt.Key_C || event.key === Qt.Key_P) && curItem) {
                                        if (root.rbwSubmenuOpen) {
                                            root.executeRbwAction(curItem, "copy_target");
                                        } else {
                                            root.executeRbwAction(curItem, "copy_pass");
                                        }
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+1 ou Alt+A -> Auto-type Username + Tab + Password
                                    if ((event.key === Qt.Key_1 || event.key === Qt.Key_A) && curItem) {
                                        root.executeRbwAction(curItem, "type_both");
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+2 -> Auto-type Username
                                    if (event.key === Qt.Key_2 && curItem) {
                                        root.executeRbwAction(curItem, "type_user");
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+3 -> Auto-type Password
                                    if (event.key === Qt.Key_3 && curItem) {
                                        root.executeRbwAction(curItem, "type_pass");
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+4 -> Auto-type TOTP
                                    if (event.key === Qt.Key_4 && curItem) {
                                        root.executeRbwAction(curItem, "type_totp");
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+M -> Menu de Campos (Targets)
                                    if (event.key === Qt.Key_M && curItem) {
                                        if (root.rbwSubmenuOpen) {
                                            root.rbwSubmenuOpen = false;
                                            root.selectedIndex = 0;
                                            root.filterList();
                                        } else {
                                            root.executeRbwAction(curItem, "menu");
                                        }
                                        event.accepted = true;
                                        return;
                                    }
                                    // Alt+S -> Sincronizar Cofre (rbw sync)
                                    if (event.key === Qt.Key_S) {
                                        if (!root.rbwSyncing) {
                                            root.rbwSyncing = true;
                                            rbwSyncProc.running = true;
                                        }
                                        event.accepted = true;
                                        return;
                                    }
                                }
                            }

                            // Atalho Delete no modo Clipboard apaga o item selecionado
                            if (root.mode === "clipboard" && event.key === Qt.Key_Delete && curItem) {
                                root.deleteClipItem(curItem);
                                event.accepted = true;
                                return;
                            }
                        }

                        Keys.onDownPressed: {
                            if (root.filteredItems.length > 0) {
                                root.selectedIndex = (root.selectedIndex + 1) % root.filteredItems.length;
                                toolListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            }
                        }
                        Keys.onUpPressed: {
                            if (root.filteredItems.length > 0) {
                                root.selectedIndex = (root.selectedIndex - 1 + root.filteredItems.length) % root.filteredItems.length;
                                toolListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            }
                        }
                        Keys.onReturnPressed: {
                            if (root.filteredItems.length > 0 && root.selectedIndex >= 0) {
                                root.triggerCurrentItem(root.filteredItems[root.selectedIndex]);
                            }
                        }
                        Keys.onEnterPressed: {
                            if (root.filteredItems.length > 0 && root.selectedIndex >= 0) {
                                root.triggerCurrentItem(root.filteredItems[root.selectedIndex]);
                            }
                        }
                        Keys.onEscapePressed: {
                            if (root.mode === "rbw" && root.rbwSubmenuOpen) {
                                root.rbwSubmenuOpen = false;
                                root.selectedIndex = 0;
                                root.filterList();
                            } else {
                                SystemState.closePopups();
                            }
                        }
                    }

                    // Limpar busca
                    Text {
                        visible: toolSearchInput.text !== ""
                        text: "󰅖"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: root.modeAccent
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                toolSearchInput.text = "";
                                toolSearchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // 2B. BARRA DE PILLS DE CATEGORIA (NO MODO CENTER SPOTLIGHT)
            RowLayout {
                visible: root.mode === "spotlight"
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 8

                Repeater {
                    model: [
                        { id: "apps", icon: "󰣆", label: "Aplicativos", col: Theme.primary },
                        { id: "files", icon: "󰉋", label: "Arquivos", col: Theme.tertiary },
                        { id: "cmds", icon: "󰆍", label: "Comandos", col: Theme.secondary },
                        { id: "all", icon: "󰍉", label: "Tudo", col: Theme.primary }
                    ]

                    delegate: Rectangle {
                        readonly property bool isCur: root.spotCategory === modelData.id
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 9
                        color: isCur ? modelData.col : Theme.alpha(modelData.col, 0.14)
                        border.width: 1
                        border.color: isCur ? modelData.col : Theme.alpha(modelData.col, 0.35)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                color: isCur ? Theme.contrastColor(modelData.col) : modelData.col
                            }

                            Text {
                                text: modelData.label
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: isCur ? Theme.contrastColor(modelData.col) : Theme.textPrimary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.spotCategory = modelData.id;
                                root.selectedIndex = 0;
                                if (modelData.id === "files" && root.searchQuery.length >= 2) {
                                    root.triggerSpotlightFileSearch(root.searchQuery);
                                }
                                root.filterList();
                                toolSearchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // 2C. BARRA DE ATALHOS COLORIDOS DO ROFI-RBW (NO MODO RBW)
            RowLayout {
                visible: root.mode === "rbw"
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 5

                Repeater {
                    model: [
                        { key: "Alt+T", desc: "TOTP 2FA", act: "copy_totp", col: Theme.tertiary },
                        { key: "Alt+C", desc: "Senha", act: "copy_pass", col: Theme.primary },
                        { key: "Alt+U", desc: "Usuário", act: "copy_user", col: Theme.secondary },
                        { key: "Alt+1", desc: "Auto-Type", act: "type_both", col: Theme.primary },
                        { key: "Alt+M", desc: "Campos", act: "menu", col: Theme.tertiary }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 7
                        color: rbwHintMouse.containsMouse
                            ? Theme.alpha(modelData.col, 0.32)
                            : Theme.alpha(modelData.col, 0.14)
                        border.width: 1
                        border.color: Theme.alpha(modelData.col, 0.45)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: modelData.key
                                font.family: Config.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                color: modelData.col
                            }

                            Text {
                                text: modelData.desc
                                font.family: Config.fontFamily
                                font.pixelSize: 9
                                color: Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: rbwHintMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.filteredItems.length > 0 && root.selectedIndex >= 0) {
                                    root.executeRbwAction(root.filteredItems[root.selectedIndex], modelData.act);
                                }
                            }
                        }
                    }
                }
            }

            // 3. LISTA DE RESULTADOS COLORIDA E VIVA
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: toolBox.listH

                Rectangle {
                    visible: root.filteredItems.length === 0
                    anchors.fill: parent
                    radius: 12
                    color: Theme.alpha(root.modeAccent, 0.08)
                    border.width: 1
                    border.color: Theme.alpha(root.modeAccent, 0.25)

                    Text {
                        anchors.centerIn: parent
                        text: root.mode === "spotlight" && root.spotCategory === "files" && root.searchQuery.length < 2
                            ? "Digite pelo menos 2 letras para buscar arquivos na sua Home..."
                            : "Nenhum resultado encontrado"
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeSmall
                        color: Theme.textSecondary
                    }
                }

                ListView {
                    id: toolListView
                    visible: root.filteredItems.length > 0
                    anchors.fill: parent
                    clip: true
                    spacing: 5
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.filteredItems

                    delegate: Rectangle {
                        readonly property bool isSel: index === root.selectedIndex
                        readonly property color rowAccent: modelData.itemAccent || root.modeAccent

                        width: toolListView.width - (toolListView.count > toolBox.maxVisibleRows ? 8 : 0)
                        height: toolBox.rowPitch - 5
                        radius: 11
                        color: isSel
                            ? Theme.alpha(rowAccent, 0.26)
                            : (rowMouse.containsMouse ? Theme.alpha(rowAccent, 0.16) : Theme.alpha(rowAccent, 0.08))
                        border.width: 1
                        border.color: isSel ? rowAccent : Theme.alpha(rowAccent, 0.28)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            // Ícone Colorido (ou Ícone real do App no Spotlight)
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 9
                                color: isSel ? rowAccent : Theme.alpha(rowAccent, 0.22)
                                border.width: 1
                                border.color: Theme.alpha(rowAccent, 0.55)

                                IconImage {
                                    id: spotAppIconImg
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    visible: (modelData.appIcon || "") !== "" && source !== ""
                                    source: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !spotAppIconImg.visible
                                    text: modelData.iconText || "󰣆"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 15
                                    color: isSel ? Theme.contrastColor(rowAccent) : rowAccent
                                }
                            }

                            // Textos Principais (Título + Subtítulo)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title || ""
                                    font.family: Config.fontFamily
                                    font.pixelSize: Config.fontSizeNormal
                                    font.bold: true
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.subtitle || ""
                                    font.family: Config.fontFamily
                                    font.pixelSize: 10
                                    color: isSel ? rowAccent : Theme.textSecondary
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            // Ações Rápidas Interativas na Linha Selecionada do RBW
                            RowLayout {
                                visible: root.mode === "rbw" && !root.rbwSubmenuOpen && !modelData.locked && isSel
                                spacing: 4
                                z: 3

                                Repeater {
                                    model: [
                                        { icon: "󰔛", tip: "TOTP", act: "copy_totp", col: Theme.tertiary },
                                        { icon: "󰌆", tip: "Senha", act: "copy_pass", col: Theme.primary },
                                        { icon: "󰀄", tip: "User", act: "copy_user", col: Theme.secondary },
                                        { icon: "󰌌", tip: "Digitar", act: "type_both", col: Theme.primary },
                                        { icon: "󰍜", tip: "Mais", act: "menu", col: Theme.tertiary }
                                    ]

                                    delegate: Rectangle {
                                        height: 24
                                        width: actRowTxt.implicitWidth + 10
                                        radius: 6
                                        color: actRowMouse.containsMouse ? modelData.col : Theme.alpha(modelData.col, 0.22)
                                        border.width: 1
                                        border.color: modelData.col

                                        Text {
                                            id: actRowTxt
                                            anchors.centerIn: parent
                                            text: modelData.icon + " " + modelData.tip
                                            font.family: Config.fontFamily
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: actRowMouse.containsMouse ? Theme.contrastColor(modelData.col) : modelData.col
                                        }

                                        MouseArea {
                                            id: actRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.executeRbwAction(modelData, modelData.act)
                                        }
                                    }
                                }
                            }

                            // Pill / Badge Colorido (Tecla de atalho, Pasta do Vault, Categoria ou ID do Cliphist)
                            Rectangle {
                                visible: !(root.mode === "rbw" && !root.rbwSubmenuOpen && isSel)
                                height: 24
                                width: Math.min(190, bdgTxt.implicitWidth + 14)
                                radius: 7
                                color: isSel ? rowAccent : Theme.alpha(rowAccent, 0.20)
                                border.width: 1
                                border.color: Theme.alpha(rowAccent, 0.50)

                                Text {
                                    id: bdgTxt
                                    anchors.centerIn: parent
                                    width: Math.min(176, implicitWidth)
                                    text: modelData.badge || ""
                                    font.family: Config.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: isSel ? Theme.contrastColor(rowAccent) : rowAccent
                                    elide: Text.ElideRight
                                }
                            }

                            // Botão apagar individual no modo Clipboard
                            Rectangle {
                                visible: root.mode === "clipboard"
                                width: 24; height: 24; radius: 6
                                color: delClipMouse.containsMouse ? Theme.alpha(Theme.error, 0.30) : Theme.alpha(Theme.error, 0.12)
                                border.width: 1
                                border.color: delClipMouse.containsMouse ? Theme.error : "transparent"
                                z: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.error
                                }

                                MouseArea {
                                    id: delClipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.deleteClipItem(modelData)
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: 1
                            onEntered: root.selectedIndex = index
                            onClicked: root.triggerCurrentItem(modelData)
                        }
                    }
                }

                // Scrollbar colorida
                Rectangle {
                    visible: toolListView.visible && toolListView.count > toolBox.maxVisibleRows
                    anchors.right: parent.right
                    width: 4
                    radius: 2
                    color: Theme.alpha(root.modeAccent, 0.65)
                    y: toolListView.visibleArea.yPosition * toolListView.height
                    height: Math.max(20, toolListView.visibleArea.heightRatio * toolListView.height)
                }
            }
        }
    }
}
