import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."

RowLayout {
    id: root
    spacing: 10

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name || "";
            if (n.includes("window") || n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
            }
        }
    }

    Component.onCompleted: {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function switchWorkspace(target) {
        if (Hyprland.usingLua) {
            if (typeof target === "number") {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${target} })`);
            } else {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${target}" })`);
            }
        } else {
            Hyprland.dispatch("workspace " + target);
        }
    }

    // =========================================================================
    // 1. BOTÃO DE PESQUISA / LAUNCHER (Único botão de busca, na esquerda)
    // =========================================================================
    Rectangle {
        id: launcherBtn
        readonly property bool isOpen: SystemState.activePopup === "spotlight"

        Layout.preferredWidth: 40
        Layout.preferredHeight: Config.pillHeight
        radius: Config.pillRadius
        color: isOpen ? Theme.primary : (launcherMouse.containsMouse ? Theme.pillHoverBg : Theme.pillBg)
        border.width: Config.borderWidth
        border.color: isOpen ? Theme.activeBorder : Theme.widgetBorder

        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: "󰣇"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeIcon + 2
            color: launcherBtn.isOpen ? Theme.contrastColor(Theme.primary) : Theme.primary
        }

        MouseArea {
            id: launcherMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: () => {
                SystemState.toggleDrawer("spotlight", launcherBtn);
            }
        }
    }

    // =========================================================================
    // 2. WORKSPACES DO HYPRLAND (Sem nome de aplicação ao lado)
    // =========================================================================
    Rectangle {
        Layout.preferredHeight: Config.pillHeight
        Layout.preferredWidth: wsRow.implicitWidth + 18
        radius: Config.pillRadius
        color: Theme.pillBg
        border.width: Config.borderWidth
        border.color: Theme.widgetBorder

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0) {
                    root.switchWorkspace("e-1");
                } else if (wheel.angleDelta.y < 0) {
                    root.switchWorkspace("e+1");
                }
            }
        }

        Row {
            id: wsRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: 7

                delegate: Item {
                    id: wsItem
                    readonly property int wsId: index + 1
                    readonly property bool isFocused: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id === wsId) : (wsId === 1)
                    readonly property bool isOccupied: {
                        const list = Hyprland.workspaces.values;
                        for (let i = 0; i < list.length; i++) {
                            const ws = list[i];
                            if (ws && ws.id === wsId) {
                                const hasTls = ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0;
                                const hasWins = ws.lastIpcObject && ws.lastIpcObject.windows > 0;
                                return hasTls || hasWins;
                            }
                        }
                        return false;
                    }

                    width: isFocused ? 34 : (isOccupied ? 20 : 10)
                    height: 22

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: isFocused ? 22 : (isOccupied ? 13 : 8)
                        radius: height / 2
                        color: {
                            if (isFocused) return Theme.primary;
                            if (wsMouse.containsMouse) return Theme.primaryFixed;
                            if (isOccupied) return Theme.tertiary;
                            return Theme.alpha(Theme.textSecondary, 0.22);
                        }
                        border.width: (!isFocused && isOccupied) ? 1 : 0
                        border.color: Theme.alpha(Theme.textPrimary, 0.35)

                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 180 } }

                        Text {
                            anchors.centerIn: parent
                            visible: wsItem.isFocused
                            opacity: wsItem.isFocused ? 1.0 : 0.0
                            text: wsItem.wsId.toString()
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.contrastColor(Theme.primary)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchWorkspace(wsItem.wsId)
                    }
                }
            }
        }
    }
}
