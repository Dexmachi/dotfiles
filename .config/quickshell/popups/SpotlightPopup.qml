import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import ".."

PanelWindow {
    id: root

    readonly property bool isOpen: SystemState.activePopup === "spotlight"
    property real progress: isOpen ? 1.0 : 0.0

    Behavior on progress {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
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

    property string searchQuery: ""
    property string activeTab: "apps" // Abre sempre em "Aplicativos"
    property int selectedIndex: 0
    property bool powerMenuOpen: false
    property var fileResults: []
    property var combinedResults: []
    readonly property string userName: Quickshell.env("USER") || "dexmachina"
    readonly property string facePath: "file://" + Quickshell.env("HOME") + "/.face"

    readonly property var quickCommands: [
        {
            type: "cmd",
            title: "Alternar Barra: Topo / Base",
            subtitle: "Muda a posição da barra na tela instantaneamente",
            iconText: "󰹢",
            action: function() { Config.toggleBarPosition(); }
        },
        {
            type: "cmd",
            title: "Trocar Wallpaper & Cores (Waypaper + Matugen)",
            subtitle: "Abre o seletor de wallpapers e atualiza a paleta",
            iconText: "󰸉",
            action: function() { Quickshell.execDetached(["waypaper"]); }
        },
        {
            type: "cmd",
            title: "Modo Performance / Eco (Power Profile)",
            subtitle: "Alterna o perfil de energia atual",
            iconText: "󰓅",
            action: function() { SystemState.cyclePowerProfile(); }
        },
        {
            type: "cmd",
            title: "Bloquear Sessão (Hyprlock)",
            subtitle: "Trava a tela imediatamente",
            iconText: "󰌾",
            action: function() { Quickshell.execDetached(["hyprlock"]); }
        }
    ]

    Process {
        id: fdProcess
        property string pendingQuery: ""
        command: [
            "fd",
            "--max-results", "40",
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
                for (let i = 0; i < lines.length && files.length < 40; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    const parts = line.replace(/\/$/, "").split("/");
                    const base = parts[parts.length - 1] || line;
                    const isDir = line.endsWith("/");
                    files.push({
                        type: "file",
                        title: base,
                        subtitle: line.replace(homeDir, "~"),
                        fullPath: line,
                        iconText: isDir ? "󰉋" : "󰈔"
                    });
                }
                root.fileResults = files;
                root.rebuildResults();
            }
        }
    }

    function triggerFileSearch(q) {
        const clean = q.trim().replace(/^@\s*/, "");
        if (clean.length < 2) {
            root.fileResults = [];
            root.rebuildResults();
            return;
        }
        if (fdProcess.running) fdProcess.running = false;
        fdProcess.pendingQuery = clean;
        fdProcess.running = true;
    }

    readonly property bool isAppsMode: {
        const raw = root.searchQuery.trim();
        const isCmdPrefix = raw.startsWith(">") || raw.startsWith("$") || raw.startsWith(":");
        const isFilePrefix = raw.startsWith("@") || raw.startsWith("/");
        return !isCmdPrefix && !isFilePrefix && root.activeTab === "apps";
    }

    function rebuildResults() {
        const raw = root.searchQuery.trim();
        const isCmdPrefix = raw.startsWith(">") || raw.startsWith("$") || raw.startsWith(":");
        const isFilePrefix = raw.startsWith("@") || raw.startsWith("/");
        const q = raw.replace(/^[>$:@]\s*/, "").toLowerCase();

        const list = [];

        // 1. Modo Comandos
        if (isCmdPrefix || root.activeTab === "cmds") {
            if (q.length > 0) {
                list.push({
                    type: "shell",
                    title: "Executar: " + q,
                    subtitle: "Rodar comando diretamente no shell",
                    shellCmd: q,
                    iconText: "󰆍"
                });
            }
            for (let i = 0; i < quickCommands.length; i++) {
                const qc = quickCommands[i];
                if (q === "" || qc.title.toLowerCase().includes(q) || qc.subtitle.toLowerCase().includes(q)) {
                    list.push(qc);
                }
            }
        }
        // 2. Modo Arquivos
        else if (isFilePrefix || root.activeTab === "files") {
            for (let i = 0; i < root.fileResults.length; i++) {
                list.push(root.fileResults[i]);
            }
        }
        // 3. Modo Padrão: Aplicativos (Grade 4x5 rolável)
        else {
            const apps = DesktopEntries.applications.values;
            for (let i = 0; i < apps.length; i++) {
                const app = apps[i];
                if (!app || app.noDisplay) continue;
                const name = (app.name || "").toLowerCase();
                const gen = (app.genericName || "").toLowerCase();
                const comm = (app.comment || "").toLowerCase();
                if (q === "" || name.includes(q) || gen.includes(q) || comm.includes(q)) {
                    list.push({
                        type: "app",
                        title: app.name,
                        subtitle: app.comment || app.genericName || "Aplicativo",
                        appIcon: app.icon || "",
                        entry: app,
                        iconText: "󰣆"
                    });
                }
            }
        }

        root.combinedResults = list;
        if (root.selectedIndex >= root.combinedResults.length) {
            root.selectedIndex = Math.max(0, root.combinedResults.length - 1);
        }
        if (root.isAppsMode) {
            appsGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
        } else {
            resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    function executeItem(item) {
        if (!item) return;
        SystemState.closePopups();
        if (item.type === "app" && item.entry) {
            item.entry.execute();
        } else if (item.type === "file" && item.fullPath) {
            Quickshell.execDetached(["xdg-open", item.fullPath]);
        } else if (item.type === "shell" && item.shellCmd) {
            Quickshell.execDetached(["sh", "-c", item.shellCmd]);
        } else if (item.type === "cmd" && item.action) {
            item.action();
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            root.activeTab = "apps";
            root.powerMenuOpen = false;
            searchInput.text = "";
            root.searchQuery = "";
            root.selectedIndex = 0;
            root.fileResults = [];
            root.rebuildResults();
            appsGridView.positionViewAtBeginning();
            resultsListView.positionViewAtBeginning();
            // Força recarregar ~/.face caso o arquivo tenha acabado de ser atualizado
            faceImg.source = "";
            faceImg.source = root.facePath;
            searchInput.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: SystemState.closePopups()
    }

    // =========================================================================
    // GAVETA START MENU (Estendendo do botão Arch na esquerda)
    // =========================================================================
    Rectangle {
        id: spotDrawer

        readonly property real targetW: 440
        // Grade 3x4 para Aplicativos (3 colunas x até 4 linhas de 78px)
        readonly property int gridRows: Math.min(4, Math.ceil(root.combinedResults.length / 3))
        readonly property int listRows: Math.min(4, root.combinedResults.length)
        readonly property real viewportH: root.isAppsMode
            ? (gridRows > 0 ? (gridRows * 78) : 56)
            : (listRows > 0 ? (listRows * 48) : 56)

        // Soma: Barra de pesquisa (44) + Pills (32) + Viewport (viewportH) + Rodapé (42) + espaçamentos/margens (60)
        readonly property real targetH: 44 + 32 + viewportH + 42 + 60

        property real animatedTargetH: targetH
        Behavior on animatedTargetH {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        width: targetW
        height: Math.max(0, animatedTargetH * root.progress)

        x: Config.marginHorizontal
        y: Config.isTop
            ? (Config.barHeight + Config.marginVertical + 4)
            : (root.height - Config.barHeight - Config.marginVertical - height - 4)

        radius: Config.popupRadius
        color: Theme.popupBg
        border.width: Config.borderWidth
        border.color: Theme.alpha(Theme.primary, 0.45)
        clip: true

        // Efeito Spotlight colorido (Matugen Primary + Tertiary)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Config.isTop ? Theme.alpha(Theme.primary, 0.36) : Theme.alpha(Theme.tertiary, 0.08)
                }
                GradientStop {
                    position: 0.55
                    color: Theme.alpha(Theme.primary, 0.08)
                }
                GradientStop {
                    position: 1.0
                    color: !Config.isTop ? Theme.alpha(Theme.primary, 0.36) : Theme.alpha(Theme.tertiary, 0.08)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Aba luminosa alinhada ao botão Arch da esquerda
        Rectangle {
            width: 36
            height: 3
            radius: 1.5
            color: Theme.primary
            opacity: 0.85
            x: 12
            anchors.top: Config.isTop ? parent.top : undefined
            anchors.bottom: !Config.isTop ? parent.bottom : undefined
        }

        ColumnLayout {
            id: spotCol
            width: spotDrawer.targetW - 28
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: Config.isTop ? parent.top : undefined
            anchors.topMargin: Config.isTop ? 15 : 0
            anchors.bottom: !Config.isTop ? parent.bottom : undefined
            anchors.bottomMargin: !Config.isTop ? 15 : 0
            spacing: 10
            opacity: root.progress

            // =================================================================
            // 1. BARRA DE PESQUISA
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: Theme.cardBg
                border.width: Config.borderWidth
                border.color: Theme.widgetBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: ""
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        color: Theme.primary
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeNormal
                        font.weight: Font.Medium
                        color: Theme.textPrimary
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.contrastColor(Theme.primary)
                        clip: true
                        focus: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text === ""
                            text: root.activeTab === "apps"
                                ? "Pesquisar aplicativos..."
                                : (root.activeTab === "files" ? "Pesquisar arquivos na home..." : "Digite ou escolha um comando...")
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeNormal
                            color: Theme.alpha(Theme.textSecondary, 0.65)
                        }

                        onTextChanged: {
                            root.searchQuery = text;
                            root.selectedIndex = 0;
                            if (root.activeTab === "files" || text.trim().startsWith("@")) {
                                root.triggerFileSearch(text);
                            }
                            root.rebuildResults();
                        }

                        Keys.onRightPressed: (event) => {
                            if (root.isAppsMode && searchInput.text === "" && root.combinedResults.length > 0) {
                                root.selectedIndex = (root.selectedIndex + 1) % root.combinedResults.length;
                                appsGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                                event.accepted = true;
                            }
                        }
                        Keys.onLeftPressed: (event) => {
                            if (root.isAppsMode && searchInput.text === "" && root.combinedResults.length > 0) {
                                root.selectedIndex = (root.selectedIndex - 1 + root.combinedResults.length) % root.combinedResults.length;
                                appsGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                                event.accepted = true;
                            }
                        }
                        Keys.onDownPressed: {
                            if (root.combinedResults.length > 0) {
                                const step = root.isAppsMode ? 3 : 1;
                                root.selectedIndex = Math.min(root.combinedResults.length - 1, root.selectedIndex + step);
                                if (root.isAppsMode) appsGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                                else resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            }
                        }
                        Keys.onUpPressed: {
                            if (root.combinedResults.length > 0) {
                                const step = root.isAppsMode ? 3 : 1;
                                root.selectedIndex = Math.max(0, root.selectedIndex - step);
                                if (root.isAppsMode) appsGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                                else resultsListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            }
                        }
                        Keys.onReturnPressed: {
                            if (root.combinedResults.length > 0 && root.selectedIndex >= 0) {
                                root.executeItem(root.combinedResults[root.selectedIndex]);
                            }
                        }
                        Keys.onEnterPressed: {
                            if (root.combinedResults.length > 0 && root.selectedIndex >= 0) {
                                root.executeItem(root.combinedResults[root.selectedIndex]);
                            }
                        }
                        Keys.onEscapePressed: {
                            SystemState.closePopups();
                        }
                    }

                    // Botão limpar texto quando houver busca
                    Text {
                        visible: searchInput.text !== ""
                        text: "󰅖"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Theme.textSecondary
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 2. PILLS PARA SELECIONAR O QUE QUER
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 8

                Repeater {
                    model: [
                        { id: "apps", icon: "󰣆", label: "Aplicativos" },
                        { id: "files", icon: "󰉋", label: "Arquivos" },
                        { id: "cmds", icon: "󰆍", label: "Comandos" }
                    ]

                    delegate: Rectangle {
                        readonly property bool isCurrent: root.activeTab === modelData.id
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: 10
                        color: isCurrent
                            ? Theme.primary
                            : (pillTabMouse.containsMouse ? Theme.cardHoverBg : Theme.cardBg)
                        border.width: Config.borderWidth
                        border.color: isCurrent ? Theme.activeBorder : Theme.widgetBorder

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: isCurrent ? Theme.contrastColor(Theme.primary) : Theme.primary
                            }

                            Text {
                                text: modelData.label
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeSmall
                                font.bold: true
                                color: isCurrent ? Theme.contrastColor(Theme.primary) : Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: pillTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = modelData.id;
                                root.selectedIndex = 0;
                                if (modelData.id === "files" && root.searchQuery.length >= 2) {
                                    root.triggerFileSearch(root.searchQuery);
                                }
                                root.rebuildResults();
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. APLICAÇÕES (GRADE 4x5 ROLÁVEL) OU LISTA DE ARQUIVOS/COMANDOS
            // =================================================================
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: spotDrawer.viewportH

                // Estado vazio (ex: aba Arquivos antes de digitar)
                Rectangle {
                    visible: root.combinedResults.length === 0
                    anchors.fill: parent
                    radius: 12
                    color: Theme.cardBg
                    border.width: Config.borderWidth
                    border.color: Theme.widgetBorder

                    Text {
                        anchors.centerIn: parent
                        text: root.activeTab === "files" && root.searchQuery.length < 2
                            ? "Digite pelo menos 2 letras para buscar arquivos..."
                            : "Nenhum resultado encontrado"
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeSmall
                        color: Theme.textSecondary
                    }
                }

                // A) GRADE 3x4 DE APLICATIVOS (Sem caixa ao redor: apenas o ícone e o nome embaixo)
                GridView {
                    id: appsGridView
                    visible: root.isAppsMode && root.combinedResults.length > 0
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: Math.floor((width - 8) / 3)
                    cellHeight: 78
                    model: root.isAppsMode ? root.combinedResults : []

                    delegate: Item {
                        width: appsGridView.cellWidth
                        height: appsGridView.cellHeight

                        readonly property bool isSel: index === root.selectedIndex
                        readonly property bool isHighlight: isSel || gridItemMouse.containsMouse

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 10
                            spacing: 6
                            scale: isHighlight ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36

                                IconImage {
                                    id: gridAppIcon
                                    anchors.centerIn: parent
                                    width: 34
                                    height: 34
                                    visible: (modelData.appIcon || "") !== "" && source !== ""
                                    source: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !gridAppIcon.visible
                                    text: modelData.iconText || "󰣆"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 26
                                    color: isHighlight ? Theme.primary : Theme.textPrimary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.title || ""
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.bold: isHighlight
                                font.weight: isHighlight ? Font.Bold : Font.Medium
                                color: isHighlight ? Theme.primary : Theme.textPrimary
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        MouseArea {
                            id: gridItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = index
                            onClicked: root.executeItem(modelData)
                        }
                    }
                }

                // Scrollbar da Grade 3x4
                Rectangle {
                    visible: appsGridView.visible && appsGridView.count > 12
                    anchors.right: parent.right
                    width: 4
                    radius: 2
                    color: Theme.alpha(Theme.primary, 0.45)
                    y: appsGridView.visibleArea.yPosition * appsGridView.height
                    height: Math.max(20, appsGridView.visibleArea.heightRatio * appsGridView.height)
                }

                // B) LISTA ROLÁVEL PARA ARQUIVOS & COMANDOS
                ListView {
                    id: resultsListView
                    visible: !root.isAppsMode && root.combinedResults.length > 0
                    anchors.fill: parent
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: !root.isAppsMode ? root.combinedResults : []

                    delegate: Rectangle {
                        readonly property bool isSel: index === root.selectedIndex
                        width: resultsListView.width - (resultsListView.count > 5 ? 8 : 0)
                        height: 44
                        radius: 10
                        color: isSel ? Theme.alpha(Theme.primaryContainer, 0.85) : (resMouse.containsMouse ? Theme.cardHoverBg : Theme.cardBg)
                        border.width: Config.borderWidth
                        border.color: isSel ? Theme.activeBorder : Theme.widgetBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                width: 30; height: 30; radius: 8
                                color: isSel ? Theme.primary : Theme.surfaceContainerHighest

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.iconText || "󰈔"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 15
                                    color: isSel ? Theme.contrastColor(Theme.primary) : Theme.primary
                                }
                            }

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
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.subtitle || ""
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: resMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = index
                            onClicked: root.executeItem(modelData)
                        }
                    }
                }

                // Scrollbar da Lista
                Rectangle {
                    visible: resultsListView.visible && resultsListView.count > 5
                    anchors.right: parent.right
                    width: 4
                    radius: 2
                    color: Theme.alpha(Theme.primary, 0.45)
                    y: resultsListView.visibleArea.yPosition * resultsListView.height
                    height: Math.max(18, resultsListView.visibleArea.heightRatio * resultsListView.height)
                }
            }

            // =================================================================
            // 4. RODAPÉ LIMPO (Sem caixa: .face + Nome + Ícone Arquivos + Ícone Power expansível)
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 12

                // Foto de Perfil circular (~/.face)
                ClippingRectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: Theme.surfaceContainerHighest
                    border.width: 1
                    border.color: Theme.primary

                    Image {
                        id: faceImg
                        anchors.fill: parent
                        source: root.facePath
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: faceImg.status !== Image.Ready
                        text: "󰀄"
                        font.family: Config.fontFamily
                        font.pixelSize: 18
                        color: Theme.primary
                    }
                }

                // Nome do Usuário (sem caixa)
                Text {
                    Layout.fillWidth: true
                    text: root.userName
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                }

                // Símbolo de Gerenciador de Arquivos (sem caixa)
                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28

                    Text {
                        anchors.centerIn: parent
                        text: "󰉋"
                        font.family: Config.fontFamily
                        font.pixelSize: 19
                        color: fmMouse.containsMouse ? Theme.primary : Theme.textPrimary
                        scale: fmMouse.containsMouse ? 1.12 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: fmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SystemState.closePopups();
                            Quickshell.execDetached(["nautilus", "--new-window"]);
                        }
                    }
                }

                // Opções de Power que expandem ao clicar no símbolo de Power
                RowLayout {
                    visible: root.powerMenuOpen
                    opacity: root.powerMenuOpen ? 1.0 : 0.0
                    spacing: 10
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // Suspender
                    Item {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        Text {
                            anchors.centerIn: parent
                            text: "󰤄"
                            font.family: Config.fontFamily
                            font.pixelSize: 18
                            color: suspMouse.containsMouse ? Theme.tertiary : Theme.textSecondary
                            scale: suspMouse.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: suspMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SystemState.closePopups();
                                Quickshell.execDetached(["systemctl", "suspend"]);
                            }
                        }
                    }

                    // Reiniciar
                    Item {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        Text {
                            anchors.centerIn: parent
                            text: "󰜉"
                            font.family: Config.fontFamily
                            font.pixelSize: 18
                            color: rebMouse.containsMouse ? Theme.secondary : Theme.textSecondary
                            scale: rebMouse.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: rebMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SystemState.closePopups();
                                Quickshell.execDetached(["systemctl", "reboot"]);
                            }
                        }
                    }

                    // Desligar
                    Item {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: Config.fontFamily
                            font.pixelSize: 18
                            color: offMouse.containsMouse ? Theme.error : Theme.textSecondary
                            scale: offMouse.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: offMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SystemState.closePopups();
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }
                    }
                }

                // Símbolo de Power na direita (clica para abrir/fechar as opções de energia)
                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28

                    Text {
                        anchors.centerIn: parent
                        text: root.powerMenuOpen ? "󰅖" : "󰐥"
                        font.family: Config.fontFamily
                        font.pixelSize: 19
                        color: root.powerMenuOpen || pwrToggleMouse.containsMouse ? Theme.error : Theme.textPrimary
                        scale: pwrToggleMouse.containsMouse ? 1.12 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: pwrToggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.powerMenuOpen = !root.powerMenuOpen
                    }
                }
            }
        }
    }
}
