import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".."

// Banner flutuante nativo de notificação (estilo macOS) com janela Wayland de tamanho fixo
// (evita redimensionar o buffer Wayland a cada frame, eliminando 100% do stutter!)
PanelWindow {
    id: root

    readonly property var notif: SystemState.latestToast
    readonly property bool hasToast: notif !== null && !SystemState.dndEnabled && SystemState.activePopup !== "notifications"

    // Mantém os dados da última notificação cacheados durante a animação de saída
    // para que o card não encolha/apague o texto no meio do fade-out
    property string cachedAppName: "Notificação"
    property string cachedSummary: ""
    property string cachedBody: ""
    property string cachedIcon: ""
    property var cachedNotifObj: null

    onNotifChanged: {
        if (notif !== null) {
            cachedNotifObj = notif;
            cachedAppName = notif.appName || "Notificação";
            cachedSummary = notif.summary || "";
            cachedBody = (notif.body || "").replace(/<[^>]*>/g, "");
            cachedIcon = notif.appIcon || "";
        }
    }

    property real progress: hasToast ? 1.0 : 0.0
    Behavior on progress {
        NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
    }

    visible: progress > 0.01

    WlrLayershell.namespace: "quickshell-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: Config.isTop
        bottom: !Config.isTop
        right: true
    }

    margins {
        top: Config.isTop ? (Config.barHeight + Config.marginVertical + 8) : 0
        bottom: !Config.isTop ? (Config.barHeight + Config.marginVertical + 8) : 0
        right: Config.marginHorizontal
    }

    // Tamanho estático da superfície Wayland (zero reconfiguração de buffer durante a animação!)
    implicitWidth: 348
    implicitHeight: 200
    color: "transparent"

    // Região clicável restrita apenas ao card visível
    mask: Region {
        item: root.hasToast ? toastBox : emptyMask
    }

    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    Rectangle {
        id: toastBox
        width: 340
        height: toastCol.implicitHeight + 22
        anchors.right: parent.right
        y: Config.isTop
            ? (-18 * (1.0 - root.progress))
            : (parent.height - height + (18 * (1.0 - root.progress)))
        opacity: root.progress
        scale: 0.96 + (0.04 * root.progress)
        radius: Config.popupRadius
        color: toastBodyMouse.containsMouse
            ? Theme.alpha(Theme.surfaceContainerLow, Math.max(0.78, Config.popupOpacity + 0.44))
            : Theme.alpha(Theme.surfaceContainerLowest, Math.max(0.72, Config.popupOpacity + 0.38))
        border.width: Config.borderWidth
        border.color: toastBodyMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.primary, 0.45)
        clip: true

        // Clicar no corpo do toast abre/foca o aplicativo (ex: Telegram)
        MouseArea {
            id: toastBodyMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SystemState.activateNotification(root.notif || root.cachedNotifObj)
        }

        // Gradiente Spotlight suave no banner de notificação
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Config.isTop ? Theme.alpha(Theme.primary, 0.28) : Theme.alpha(Theme.tertiary, 0.06)
                }
                GradientStop {
                    position: 1.0
                    color: !Config.isTop ? Theme.alpha(Theme.primary, 0.28) : Theme.alpha(Theme.tertiary, 0.06)
                }
            }
        }

        ColumnLayout {
            id: toastCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 11
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                IconImage {
                    id: tIcon
                    width: 16; height: 16
                    visible: root.cachedIcon !== "" && source !== ""
                    source: root.cachedIcon !== "" ? Quickshell.iconPath(root.cachedIcon, true) : ""
                }

                Text {
                    visible: !tIcon.visible
                    text: "󰂚"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Theme.primary
                }

                Text {
                    Layout.fillWidth: true
                    text: root.cachedAppName
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.primary
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 20; height: 20; radius: 6
                    color: closeToastMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: closeToastMouse.containsMouse ? Theme.error : Theme.textSecondary
                    }

                    MouseArea {
                        id: closeToastMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemState.dismissToast()
                    }
                }
            }

            Text {
                visible: root.cachedSummary !== ""
                Layout.fillWidth: true
                text: root.cachedSummary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeNormal
                font.bold: true
                color: Theme.textPrimary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                visible: root.cachedBody !== ""
                Layout.fillWidth: true
                text: root.cachedBody
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeSmall
                color: Theme.textSecondary
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }
}
