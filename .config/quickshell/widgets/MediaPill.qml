import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

// Pílula de Multimídia na barra (borda fina padrão de 1px; a borda grossa fica exclusiva no widget MediaPopup)
Rectangle {
    id: root

    readonly property bool active: SystemState.hasMedia
    readonly property bool isOpen: SystemState.activePopup === "media"
    readonly property color spotColor: SystemState.mediaCoverColor

    onIsOpenChanged: {
        if (isOpen) {
            const mapped = root.mapToItem(null, 0, 0);
            SystemState.drawerCenterX = mapped.x + (root.width / 2) + Config.marginHorizontal;
            SystemState.drawerButtonWidth = Math.max(40, root.width);
        }
    }

    Layout.preferredHeight: Config.pillHeight
    Layout.preferredWidth: active
        ? Math.min(330, Math.max(150, contentRow.implicitWidth + 28))
        : 150
    radius: Config.pillRadius
    color: Theme.alpha(Theme.surfaceContainerLowest, 0.65)
    border.width: Config.borderWidth
    border.color: (SystemState.isPlaying || isOpen)
        ? Theme.alpha(spotColor, 0.35)
        : Theme.widgetBorder
    clip: true

    Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 220 } }

    // Efeito Spotlight vindo de cima (ou de baixo) na cor luminosa da capa
    Rectangle {
        anchors.fill: parent
        radius: Config.pillRadius
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Config.isTop
                    ? Theme.alpha(root.spotColor, (root.isOpen ? 0.48 : (SystemState.isPlaying ? 0.38 : 0.18)))
                    : "transparent"
            }
            GradientStop {
                position: 0.58
                color: Theme.alpha(root.spotColor, 0.06)
            }
            GradientStop {
                position: 1.0
                color: !Config.isTop
                    ? Theme.alpha(root.spotColor, (root.isOpen ? 0.48 : (SystemState.isPlaying ? 0.38 : 0.18)))
                    : "transparent"
            }
        }
    }

    // Feixe de luz concentrado na origem do Spotlight
    Rectangle {
        width: parent.width * 0.65
        height: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: Config.isTop ? parent.top : undefined
        anchors.bottom: !Config.isTop ? parent.bottom : undefined
        radius: 1
        color: root.spotColor
        opacity: SystemState.isPlaying || root.isOpen ? 0.9 : 0.45
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        width: Math.min(parent.width - 20, implicitWidth)
        spacing: 9

        Text {
            text: SystemState.mediaIcon
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeIcon
            color: root.spotColor
        }

        // Apenas o nome da música ou vídeo tocando
        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: 250
            text: root.active ? SystemState.trackTitle : "Sem reprodução"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeNormal
            font.weight: Font.DemiBold
            color: Theme.textPrimary
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SystemState.toggleDrawer("media", root)
    }
}
