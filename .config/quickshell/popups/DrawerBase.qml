import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    required property string popupName
    property string altPopupName: ""
    property int targetWidth: 340
    property int contentHeight: 220
    property color accentColor: Theme.primary
    property bool showSpotlight: false
    property bool mp3Expanded: SystemState.mediaExpanded
    default property alias drawerContent: innerItem.data

    readonly property bool isOpen: SystemState.activePopup === popupName || (altPopupName !== "" && SystemState.activePopup === altPopupName)
    property real progress: isOpen ? 1.0 : 0.0
    property real lockedCenterX: SystemState.drawerCenterX
    property real lockedBtnWidth: SystemState.drawerButtonWidth

    readonly property int sideMargin: showSpotlight ? Config.mediaWidgetBorderSide : 0
    readonly property int topBotMargin: showSpotlight ? Config.mediaWidgetBorderTopBottom : 0

    onIsOpenChanged: {
        if (isOpen) {
            lockedCenterX = SystemState.drawerCenterX;
            lockedBtnWidth = SystemState.drawerButtonWidth;
        }
    }

    Connections {
        target: SystemState
        function onActivePopupChanged() {
            if (root.isOpen) {
                root.lockedCenterX = SystemState.drawerCenterX;
                root.lockedBtnWidth = SystemState.drawerButtonWidth;
            }
        }
    }

    Behavior on progress {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    visible: progress > 0.01

    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Clicar fora retrai a gaveta
    MouseArea {
        anchors.fill: parent
        onClicked: SystemState.closePopups()
    }

    // Container da Gaveta
    Rectangle {
        id: drawerBox

        readonly property real rawFullH: root.contentHeight + 30 + (root.topBotMargin * 2)
        property real animatedFullH: rawFullH
        property real animatedW: root.targetWidth + (root.sideMargin * 2)

        Behavior on animatedFullH {
            enabled: root.progress > 0.98
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on animatedW {
            enabled: root.progress > 0.98
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        width: animatedW
        height: Math.max(0, animatedFullH * root.progress)

        x: {
            const rawX = root.lockedCenterX - (width / 2);
            const minX = Config.marginHorizontal;
            const maxX = Math.max(minX, root.width - width - Config.marginHorizontal);
            return Math.max(minX, Math.min(maxX, rawX));
        }

        y: Config.isTop
            ? (Config.barHeight + Config.marginVertical + 4)
            : (root.height - Config.barHeight - Config.marginVertical - height - 4)

        // Raio externo concêntrico: innerBody.radius + espessura da borda
        radius: Config.popupRadius + root.sideMargin
        // Preenche de forma contínua com 10% alpha (sem border.width oco do Qt que descola nos cantos!)
        color: root.showSpotlight ? Theme.alpha(root.accentColor, Config.mediaBorderOpacity) : "transparent"
        border.width: 0
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Corpo Interno da Gaveta
        Rectangle {
            id: innerBody
            anchors.fill: parent
            anchors.leftMargin: root.sideMargin
            anchors.rightMargin: root.sideMargin
            anchors.topMargin: root.topBotMargin
            anchors.bottomMargin: root.topBotMargin
            radius: Config.popupRadius
            color: Theme.popupBg
            border.width: root.showSpotlight ? 0 : Config.borderWidth
            border.color: Theme.alpha(root.accentColor, 0.25)
            clip: true

            // Efeito Spotlight no Multimídia
            Rectangle {
                visible: root.showSpotlight
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Config.isTop ? Theme.alpha(root.accentColor, 0.38) : "transparent"
                    }
                    GradientStop {
                        position: 0.55
                        color: Theme.alpha(root.accentColor, 0.06)
                    }
                    GradientStop {
                        position: 1.0
                        color: !Config.isTop ? Theme.alpha(root.accentColor, 0.38) : "transparent"
                    }
                }
            }

            // Aba luminosa conectando com o botão clicado
            Rectangle {
                width: Math.min(parent.width * 0.6, Math.max(36, root.lockedBtnWidth * 0.8))
                height: 3
                radius: 1.5
                color: root.accentColor
                opacity: 0.85
                anchors.top: Config.isTop ? parent.top : undefined
                anchors.bottom: !Config.isTop ? parent.bottom : undefined
                x: {
                    const localBtnX = root.lockedCenterX - drawerBox.x - root.sideMargin - (width / 2);
                    return Math.max(16, Math.min(innerBody.width - width - 16, localBtnX));
                }
            }

            // Conteúdo interno ancorado ao topo (ou base)
            Item {
                id: innerItem
                width: innerBody.width - 28
                height: root.contentHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: Config.isTop ? parent.top : undefined
                anchors.topMargin: Config.isTop ? 15 : 0
                anchors.bottom: !Config.isTop ? parent.bottom : undefined
                anchors.bottomMargin: !Config.isTop ? 15 : 0
                opacity: root.progress
            }

            // =================================================================
            // BOTÃO EM MEIA-LUA ESTILO APPLE DENTRO DO PRÓPRIO DRAWER (innerBody)
            // (Concêntrico com a curva interna do drawer, com 5px de margem do canto)
            // =================================================================
            Item {
                id: crescentHandle
                visible: root.showSpotlight
                width: 36
                height: 36
                anchors.right: parent.right
                anchors.bottom: Config.isTop ? parent.bottom : undefined
                anchors.top: !Config.isTop ? parent.top : undefined
                opacity: root.progress

                Canvas {
                    id: arcCanvas
                    anchors.fill: parent
                    property bool hovered: grabMouse.containsMouse || grabMouse.pressed

                    onHoveredChanged: requestPaint()
                    Component.onCompleted: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);

                        // Centro concêntrico com o raio do innerBody (18px), com 5px de margem interna (r = 13px)
                        const cornerR = Config.popupRadius;
                        const marginInside = 5.5;
                        const r = Math.max(8, cornerR - marginInside);
                        const cx = width - cornerR;
                        const cy = Config.isTop ? (height - cornerR) : cornerR;

                        ctx.beginPath();
                        if (Config.isTop) {
                            // Arco em meia-lua acompanhando o canto inferior direito interno
                            ctx.arc(cx, cy, r, 0.08 * Math.PI, 0.42 * Math.PI, false);
                        } else {
                            // Arco em meia-lua acompanhando o canto superior direito interno
                            ctx.arc(cx, cy, r, -0.42 * Math.PI, -0.08 * Math.PI, false);
                        }

                        ctx.lineWidth = hovered ? 4.5 : 3.8;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = hovered ? "rgba(225, 230, 238, 0.95)" : "rgba(165, 172, 184, 0.80)";
                        ctx.stroke();
                    }
                }

                MouseArea {
                    id: grabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Config.isTop ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor

                    property real startX: 0
                    property real startY: 0
                    property bool toggledDuringDrag: false

                    onPressed: (mouse) => {
                        startX = mouse.x;
                        startY = mouse.y;
                        toggledDuringDrag = false;
                    }

                    onPositionChanged: (mouse) => {
                        if (!pressed || toggledDuringDrag) return;
                        const dx = mouse.x - startX;
                        const dy = Config.isTop ? (mouse.y - startY) : (startY - mouse.y);
                        const pullScore = dx + dy;

                        if (!root.mp3Expanded && pullScore > 16) {
                            SystemState.mediaExpanded = true;
                            toggledDuringDrag = true;
                        } else if (root.mp3Expanded && pullScore < -16) {
                            SystemState.mediaExpanded = false;
                            toggledDuringDrag = true;
                        }
                    }

                    onReleased: () => {
                        if (!toggledDuringDrag) {
                            SystemState.mediaExpanded = !SystemState.mediaExpanded;
                        }
                    }
                }
            }
        }
    }
}
