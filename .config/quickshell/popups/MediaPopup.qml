import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".."

DrawerBase {
    id: root
    popupName: "media"
    targetWidth: mp3Expanded ? 375 : 345
    contentHeight: cardCol.implicitHeight
    accentColor: SystemState.mediaCoverColor
    showSpotlight: true

    property bool shuffleActive: false
    property bool repeatActive: false

    function getSourceLabel(p) {
        const plat = SystemState.classifyPlayer(p);
        if (plat === "netflix") return { icon: "󰝆", name: "Netflix", color: "#ff2632" };
        if (plat === "youtube") return { icon: "󰗃", name: "YouTube", color: "#ff2b45" };
        if (plat === "prime") return { icon: "󰐌", name: "Prime Video", color: "#00b4f5" };
        if (plat === "disney") return { icon: "󰓎", name: "Disney+", color: "#528bff" };
        if (plat === "spotify") return { icon: "󰓇", name: "Spotify", color: "#1ed760" };
        return { icon: "󰀥", name: p.identity || "MP3", color: "#f59e0b" };
    }

    ColumnLayout {
        id: cardCol
        width: parent.width
        spacing: root.mp3Expanded ? 13 : 12

        // =====================================================================
        // SELETOR DE FONTE DE MÍDIA (Aparece quando há mais de 1 player aberto,
        // ex: Zen Browser com YouTube/Netflix + Spotify + MP3 do Sistema)
        // =====================================================================
        RowLayout {
            visible: SystemState.playersList.length > 1
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: SystemState.playersList

                delegate: Rectangle {
                    readonly property var info: root.getSourceLabel(modelData)
                    readonly property bool isSelected: SystemState.activePlayer === modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: 8
                    color: isSelected
                        ? Theme.alpha(root.accentColor, 0.28)
                        : (srcHover.containsMouse ? Theme.cardHoverBg : Theme.cardBg)
                    border.width: Config.borderWidth
                    border.color: isSelected ? Theme.alpha(root.accentColor, 0.65) : Theme.widgetBorder

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: info.icon
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: isSelected ? root.accentColor : Theme.textSecondary
                        }

                        Text {
                            text: info.name
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: isSelected
                            color: isSelected ? Theme.textPrimary : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: srcHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SystemState.selectedPlayerIndex = index;
                            if (SystemState.classifyPlayer(modelData) === "mp3") {
                                root.mp3Expanded = true;
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // MODO 1: COMPACTO (Padrão antes de puxar a meia-lua)
        // =====================================================================
        RowLayout {
            visible: !root.mp3Expanded
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {
                Layout.preferredWidth: 74
                Layout.preferredHeight: 74
                radius: SystemState.isLocalMp3 ? 37 : 14
                color: Theme.cardBg
                border.width: 1
                border.color: Theme.alpha(root.accentColor, 0.55)

                Image {
                    id: compactCoverImg
                    anchors.fill: parent
                    source: SystemState.localCoverFile !== "" ? SystemState.localCoverFile : SystemState.trackArtUrl
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: compactCoverImg.status !== Image.Ready
                    font.family: Config.fontFamily
                    font.pixelSize: 32
                    color: root.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Badge Temático da Plataforma (Netflix, YouTube, Prime Video, Disney+, Spotify, MP3)
                Rectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: badgeRow.implicitWidth + 20
                    radius: 7
                    color: Theme.alpha(root.accentColor, 0.22)
                    border.width: 1
                    border.color: Theme.alpha(root.accentColor, 0.5)

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6
                        Text {
                            text: SystemState.mediaIcon
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: root.accentColor
                        }
                        Text {
                            text: SystemState.mediaBadgeText
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: SystemState.trackTitle
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeLarge
                    font.bold: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: SystemState.trackArtist || SystemState.playerIdentity
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeNormal
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // =====================================================================
        // MODO 2: ESTILO MP3 / CINEMA EXPANDIDO (Ao puxar a meia-lua no canto)
        // =====================================================================
        ColumnLayout {
            visible: root.mp3Expanded
            Layout.fillWidth: true
            spacing: 12

            // Barra superior do Player Expandido
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    height: 24
                    Layout.preferredWidth: mp3BadgeRow.implicitWidth + 20
                    radius: 7
                    color: Theme.alpha(root.accentColor, 0.22)
                    border.width: 1
                    border.color: Theme.alpha(root.accentColor, 0.5)

                    RowLayout {
                        id: mp3BadgeRow
                        anchors.centerIn: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6
                        Text {
                            text: SystemState.mediaIcon
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: root.accentColor
                        }
                        Text {
                            text: SystemState.mediaBadgeText
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Capa Grande Centralizada (No modo MP3 do sistema vira um disco de vinil/CD redondo!)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 200

                ClippingRectangle {
                    width: 192
                    height: 192
                    anchors.centerIn: parent
                    radius: SystemState.isLocalMp3 ? 96 : 20
                    color: Theme.cardBg
                    border.width: 2
                    border.color: Theme.alpha(root.accentColor, 0.6)
                    scale: SystemState.isPlaying ? 1.0 : 0.95
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on radius { NumberAnimation { duration: 220 } }

                    Image {
                        id: mp3CoverImg
                        anchors.fill: parent
                        source: SystemState.localCoverFile !== "" ? SystemState.localCoverFile : SystemState.trackArtUrl
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: mp3CoverImg.status !== Image.Ready
                        text: SystemState.mediaIcon
                        font.family: Config.fontFamily
                        font.pixelSize: 64
                        color: root.accentColor
                    }

                    // Centro de Vinil quando for MP3 do Sistema
                    Rectangle {
                        visible: SystemState.isLocalMp3 && mp3CoverImg.status === Image.Ready
                        width: 34; height: 34; radius: 17
                        anchors.centerIn: parent
                        color: Theme.surfaceContainerLowest
                        border.width: 3
                        border.color: root.accentColor
                    }
                }
            }

            // Informações Centralizadas da Faixa
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: SystemState.trackTitle
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeLarge + 1
                    font.bold: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: SystemState.trackArtist || SystemState.playerIdentity
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeNormal
                    font.weight: Font.Medium
                    color: root.accentColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    visible: SystemState.trackAlbum !== ""
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: SystemState.trackAlbum
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // =====================================================================
        // BARRA DE PROGRESSO INTERATIVA (Arrastável)
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Rectangle {
                id: progTrack
                Layout.fillWidth: true
                Layout.preferredHeight: root.mp3Expanded ? 10 : 8
                radius: height / 2
                color: Theme.surfaceContainerHighest

                Rectangle {
                    width: parent.width * Math.min(1, Math.max(0, SystemState.trackPosition / SystemState.trackLength))
                    height: parent.height
                    radius: height / 2
                    color: root.accentColor
                    Behavior on width { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    id: seekMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function seekToMouse(mx) {
                        const ratio = Math.max(0, Math.min(1, mx / progTrack.width));
                        const targetPos = ratio * SystemState.trackLength;
                        SystemState.mediaSeek(targetPos);
                    }
                    onPressed: (mouse) => {
                        SystemState.isSeekingMedia = true;
                        seekToMouse(mouse.x);
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed) seekToMouse(mouse.x);
                    }
                    onReleased: SystemState.finishMediaSeek()
                    onCanceled: SystemState.finishMediaSeek()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: SystemState.formatTime(SystemState.trackPosition)
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: SystemState.formatTime(SystemState.trackLength)
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                }
            }
        }

        // =====================================================================
        // CONTROLES DE FAIXA (No modo MP3 inclui Shuffle e Repeat)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: root.mp3Expanded ? 16 : 18

            Item { Layout.fillWidth: true }

            // Botão Shuffle (Visível no modo MP3)
            Item {
                visible: root.mp3Expanded
                width: 32; height: 32
                Text {
                    anchors.centerIn: parent
                    text: "󰒝"
                    font.family: Config.fontFamily
                    font.pixelSize: 17
                    color: root.shuffleActive ? root.accentColor : (shufHover.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                }
                MouseArea {
                    id: shufHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.shuffleActive = !root.shuffleActive;
                        Quickshell.execDetached(["playerctl", "-p", SystemState.targetPlayerctlName, "shuffle", "Toggle"]);
                    }
                }
            }

            // Anterior (ou Voltar 10s quando canGoNext == false)
            Rectangle {
                width: 38; height: 38; radius: 19
                color: prevHover.containsMouse ? Theme.cardHoverBg : Theme.cardBg
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.35)
                Text {
                    anchors.centerIn: parent
                    text: SystemState.canSkipTrack ? "󰒮" : "󰴪"
                    font.family: Config.fontFamily
                    font.pixelSize: 18
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: prevHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemState.mediaPrev()
                }
            }

            // Play / Pause
            Rectangle {
                width: root.mp3Expanded ? 54 : 48
                height: root.mp3Expanded ? 54 : 48
                radius: width / 2
                color: root.accentColor
                border.width: Config.borderWidth
                border.color: Theme.alpha(Theme.textPrimary, 0.25)
                scale: playHover.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: SystemState.isPlaying ? "󰏤" : "󰐊"
                    font.family: Config.fontFamily
                    font.pixelSize: root.mp3Expanded ? 24 : 22
                    color: Theme.contrastColor(root.accentColor)
                }
                MouseArea {
                    id: playHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemState.mediaPlayPause()
                }
            }

            // Próxima (ou Pular 10s quando canGoNext == false)
            Rectangle {
                width: 38; height: 38; radius: 19
                color: nextHover.containsMouse ? Theme.cardHoverBg : Theme.cardBg
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.35)
                Text {
                    anchors.centerIn: parent
                    text: SystemState.canSkipTrack ? "󰒭" : "󰵱"
                    font.family: Config.fontFamily
                    font.pixelSize: 18
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: nextHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemState.mediaNext()
                }
            }

            // Botão Repeat (Visível no modo MP3)
            Item {
                visible: root.mp3Expanded
                width: 32; height: 32
                Text {
                    anchors.centerIn: parent
                    text: "󰑖"
                    font.family: Config.fontFamily
                    font.pixelSize: 17
                    color: root.repeatActive ? root.accentColor : (repHover.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                }
                MouseArea {
                    id: repHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.repeatActive = !root.repeatActive;
                        Quickshell.execDetached(["playerctl", "-p", SystemState.targetPlayerctlName, "loop", root.repeatActive ? "Playlist" : "None"]);
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // =====================================================================
        // SLIDER DE VOLUME DEDICADO ESTILO MP3 / IPOD (Visível no modo MP3)
        // =====================================================================
        RowLayout {
            visible: root.mp3Expanded
            Layout.fillWidth: true
            Layout.rightMargin: 22 // margem para não encostar na meia-lua do canto
            Layout.leftMargin: 6
            Layout.topMargin: 2
            spacing: 10

            Text {
                text: "󰕿"
                font.family: Config.fontFamily
                font.pixelSize: 14
                color: Theme.textSecondary
            }

            Rectangle {
                id: mp3VolBar
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Theme.surfaceContainerHighest
                clip: true

                Rectangle {
                    width: parent.width * Math.min(1, Math.max(0, SystemState.volume / 100))
                    height: parent.height
                    radius: 4
                    color: root.accentColor
                    Behavior on width { enabled: !mp3VolMouse.pressed; NumberAnimation { duration: 70 } }
                }

                MouseArea {
                    id: mp3VolMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function setVolFromX(mx) {
                        const ratio = Math.max(0, Math.min(1, mx / mp3VolBar.width));
                        SystemState.setVolume(Math.round(ratio * 100));
                    }
                    onPressed: (mouse) => setVolFromX(mouse.x)
                    onPositionChanged: (mouse) => { if (pressed) setVolFromX(mouse.x); }
                }
            }

            Text {
                text: "󰕾"
                font.family: Config.fontFamily
                font.pixelSize: 14
                color: root.accentColor
            }
        }
    }
}
