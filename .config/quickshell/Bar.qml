import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "widgets"

PanelWindow {
    id: root

    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: Config.isTop
        bottom: !Config.isTop
        left: true
        right: true
    }

    margins {
        top: Config.isTop ? Config.marginVertical : 0
        bottom: !Config.isTop ? Config.marginVertical : 0
        left: Config.marginHorizontal
        right: Config.marginHorizontal
    }

    implicitHeight: Config.barHeight
    color: "transparent"

    // Container Principal Flutuante (Glassmorphism translúcido + Bordas mais largas e transparentes)
    Rectangle {
        id: barSurface
        anchors.fill: parent
        radius: Config.barRadius
        color: Theme.glassBg
        border.width: Config.borderWidth
        border.color: Theme.glassBorder

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        // Seção Esquerda: Botão de Busca/Launcher + Workspaces (sem o nome da aplicação ativa)
        Workspaces {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
        }

        // Seção Central: Ilha de Música (Spotlight) + Bluetooth Central (Brilho Verde)
        RowLayout {
            anchors.centerIn: parent
            spacing: 10

            MediaPill {}
            BluetoothPill {}
        }

        // Seção Direita: Tray Retrátil + Áudio + Consumo + Notificações + Data/Hora
        StatusCluster {
            id: rightSection
            barWindow: root
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
