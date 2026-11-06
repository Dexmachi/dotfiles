import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

DrawerBase {
    id: root
    popupName: "bluetooth"
    targetWidth: 320
    contentHeight: btCol.implicitHeight
    accentColor: SystemState.btIsConnected ? Theme.btConnectedGreen : Theme.primary

    ColumnLayout {
        id: btCol
        width: parent.width
        spacing: 10

        // Cabeçalho Bluetooth (o ícone da esquerda liga/desliga o Bluetooth)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 34; height: 34; radius: 10
                color: SystemState.btEnabled
                    ? (SystemState.btIsConnected ? Theme.btConnectedGreen : Theme.primary)
                    : Theme.surfaceContainerHighest
                scale: btIconMouse.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: SystemState.btEnabled ? "󰂯" : "󰂲"
                    font.family: Config.fontFamily
                    font.pixelSize: 16
                    color: SystemState.btEnabled ? Theme.contrastColor(parent.color) : Theme.textSecondary
                }

                MouseArea {
                    id: btIconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemState.toggleBluetoothPower()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: "Bluetooth"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeLarge
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: SystemState.btIsConnected
                        ? ("Conectado a " + SystemState.btConnectedName)
                        : (SystemState.btEnabled ? "Ativo • Clique no ícone p/ desligar" : "Desligado • Clique no ícone p/ ligar")
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    color: SystemState.btIsConnected ? Theme.btConnectedGreen : Theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // Lista de Dispositivos Pareados
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: SystemState.btDevices

                delegate: Rectangle {
                    readonly property bool isConn: modelData.connected
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 10
                    color: isConn ? Theme.alpha(Theme.btConnectedGreen, 0.16) : (devHover.containsMouse ? Theme.cardHoverBg : Theme.cardBg)
                    border.width: 1
                    border.color: isConn ? Theme.alpha(Theme.btConnectedGreen, 0.55) : Theme.alpha(Theme.outlineVariant, 0.25)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: SystemState.getBtDeviceIcon(modelData)
                            font.family: Config.fontFamily
                            font.pixelSize: 16
                            color: isConn ? Theme.btConnectedGreen : Theme.primary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || modelData.deviceName || modelData.address
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeNormal
                                font.bold: true
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                            }
                            Text {
                                text: isConn
                                    ? ("Conectado" + (modelData.batteryAvailable ? " • 󰁹 " + Math.round(modelData.battery * 100) + "%" : ""))
                                    : "Pareado"
                                font.family: Config.fontFamily
                                font.pixelSize: 10
                                color: isConn ? Theme.btConnectedGreen : Theme.textSecondary
                            }
                        }

                        Item {
                            Layout.preferredWidth: connTxt.implicitWidth + 6
                            Layout.preferredHeight: 24

                            Text {
                                id: connTxt
                                anchors.centerIn: parent
                                text: isConn ? "Desconectar" : "Conectar"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: isConn
                                    ? (connMouse.containsMouse ? Qt.lighter(Theme.error, 1.15) : Theme.error)
                                    : (connMouse.containsMouse ? Theme.textPrimary : Theme.primary)
                                scale: connMouse.containsMouse ? 1.06 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            MouseArea {
                                id: connMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemState.toggleBtDeviceConnection(modelData)
                            }
                        }
                    }

                    MouseArea {
                        id: devHover
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                    }
                }
            }
        }

        // Botão Abrir Gerenciador Completo (Blueman)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 9
            color: bmHover.containsMouse ? Theme.cardHoverBg : Theme.cardBg
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.3)

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "󰒓"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Theme.primary
                }
                Text {
                    text: "Gerenciador Bluetooth Completo"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
            }

            MouseArea {
                id: bmHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SystemState.closePopups();
                    Quickshell.execDetached(["blueman-manager"]);
                }
            }
        }
    }
}
