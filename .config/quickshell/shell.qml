//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "popups"

ShellRoot {
    id: root

    // Barra Principal Flutuante
    Bar {}

    // Gavetas Individuais por Tipo (estendendo diretamente de cada botão)
    MediaPopup {}
    BluetoothDrawer {}
    AudioDrawer {}
    HardwareDrawer {}
    NotificationDrawer {}
    NotificationToast {}
    CalendarPopup {}
    SpotlightPopup {}
    QuickToolsPopup {}

    // IPC Handler para atalhos de teclado do Hyprland (substituindo 100% do Rofi)
    IpcHandler {
        target: "bar"

        function toggleSpotlight(): void {
            SystemState.toggleToolPopup("spotlight");
        }

        function toggleStartMenu(): void {
            SystemState.togglePopup("spotlight");
        }

        function toggleAudio(): void {
            SystemState.togglePopup("audio");
        }

        function toggleBluetooth(): void {
            SystemState.togglePopup("bluetooth");
        }

        function toggleHardware(): void {
            SystemState.togglePopup("hardware");
        }

        function toggleNotifications(): void {
            SystemState.togglePopup("notifications");
        }

        function toggleCalendar(): void {
            SystemState.togglePopup("calendar");
        }

        function toggleMedia(): void {
            SystemState.togglePopup("media");
        }

        function toggleMediaExpanded(): void {
            SystemState.toggleMediaExpanded();
        }

        function togglePosition(): void {
            Config.toggleBarPosition();
        }

        function toggleClipboard(): void {
            SystemState.toggleToolPopup("clipboard");
        }

        function toggleScreenshot(): void {
            SystemState.toggleToolPopup("screenshot");
        }

        function toggleKeybindings(): void {
            SystemState.toggleToolPopup("keybindings");
        }

        function toggleRbw(): void {
            SystemState.toggleToolPopup("rbw");
        }

        function toggleSidepad(): void {
            SystemState.toggleToolPopup("sidepad");
        }

        function toggleNightLight(): void {
            SystemState.toggleNightLight();
        }
    }
}
