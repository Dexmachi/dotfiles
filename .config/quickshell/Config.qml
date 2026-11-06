pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Posição da barra: "top" ou "bottom"
    property string barPosition: "top"
    readonly property bool isTop: barPosition === "top"

    // Dimensões maiores e confortáveis
    property int barHeight: 46
    property int pillHeight: 34
    property int marginHorizontal: 8
    property int marginVertical: 6
    property int barRadius: 12
    property int pillRadius: 12
    property int popupRadius: 16

    // Borda padrão fina (1px) para a barra, pills e demais widgets
    property real borderWidth: 1

    // Borda grossa simétrica (10px em todos os lados) e bem transparente EXCLUSIVA do widget de Multimídia (MediaPopup)
    property int mediaWidgetBorderSide: 8
    property int mediaWidgetBorderTopBottom: 8

    // Tipografia maior e legível
    property string fontFamily: "Maple Mono NF CN"
    property int fontSizeSmall: 12
    property int fontSizeNormal: 13
    property int fontSizeLarge: 15
    property int fontSizeIcon: 16

    // Opacidade Glassmorphism configurável (reduzida nos popups e cards para o blur destacar de verdade)
    property real glassOpacity: 0.50
    property real pillOpacity: 0.46
    property real popupOpacity: 0.30
    property real cardOpacity: 0.36
    property real mediaBorderOpacity: 0.10

    function toggleBarPosition() {
        root.barPosition = (root.barPosition === "top") ? "bottom" : "top";
    }
}
