import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import ".."

DrawerBase {
    id: root
    popupName: "notifications"
    targetWidth: 350
    contentHeight: notifCol.implicitHeight
    accentColor: SystemState.dndEnabled ? Theme.error : Theme.primary

    ColumnLayout {
        id: notifCol
        width: parent.width
        spacing: 10

        // Cabeçalho + Contador Nativo + Botão Limpar Tudo
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: SystemState.dndEnabled ? "󰂛" : "󰂚"
                font.family: Config.fontFamily
                font.pixelSize: 17
                color: SystemState.dndEnabled ? Theme.error : Theme.primary
            }

            Text {
                text: "Notificações"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeLarge
                font.bold: true
                color: Theme.textPrimary
            }

            Rectangle {
                height: 20
                width: cntTxt.implicitWidth + 10
                radius: 6
                color: SystemState.notifCount > 0 ? Theme.primary : Theme.surfaceContainerHighest

                Text {
                    id: cntTxt
                    anchors.centerIn: parent
                    text: SystemState.notifCount.toString()
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: SystemState.notifCount > 0 ? Theme.contrastColor(Theme.primary) : Theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            // Botão Limpar Todas (visível quando há notificações)
            Rectangle {
                visible: SystemState.notifCount > 0
                height: 24
                width: clrTxt.implicitWidth + 14
                radius: 7
                color: clrHover.containsMouse ? Theme.cardHoverBg : Theme.cardBg
                border.width: Config.borderWidth
                border.color: Theme.widgetBorder

                Text {
                    id: clrTxt
                    anchors.centerIn: parent
                    text: "󰎟 Limpar"
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.secondary
                }

                MouseArea {
                    id: clrHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemState.clearAllNotifications()
                }
            }
        }

        // Sliders Compactos de Brilho e Filtro Noturno
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 82
            radius: 12
            color: Theme.cardBg
            border.width: Config.borderWidth
            border.color: Theme.widgetBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Slider 1: Brilho da Tela
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰃠"
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        color: Theme.primary
                    }

                    Text {
                        Layout.preferredWidth: 50
                        text: "Brilho"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle {
                        id: briTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        radius: 8
                        color: Theme.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.min(1, Math.max(0.05, SystemState.brightness / 100))
                            height: parent.height
                            radius: 8
                            color: Theme.primary
                            Behavior on width { NumberAnimation { duration: 70 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function setBriFromX(mx) {
                                const ratio = Math.max(0.05, Math.min(1, mx / briTrack.width));
                                SystemState.setBrightness(Math.round(ratio * 100));
                            }
                            onPressed: (mouse) => setBriFromX(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) setBriFromX(mouse.x); }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: SystemState.brightness + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.primary
                    }
                }

                // Slider 2: Filtro Noturno / Night Shift
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰖔"
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        color: SystemState.nightLightEnabled ? Theme.tertiary : Theme.textSecondary
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SystemState.toggleNightLight()
                        }
                    }

                    Text {
                        Layout.preferredWidth: 50
                        text: "Noturno"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle {
                        id: nlTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        radius: 8
                        color: Theme.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.min(1, Math.max(0, SystemState.nightLightStrength / 100))
                            height: parent.height
                            radius: 8
                            color: Theme.tertiary
                            Behavior on width { NumberAnimation { duration: 70 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function setNlFromX(mx) {
                                const ratio = Math.max(0, Math.min(1, mx / nlTrack.width));
                                SystemState.setNightLightStrength(Math.round(ratio * 100));
                            }
                            onPressed: (mouse) => setNlFromX(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) setNlFromX(mouse.x); }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: SystemState.nightLightEnabled ? (SystemState.nightLightStrength + "%") : "Off"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: SystemState.nightLightEnabled ? Theme.tertiary : Theme.textSecondary
                    }
                }
            }
        }

        // Toggle Modo Não Perturbe (Foco)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 10
            color: SystemState.dndEnabled ? Theme.alpha(Theme.errorContainer, 0.72) : Theme.cardBg
            border.width: Config.borderWidth
            border.color: SystemState.dndEnabled ? Theme.alpha(Theme.error, 0.45) : Theme.widgetBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: SystemState.dndEnabled ? "󰂛" : "󰂚"
                    font.family: Config.fontFamily
                    font.pixelSize: 15
                    color: SystemState.dndEnabled ? Theme.error : Theme.primary
                }

                Text {
                    Layout.fillWidth: true
                    text: "Modo Não Perturbe (Foco)"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: true
                    color: Theme.textPrimary
                }

                Rectangle {
                    width: 44; height: 22; radius: 11
                    color: SystemState.dndEnabled ? Theme.error : Theme.surfaceContainerHighest

                    Rectangle {
                        width: 16; height: 16; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        x: SystemState.dndEnabled ? parent.width - width - 3 : 3
                        color: SystemState.dndEnabled ? Theme.onError : Theme.textSecondary
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: SystemState.toggleDnd()
            }
        }

        // =========================================================================
        // LISTA NATIVA DE NOTIFICAÇÕES NO QUICKSHELL (Sem depender do SwayNC!)
        // =========================================================================
        Rectangle {
            visible: SystemState.notifCount === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: 12
            color: Theme.cardBg
            border.width: Config.borderWidth
            border.color: Theme.widgetBorder

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂜"
                    font.family: Config.fontFamily
                    font.pixelSize: 20
                    color: Theme.textSecondary
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Nenhuma notificação pendente"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                }
            }
        }

        Item {
            visible: SystemState.notifCount > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(250, notifListView.contentHeight)

            ListView {
                id: notifListView
                anchors.fill: parent
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                model: SystemState.notificationsList

                delegate: Rectangle {
                    id: notifCard
                    width: notifListView.width - (notifListView.contentHeight > 250 ? 8 : 0)
                    height: cardInner.implicitHeight + 18
                    radius: 12
                    color: cardBodyMouse.containsMouse ? Theme.cardHoverBg : Theme.cardBg
                    border.width: Config.borderWidth
                    border.color: cardBodyMouse.containsMouse
                        ? Theme.primary
                        : (modelData.urgency === NotificationUrgency.Critical
                            ? Theme.alpha(Theme.error, 0.55)
                            : Theme.widgetBorder)

                    // Clicar no card da notificação abre/foca o app correspondente (ex: Telegram)
                    MouseArea {
                        id: cardBodyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemState.activateNotification(modelData)
                    }

                    ColumnLayout {
                        id: cardInner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 9
                        spacing: 5

                        // Linha 1: App + Fechar individual
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            IconImage {
                                id: notifAppIcon
                                width: 15; height: 15
                                visible: (modelData.appIcon || "") !== "" && source !== ""
                                source: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
                            }

                            Text {
                                visible: !notifAppIcon.visible
                                text: "󰂚"
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                color: Theme.primary
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.appName || "Sistema"
                                font.family: Config.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.primary
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: 20; height: 20; radius: 6
                                color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: closeMouse.containsMouse ? Theme.error : Theme.textSecondary
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SystemState.dismissNotification(modelData)
                                }
                            }
                        }

                        // Linha 2: Título (Summary)
                        Text {
                            visible: (modelData.summary || "") !== ""
                            Layout.fillWidth: true
                            text: modelData.summary || ""
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeNormal
                            font.bold: true
                            color: Theme.textPrimary
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        // Linha 3: Corpo (Body)
                        Text {
                            visible: (modelData.body || "") !== ""
                            Layout.fillWidth: true
                            text: (modelData.body || "").replace(/<[^>]*>/g, "")
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeSmall
                            color: Theme.textSecondary
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        // Linha 4: Ações da Notificação (se houver)
                        RowLayout {
                            visible: modelData.actions && modelData.actions.length > 0
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: modelData.actions

                                delegate: Rectangle {
                                    height: 24
                                    Layout.fillWidth: true
                                    radius: 6
                                    color: actHover.containsMouse ? Theme.primary : Theme.surfaceContainerHighest

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text || "Abrir"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: actHover.containsMouse ? Theme.contrastColor(Theme.primary) : Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: actHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Indicador de scroll para a lista de notificações
            Rectangle {
                visible: notifListView.contentHeight > 250
                anchors.right: parent.right
                width: 4
                radius: 2
                color: Theme.alpha(Theme.primary, 0.45)
                y: notifListView.visibleArea.yPosition * notifListView.height
                height: Math.max(18, notifListView.visibleArea.heightRatio * notifListView.height)
            }
        }
    }
}
