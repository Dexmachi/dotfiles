import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Rectangle {
    id: root

    readonly property bool connected: SystemState.btIsConnected
    readonly property bool isOpen: SystemState.activePopup === "bluetooth"

    Layout.preferredHeight: Config.pillHeight
    Layout.preferredWidth: connected ? Math.min(310, btRow.implicitWidth + 26) : 40
    radius: Config.pillRadius
    color: Theme.pillBg
    border.width: Config.borderWidth
    border.color: connected
        ? Theme.alpha(Theme.btConnectedGreen, 0.28)
        : (isOpen ? Theme.activeBorder : Theme.widgetBorder)
    clip: true

    Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // Brilho verde de baixo para cima quando conectado
    Rectangle {
        visible: root.connected
        anchors.fill: parent
        radius: Config.pillRadius
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                position: 0.45
                color: Theme.alpha(Theme.btConnectedGreen, 0.10)
            }
            GradientStop {
                position: 1.0
                color: Theme.alpha(Theme.btConnectedGreen, 0.42)
            }
        }
    }

    // Feixe verde na borda inferior quando conectado
    Rectangle {
        visible: root.connected
        width: parent.width * 0.65
        height: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        radius: 1
        color: Theme.btConnectedGreen
    }

    RowLayout {
        id: btRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.connected
                ? SystemState.btConnectedTypeIcon
                : (SystemState.btEnabled ? "󰂯" : "󰂲")
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeIcon
            color: root.connected
                ? Theme.btConnectedGreen
                : (SystemState.btEnabled ? Theme.primary : Theme.textSecondary)
        }

        Text {
            visible: root.connected
            Layout.maximumWidth: 240
            text: "conectado a " + SystemState.btConnectedName
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
        onClicked: SystemState.toggleDrawer("bluetooth", root)
    }
}
