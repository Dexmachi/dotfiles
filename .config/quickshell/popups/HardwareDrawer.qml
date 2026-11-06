import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

DrawerBase {
    id: root
    popupName: "hardware"
    altPopupName: "battery"
    targetWidth: 320
    contentHeight: hwCol.implicitHeight
    accentColor: Theme.primary

    ColumnLayout {
        id: hwCol
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: "󰻠"
                font.family: Config.fontFamily
                font.pixelSize: 17
                color: Theme.primary
            }
            Text {
                text: "Consumo & Recursos"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeLarge
                font.bold: true
                color: Theme.textPrimary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "󰔏 " + SystemState.cpuTemp + "°C"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeSmall
                font.bold: true
                color: SystemState.cpuTemp > 80 ? Theme.error : Theme.primary
            }
        }

        // Card de Barras de Consumo (CPU, RAM, Disco, Bateria)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 172
            radius: 12
            color: Theme.cardBg
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.3)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Bateria do Notebook
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: SystemState.batteryIcon + " Bateria (" + (SystemState.batteryCharging ? "Carregando" : (SystemState.batteryWatts + " W")) + ")"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemState.batteryPercent + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: SystemState.batteryCharging
                                ? Theme.btConnectedGreen
                                : (SystemState.batteryPercent <= 20 ? Theme.error : Theme.tertiary)
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 7
                        radius: 3.5
                        color: Theme.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * Math.min(1, SystemState.batteryPercent / 100)
                            height: parent.height
                            radius: 3.5
                            color: SystemState.batteryCharging
                                ? Theme.btConnectedGreen
                                : (SystemState.batteryPercent <= 20 ? Theme.error : Theme.tertiary)
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }

                // CPU
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Processador (CPU)"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemState.cpuUsage + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.primary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 7
                        radius: 3.5
                        color: Theme.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * Math.min(1, SystemState.cpuUsage / 100)
                            height: parent.height
                            radius: 3.5
                            color: Theme.primary
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }

                // RAM
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Memória RAM (" + SystemState.ramUsedText + ")"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemState.ramUsage + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.secondary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 7
                        radius: 3.5
                        color: Theme.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * Math.min(1, SystemState.ramUsage / 100)
                            height: parent.height
                            radius: 3.5
                            color: Theme.secondary
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }

                // Disco (/home)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Armazenamento /home (" + SystemState.diskUsedText + ")"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemState.diskUsage + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.tertiary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 7
                        radius: 3.5
                        color: Theme.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * Math.min(1, SystemState.diskUsage / 100)
                            height: parent.height
                            radius: 3.5
                            color: Theme.tertiary
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }
            }
        }

        // Seletor de Perfil de Energia
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { id: "power-saver", label: "󰌪 Eco" },
                    { id: "balanced", label: "󰾅 Normal" },
                    { id: "performance", label: "󰓅 Turbo" }
                ]
                delegate: Rectangle {
                    readonly property bool isAct: SystemState.powerProfile === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 8
                    color: isAct ? Theme.primary : Theme.cardBg
                    border.width: 1
                    border.color: isAct ? Theme.primary : Theme.alpha(Theme.outlineVariant, 0.3)

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: isAct ? Theme.onPrimary : Theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemState.setPowerProfile(modelData.id)
                    }
                }
            }
        }

        // Slider Ao Vivo de Opacidade / Glassmorphism dos Popups (Config.popupOpacity)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 10
            color: Theme.cardBg
            border.width: Config.borderWidth
            border.color: Theme.alpha(Theme.outlineVariant, 0.3)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "󰂵"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Theme.primary
                }

                Text {
                    text: "Opacidade Glass"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.textPrimary
                }

                Rectangle {
                    id: opTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14
                    radius: 7
                    color: Theme.surfaceContainerHighest
                    clip: true

                    Rectangle {
                        width: parent.width * Math.min(1, Math.max(0.1, Config.popupOpacity))
                        height: parent.height
                        radius: 7
                        color: Theme.primary
                        Behavior on width { NumberAnimation { duration: 60 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        function setOpFromX(mx) {
                            const ratio = Math.max(0.15, Math.min(0.90, mx / opTrack.width));
                            Config.popupOpacity = Math.round(ratio * 100) / 100;
                            Config.cardOpacity = Math.max(0.12, Math.round((ratio * 0.72) * 100) / 100);
                        }
                        onPressed: (mouse) => setOpFromX(mouse.x)
                        onPositionChanged: (mouse) => { if (pressed) setOpFromX(mouse.x); }
                    }
                }

                Text {
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Config.popupOpacity * 100) + "%"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.primary
                }
            }
        }

        // Alternar Posição da Barra (Topo / Base)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 9
            color: posHover.containsMouse ? Theme.cardHoverBg : Theme.cardBg
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.3)

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: Config.isTop ? "󰁅" : "󰁝"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Theme.primary
                }
                Text {
                    text: Config.isTop ? "Mover Barra para a Base" : "Mover Barra para o Topo"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
            }

            MouseArea {
                id: posHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.toggleBarPosition()
            }
        }
    }
}
