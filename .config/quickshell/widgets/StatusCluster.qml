import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import ".."

RowLayout {
    id: root
    property var barWindow: null
    spacing: 10

    // =========================================================================
    // 1. SYSTEM TRAY RECOLHÍVEL (Fechado por padrão, expande com animação)
    // =========================================================================
    Rectangle {
        id: trayBox
        visible: SystemTray.items.values.length > 0
        Layout.preferredHeight: Config.pillHeight
        Layout.preferredWidth: SystemState.trayExpanded
            ? (trayItemsRow.implicitWidth + 48)
            : 34
        radius: Config.pillRadius
        color: Theme.pillBg
        border.width: Config.borderWidth
        border.color: SystemState.trayExpanded ? Theme.activeBorder : Theme.widgetBorder
        clip: true

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // Botão de Expandir / Recolher o Tray
            Item {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 24

                Text {
                    anchors.centerIn: parent
                    text: SystemState.trayExpanded ? "󰅂" : "󰅁"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeIcon
                    color: Theme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemState.trayExpanded = !SystemState.trayExpanded
                }
            }

            // Ícones da Bandeja (visíveis quando expandido)
            Row {
                id: trayItemsRow
                visible: SystemState.trayExpanded
                opacity: SystemState.trayExpanded ? 1.0 : 0.0
                spacing: 8
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Repeater {
                    model: SystemTray.items.values

                    delegate: Rectangle {
                        id: trayDelegate
                        width: 24
                        height: 24
                        radius: 7
                        color: trayMouse.containsMouse ? Theme.alpha(Theme.primary, 0.22) : "transparent"

                        IconImage {
                            anchors.centerIn: parent
                            width: 17
                            height: 17
                            source: modelData.icon
                        }

                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: (mouse) => {
                                const pt = trayDelegate.mapToItem(null, 0, Config.isTop ? trayDelegate.height : 0);
                                if (mouse.button === Qt.MiddleButton) {
                                    modelData.activate();
                                } else if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton) {
                                    if (modelData.hasMenu && root.barWindow) {
                                        modelData.display(root.barWindow, pt.x, pt.y);
                                    } else {
                                        modelData.activate();
                                    }
                                }
                            }
                            onWheel: (wheel) => {
                                modelData.scroll(wheel.angleDelta.y, false);
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. WIDGET DE ÁUDIO (Abre a gaveta exclusiva AudioDrawer)
    // =========================================================================
    Rectangle {
        id: audioPill
        readonly property bool isOpen: SystemState.activePopup === "audio"

        Layout.preferredHeight: Config.pillHeight
        Layout.preferredWidth: volRow.implicitWidth + 22
        radius: Config.pillRadius
        color: isOpen ? Theme.alpha(Theme.primaryContainer, 0.72) : (volMouse.containsMouse ? Theme.pillHoverBg : Theme.pillBg)
        border.width: Config.borderWidth
        border.color: isOpen
            ? Theme.activeBorder
            : (SystemState.muted ? Theme.alpha(Theme.error, 0.35) : Theme.widgetBorder)

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: volRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                text: SystemState.volumeIcon
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeIcon
                color: SystemState.muted ? Theme.error : Theme.primary
            }

            Text {
                text: SystemState.muted ? "Mudo" : (SystemState.volume + "%")
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeNormal
                font.weight: Font.Bold
                color: SystemState.muted ? Theme.error : Theme.textPrimary
            }
        }

        MouseArea {
            id: volMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                    SystemState.toggleMute();
                } else {
                    SystemState.toggleDrawer("audio", audioPill);
                }
            }
            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0) {
                    SystemState.adjustVolume(5);
                } else if (wheel.angleDelta.y < 0) {
                    SystemState.adjustVolume(-5);
                }
            }
        }
    }

    // =========================================================================
    // 3. WIDGET DE CONSUMO / HARDWARE (Abre a gaveta exclusiva HardwareDrawer)
    // =========================================================================
    Rectangle {
        id: hwPill
        readonly property bool isOpen: SystemState.activePopup === "hardware"

        Layout.preferredHeight: Config.pillHeight
        Layout.preferredWidth: hwRow.implicitWidth + 22
        radius: Config.pillRadius
        color: isOpen ? Theme.alpha(Theme.primaryContainer, 0.72) : (hwMouse.containsMouse ? Theme.pillHoverBg : Theme.pillBg)
        border.width: Config.borderWidth
        border.color: isOpen ? Theme.activeBorder : Theme.widgetBorder

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: hwRow
            anchors.centerIn: parent
            spacing: 10

            // CPU
            RowLayout {
                spacing: 5
                Text {
                    text: "󰻠"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeIcon - 1
                    color: Theme.primary
                }
                Text {
                    text: SystemState.cpuUsage + "%"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeNormal
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                }
            }

            // RAM
            RowLayout {
                spacing: 5
                Text {
                    text: "󰍛"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeIcon - 1
                    color: Theme.secondary
                }
                Text {
                    text: SystemState.ramUsage + "%"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeNormal
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                }
            }
        }

        MouseArea {
            id: hwMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SystemState.toggleDrawer("hardware", hwPill)
        }
    }

    // =========================================================================
    // 3B. BOTÃO DE BATERIA DO NOTEBOOK (Acompanha % e estado de carga; clique abre Recursos/Energia)
    // =========================================================================
    Rectangle {
        id: batPill
        visible: SystemState.hasBattery
        readonly property bool isOpen: SystemState.activePopup === "battery"
        readonly property bool isLow: !SystemState.batteryCharging && SystemState.batteryPercent <= 20
        readonly property color batColor: SystemState.batteryCharging
            ? Theme.btConnectedGreen
            : (isLow ? Theme.error : Theme.tertiary)

        Layout.preferredHeight: Config.pillHeight
        Layout.preferredWidth: batRow.implicitWidth + 22
        radius: Config.pillRadius
        color: isOpen ? Theme.alpha(Theme.primaryContainer, 0.72) : (batMouse.containsMouse ? Theme.pillHoverBg : Theme.pillBg)
        border.width: Config.borderWidth
        border.color: isOpen
            ? Theme.activeBorder
            : (SystemState.batteryCharging
                ? Theme.alpha(Theme.btConnectedGreen, 0.45)
                : (isLow ? Theme.alpha(Theme.error, 0.55) : Theme.widgetBorder))

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: batRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: SystemState.batteryIcon
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeIcon
                color: batPill.batColor
            }

            Text {
                text: SystemState.batteryPercent + "%"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeNormal
                font.weight: Font.Bold
                color: batPill.isLow ? Theme.error : Theme.textPrimary
            }
        }

        MouseArea {
            id: batMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    SystemState.cyclePowerProfile();
                } else {
                    SystemState.toggleDrawer("battery", batPill);
                }
            }
        }
    }

    // =========================================================================
    // 4. WIDGET DE NOTIFICAÇÕES (Abre a gaveta exclusiva NotificationDrawer)
    // =========================================================================
    Rectangle {
        id: notifPill
        readonly property bool isOpen: SystemState.activePopup === "notifications"

        Layout.preferredWidth: 38
        Layout.preferredHeight: Config.pillHeight
        radius: Config.pillRadius
        color: isOpen ? Theme.alpha(Theme.primaryContainer, 0.72) : (notifMouse.containsMouse ? Theme.pillHoverBg : Theme.pillBg)
        border.width: Config.borderWidth
        border.color: isOpen ? Theme.activeBorder : Theme.widgetBorder

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: SystemState.dndEnabled ? "󰂛" : "󰂚"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeIcon
            color: SystemState.dndEnabled ? Theme.error : Theme.primary
        }

        MouseArea {
            id: notifMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SystemState.toggleDrawer("notifications", notifPill)
        }
    }

    // =========================================================================
    // 5. DATA E HORA PURA (Sem caixa, abre a gaveta CalendarDrawer)
    // =========================================================================
    ClockWidget {}
}
