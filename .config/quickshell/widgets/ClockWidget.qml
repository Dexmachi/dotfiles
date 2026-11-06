import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    id: root

    property string formattedDateTime: ""

    function updateClock() {
        const now = new Date();
        const days = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];
        const dName = days[now.getDay()];
        const day = String(now.getDate()).padStart(2, "0");
        const month = String(now.getMonth() + 1).padStart(2, "0");
        const hh = String(now.getHours()).padStart(2, "0");
        const mm = String(now.getMinutes()).padStart(2, "0");

        root.formattedDateTime = `${dName} ${day}/${month} ${hh}:${mm}`;
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateClock()
    }

    Layout.preferredHeight: Config.pillHeight
    Layout.preferredWidth: clockLabel.implicitWidth + 10

    Text {
        id: clockLabel
        anchors.centerIn: parent
        text: root.formattedDateTime
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeNormal
        font.weight: Font.Bold
        color: SystemState.activePopup === "calendar" ? Theme.primary : Theme.textPrimary
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SystemState.toggleDrawer("calendar", root)
    }
}
