pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        onFileChanged: this.reload()

        JsonAdapter {
            id: palette
            property string background: "#121413"
            property string surface: "#121413"
            property string surface_dim: "#121413"
            property string surface_bright: "#383a38"
            property string surface_container_lowest: "#0c0f0d"
            property string surface_container_low: "#1a1c1b"
            property string surface_container: "#1e201f"
            property string surface_container_high: "#282a29"
            property string surface_container_highest: "#333534"
            property string surface_variant: "#414844"
            property string on_background: "#e2e3e0"
            property string on_surface: "#e2e3e0"
            property string on_surface_variant: "#c1c8c3"
            property string primary: "#a5d0bd"
            property string primary_container: "#1c4436"
            property string on_primary: "#0d372a"
            property string on_primary_container: "#afdac6"
            property string primary_fixed: "#c1ecd8"
            property string primary_fixed_dim: "#a5d0bd"
            property string on_primary_fixed: "#002116"
            property string secondary: "#b9cac1"
            property string secondary_container: "#3d4c45"
            property string on_secondary: "#25342d"
            property string on_secondary_container: "#d7e8de"
            property string secondary_fixed: "#d5e7dd"
            property string tertiary: "#bcc5ea"
            property string tertiary_container: "#333c5a"
            property string on_tertiary: "#262f4c"
            property string on_tertiary_container: "#c7cff5"
            property string tertiary_fixed: "#dbe1ff"
            property string error: "#ffb4ab"
            property string error_container: "#93000a"
            property string on_error: "#690005"
            property string outline: "#8b938e"
            property string outline_variant: "#414844"
            property string inverse_surface: "#e2e3e0"
            property string inverse_primary: "#3f6657"
        }
    }

    // Tokens base do Matugen
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color surfaceBright: palette.surface_bright
    readonly property color surfaceContainerLowest: palette.surface_container_lowest
    readonly property color surfaceContainerLow: palette.surface_container_low
    readonly property color surfaceContainer: palette.surface_container
    readonly property color surfaceContainerHigh: palette.surface_container_high
    readonly property color surfaceContainerHighest: palette.surface_container_highest
    readonly property color surfaceVariant: palette.surface_variant

    // Tipografia clara e nítida baseada no Matugen
    readonly property color textPrimary: Qt.lighter(Qt.color(palette.primary_fixed), 1.12)
    readonly property color textSecondary: Qt.color(palette.secondary_fixed)
    readonly property color textMuted: Qt.lighter(Qt.color(palette.on_surface_variant), 1.15)

    readonly property color onBackground: textPrimary
    readonly property color onSurface: textPrimary
    readonly property color onSurfaceVariant: textSecondary

    readonly property color primary: palette.primary
    readonly property color primaryFixed: palette.primary_fixed
    readonly property color primaryContainer: palette.primary_container
    readonly property color onPrimary: palette.on_primary_fixed
    readonly property color onPrimaryContainer: textPrimary
    readonly property color onPrimaryFixed: palette.on_primary_fixed

    readonly property color secondary: palette.secondary
    readonly property color secondaryContainer: palette.secondary_container
    readonly property color onSecondary: palette.on_secondary
    readonly property color onSecondaryContainer: textPrimary

    readonly property color tertiary: palette.tertiary
    readonly property color tertiaryContainer: palette.tertiary_container
    readonly property color onTertiary: palette.on_tertiary
    readonly property color onTertiaryContainer: textPrimary

    readonly property color error: palette.error
    readonly property color errorContainer: palette.error_container
    readonly property color onError: palette.on_error

    readonly property color outline: palette.outline
    readonly property color outlineVariant: palette.outline_variant
    readonly property color inversePrimary: palette.inverse_primary

    // Cor de brilho verde para Bluetooth conectado
    readonly property color btConnectedGreen: "#34d399"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Preserva a cor real da capa (permitindo variações fortes de tom, saturação e brilho),
    // garantindo apenas que nunca fique 100% preta (luminosidade mínima de 0.28)
    function ensureLuminousLight(rawColor) {
        const c = Qt.color(rawColor);
        if (c.hslHue < 0 || c.hslSaturation < 0.05) {
            // Capa monocromática / cinza / P&B: mantém o tom neutro sem puxar para a cor do tema, só evita o preto puro
            return Qt.hsla(0.0, 0.0, Math.max(0.38, c.hslLightness), 1.0);
        }
        const h = c.hslHue;
        const s = Math.min(1.0, c.hslSaturation * 1.15);
        const l = Math.max(0.28, Math.min(0.88, c.hslLightness < 0.28 ? (0.28 + c.hslLightness * 0.5) : c.hslLightness));
        return Qt.hsla(h, s, l, 1.0);
    }

    // Retorna sempre a cor de ícone/texto com maior contraste contra um fundo específico
    function contrastColor(bgColor) {
        const c = Qt.color(bgColor);
        const lum = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
        return lum > 0.50 ? Qt.darker(onPrimaryFixed, 1.2) : textPrimary;
    }

    // Fundos Glassmorphism translúcidos baseados no Matugen (configuráveis via Config.qml)
    readonly property color glassBg: alpha(surfaceContainerLowest, Config.glassOpacity)
    readonly property color pillBg: alpha(surfaceContainerLow, Config.pillOpacity)
    readonly property color pillHoverBg: alpha(surfaceContainer, Math.min(0.85, Config.pillOpacity + 0.16))
    readonly property color popupBg: alpha(surfaceContainerLowest, Config.popupOpacity)
    readonly property color cardBg: alpha(surfaceContainerLow, Config.cardOpacity)
    readonly property color cardHoverBg: alpha(surfaceContainerHigh, Math.min(0.85, Config.cardOpacity + 0.16))

    // Bordas mais largas e MAIS TRANSPARENTES que o corpo (chanfro de vidro)
    readonly property color glassBorder: alpha(primaryFixed, 0.16)
    readonly property color widgetBorder: alpha(primaryFixed, 0.14)
    readonly property color activeBorder: alpha(primary, 0.32)
}
