import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

DrawerBase {
    id: root
    popupName: "audio"
    targetWidth: 350
    contentHeight: audioCol.implicitHeight
    accentColor: Theme.primary

    property string activeSection: "apps" // "apps", "sinks", "sources"

    ColumnLayout {
        id: audioCol
        width: parent.width
        spacing: 10

        // Cabeçalho + Abas Compactas (Apps | Saídas | Entradas)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: SystemState.volumeIcon
                font.family: Config.fontFamily
                font.pixelSize: 18
                color: Theme.primary
            }

            Text {
                text: "Áudio"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeLarge
                font.bold: true
                color: Theme.textPrimary
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 4
                Repeater {
                    model: [
                        { id: "apps", label: "Apps (" + (SystemState.audioApps.length + SystemState.micApps.length) + ")" },
                        { id: "sinks", label: "Saídas" },
                        { id: "sources", label: "Mics" }
                    ]
                    delegate: Rectangle {
                        width: secTxt.implicitWidth + 12
                        height: 24
                        radius: 7
                        color: root.activeSection === modelData.id ? Theme.primary : Theme.surfaceContainerHighest

                        Text {
                            id: secTxt
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: root.activeSection === modelData.id ? Theme.contrastColor(Theme.primary) : Theme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeSection = modelData.id
                        }
                    }
                }
            }
        }

        // =====================================================================
        // SLIDERS PRINCIPAIS COMPACTOS (Saída Master + Microfone Master)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            radius: 12
            color: Theme.cardBg
            border.width: Config.borderWidth
            border.color: Theme.widgetBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Linha 1: Saída Principal
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 26; height: 24; radius: 6
                        color: SystemState.muted ? Theme.errorContainer : Theme.surfaceContainerHighest
                        Text {
                            anchors.centerIn: parent
                            text: SystemState.volumeIcon
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            color: SystemState.muted ? Theme.error : Theme.primary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SystemState.toggleMute()
                        }
                    }

                    Text {
                        Layout.preferredWidth: 44
                        text: "Saída"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle {
                        id: outTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        radius: 8
                        color: Theme.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.min(1, Math.max(0, SystemState.volume / 100))
                            height: parent.height
                            radius: 8
                            color: SystemState.muted ? Theme.outline : Theme.primary
                            Behavior on width { NumberAnimation { duration: 70 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function setFromX(mx) {
                                const ratio = Math.max(0, Math.min(1, mx / outTrack.width));
                                SystemState.setVolume(Math.round(ratio * 100));
                            }
                            onPressed: (mouse) => setFromX(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) setFromX(mouse.x); }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        text: SystemState.muted ? "Mudo" : (SystemState.volume + "%")
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: SystemState.muted ? Theme.error : Theme.primary
                    }
                }

                // Linha 2: Entrada Principal (Microfone)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 26; height: 24; radius: 6
                        color: SystemState.micMuted ? Theme.errorContainer : Theme.surfaceContainerHighest
                        Text {
                            anchors.centerIn: parent
                            text: SystemState.micIcon
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            color: SystemState.micMuted ? Theme.error : Theme.secondary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SystemState.toggleMicMute()
                        }
                    }

                    Text {
                        Layout.preferredWidth: 44
                        text: "Mic"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle {
                        id: micTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        radius: 8
                        color: Theme.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.min(1, Math.max(0, SystemState.micVolume / 100))
                            height: parent.height
                            radius: 8
                            color: SystemState.micMuted ? Theme.outline : Theme.secondary
                            Behavior on width { NumberAnimation { duration: 70 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function setMicFromX(mx) {
                                const ratio = Math.max(0, Math.min(1, mx / micTrack.width));
                                SystemState.setMicVolume(Math.round(ratio * 100));
                            }
                            onPressed: (mouse) => setMicFromX(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) setMicFromX(mouse.x); }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        text: SystemState.micMuted ? "Mudo" : (SystemState.micVolume + "%")
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: SystemState.micMuted ? Theme.error : Theme.secondary
                    }
                }
            }
        }

        // =====================================================================
        // SEÇÃO 1: MIXER DE APLICATIVOS (Sliders individuais por app)
        // =====================================================================
        ColumnLayout {
            visible: root.activeSection === "apps"
            Layout.fillWidth: true
            spacing: 6

            Text {
                visible: SystemState.audioApps.length === 0 && SystemState.micApps.length === 0
                text: "Nenhum aplicativo reproduzindo ou capturando áudio no momento"
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                Layout.bottomMargin: 6
            }

            // Apps de Saída (Spotify, Zen, Jogos, etc.)
            Repeater {
                model: SystemState.audioApps

                delegate: Rectangle {
                    id: appDelegate
                    property int liveVol: modelData.volume
                    Connections {
                        target: SystemState
                        function onAudioAppsChanged() {
                            if (!appMouseArea.pressed) appDelegate.liveVol = modelData.volume;
                        }
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 10
                    color: Theme.cardBg
                    border.width: 1
                    border.color: Theme.widgetBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.muted ? Theme.errorContainer : Theme.surfaceContainerHighest
                            Text {
                                anchors.centerIn: parent
                                text: modelData.muted ? "󰝟" : "󰕾"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: modelData.muted ? Theme.error : Theme.primary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemState.toggleAppMute(modelData.index)
                            }
                        }

                        Text {
                            Layout.preferredWidth: 85
                            text: modelData.name
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: appSlider
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14
                            radius: 7
                            color: Theme.surfaceContainerHighest
                            clip: true

                            Rectangle {
                                width: parent.width * Math.min(1, Math.max(0, appDelegate.liveVol / 100))
                                height: parent.height
                                radius: 7
                                color: modelData.muted ? Theme.outline : Theme.primary
                                Behavior on width { enabled: !appMouseArea.pressed; NumberAnimation { duration: 70 } }
                            }

                            MouseArea {
                                id: appMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                function updateAppVol(mx) {
                                    const ratio = Math.max(0, Math.min(1, mx / appSlider.width));
                                    const v = Math.round(ratio * 100);
                                    appDelegate.liveVol = v;
                                    SystemState.setAppVolume(modelData.index, v);
                                }
                                onPressed: (mouse) => {
                                    SystemState.isDraggingAudio = true;
                                    updateAppVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) updateAppVol(mouse.x);
                                }
                                onReleased: SystemState.finishAudioDrag()
                                onCanceled: SystemState.finishAudioDrag()
                            }
                        }

                        Text {
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                            text: modelData.muted ? "Mudo" : (appDelegate.liveVol + "%")
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: modelData.muted ? Theme.error : Theme.textSecondary
                        }
                    }
                }
            }

            // Apps de Microfone (Discord, etc.)
            Repeater {
                model: SystemState.micApps

                delegate: Rectangle {
                    id: micAppDelegate
                    property int liveVol: modelData.volume
                    Connections {
                        target: SystemState
                        function onMicAppsChanged() {
                            if (!micAppMouseArea.pressed) micAppDelegate.liveVol = modelData.volume;
                        }
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 10
                    color: Theme.cardBg
                    border.width: 1
                    border.color: Theme.widgetBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.muted ? Theme.errorContainer : Theme.surfaceContainerHighest
                            Text {
                                anchors.centerIn: parent
                                text: modelData.muted ? "󰍭" : "󰍬"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: modelData.muted ? Theme.error : Theme.secondary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SystemState.toggleMicAppMute(modelData.index)
                            }
                        }

                        Text {
                            Layout.preferredWidth: 85
                            text: modelData.name + " (Mic)"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            id: micAppSlider
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14
                            radius: 7
                            color: Theme.surfaceContainerHighest
                            clip: true

                            Rectangle {
                                width: parent.width * Math.min(1, Math.max(0, micAppDelegate.liveVol / 100))
                                height: parent.height
                                radius: 7
                                color: modelData.muted ? Theme.outline : Theme.secondary
                                Behavior on width { enabled: !micAppMouseArea.pressed; NumberAnimation { duration: 70 } }
                            }

                            MouseArea {
                                id: micAppMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                function updateMicAppVol(mx) {
                                    const ratio = Math.max(0, Math.min(1, mx / micAppSlider.width));
                                    const v = Math.round(ratio * 100);
                                    micAppDelegate.liveVol = v;
                                    SystemState.setMicAppVolume(modelData.index, v);
                                }
                                onPressed: (mouse) => {
                                    SystemState.isDraggingAudio = true;
                                    updateMicAppVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) updateMicAppVol(mouse.x);
                                }
                                onReleased: SystemState.finishAudioDrag()
                                onCanceled: SystemState.finishAudioDrag()
                            }
                        }

                        Text {
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                            text: modelData.muted ? "Mudo" : (micAppDelegate.liveVol + "%")
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: modelData.muted ? Theme.error : Theme.textSecondary
                        }
                    }
                }
            }
        }

        // =====================================================================
        // SEÇÃO 2: DISPOSITIVOS DE SAÍDA (Sinks + Slider de Volume)
        // =====================================================================
        ColumnLayout {
            visible: root.activeSection === "sinks"
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: SystemState.audioSinks

                delegate: Rectangle {
                    id: sinkDelegate
                    property int liveVol: modelData.volume
                    Connections {
                        target: SystemState
                        function onAudioSinksChanged() {
                            if (!sinkMouseArea.pressed) sinkDelegate.liveVol = modelData.volume;
                        }
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    radius: 10
                    color: modelData.isDefault ? Theme.alpha(Theme.primaryContainer, 0.72) : Theme.cardBg
                    border.width: Config.borderWidth
                    border.color: modelData.isDefault ? Theme.activeBorder : Theme.widgetBorder

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: modelData.isDefault ? "󰄬" : "󰓃"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: modelData.isDefault ? Theme.primary : Theme.textSecondary
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.description
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.bold: modelData.isDefault
                                color: Theme.textPrimary
                                elide: Text.ElideRight

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SystemState.setSink(modelData.name)
                                }
                            }

                            Text {
                                text: sinkDelegate.liveVol + "%"
                                font.family: Config.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.primary
                            }
                        }

                        Rectangle {
                            id: sinkVolBar
                            Layout.fillWidth: true
                            Layout.preferredHeight: 12
                            radius: 6
                            color: Theme.surfaceContainerHighest
                            clip: true

                            Rectangle {
                                width: parent.width * Math.min(1, Math.max(0, sinkDelegate.liveVol / 100))
                                height: parent.height
                                radius: 6
                                color: Theme.primary
                            }

                            MouseArea {
                                id: sinkMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                function updateSinkVol(mx) {
                                    const ratio = Math.max(0, Math.min(1, mx / sinkVolBar.width));
                                    const v = Math.round(ratio * 100);
                                    sinkDelegate.liveVol = v;
                                    SystemState.setSinkVolume(modelData.name, v);
                                }
                                onPressed: (mouse) => {
                                    SystemState.isDraggingAudio = true;
                                    updateSinkVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => { if (pressed) updateSinkVol(mouse.x); }
                                onReleased: SystemState.finishAudioDrag()
                                onCanceled: SystemState.finishAudioDrag()
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // SEÇÃO 3: DISPOSITIVOS DE ENTRADA (Microfones + Slider de Ganho)
        // =====================================================================
        ColumnLayout {
            visible: root.activeSection === "sources"
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: SystemState.audioSources

                delegate: Rectangle {
                    id: srcDelegate
                    property int liveVol: modelData.volume
                    Connections {
                        target: SystemState
                        function onAudioSourcesChanged() {
                            if (!srcMouseArea.pressed) srcDelegate.liveVol = modelData.volume;
                        }
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    radius: 10
                    color: modelData.isDefault ? Theme.alpha(Theme.primaryContainer, 0.72) : Theme.cardBg
                    border.width: Config.borderWidth
                    border.color: modelData.isDefault ? Theme.activeBorder : Theme.widgetBorder

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: modelData.isDefault ? "󰄬" : "󰍬"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                color: modelData.isDefault ? Theme.secondary : Theme.textSecondary
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.description
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.bold: modelData.isDefault
                                color: Theme.textPrimary
                                elide: Text.ElideRight

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SystemState.setSource(modelData.name)
                                }
                            }

                            Text {
                                text: srcDelegate.liveVol + "%"
                                font.family: Config.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.secondary
                            }
                        }

                        Rectangle {
                            id: srcVolBar
                            Layout.fillWidth: true
                            Layout.preferredHeight: 12
                            radius: 6
                            color: Theme.surfaceContainerHighest
                            clip: true

                            Rectangle {
                                width: parent.width * Math.min(1, Math.max(0, srcDelegate.liveVol / 100))
                                height: parent.height
                                radius: 6
                                color: Theme.secondary
                            }

                            MouseArea {
                                id: srcMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                function updateSrcVol(mx) {
                                    const ratio = Math.max(0, Math.min(1, mx / srcVolBar.width));
                                    const v = Math.round(ratio * 100);
                                    srcDelegate.liveVol = v;
                                    SystemState.setSourceVolume(modelData.name, v);
                                }
                                onPressed: (mouse) => {
                                    SystemState.isDraggingAudio = true;
                                    updateSrcVol(mouse.x);
                                }
                                onPositionChanged: (mouse) => { if (pressed) updateSrcVol(mouse.x); }
                                onReleased: SystemState.finishAudioDrag()
                                onCanceled: SystemState.finishAudioDrag()
                            }
                        }
                    }
                }
            }
        }
    }
}
