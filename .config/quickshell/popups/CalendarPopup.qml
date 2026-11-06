import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

DrawerBase {
    id: root
    popupName: "calendar"
    targetWidth: 310
    contentHeight: calCol.implicitHeight
    accentColor: Theme.primary

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()
    property var calendarCells: []

    readonly property var monthNames: [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]
    readonly property var weekHeaders: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

    function rebuildCalendar() {
        const now = new Date();
        const firstDay = new Date(viewYear, viewMonth, 1).getDay();
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        const daysInPrev = new Date(viewYear, viewMonth, 0).getDate();

        const cells = [];
        for (let i = firstDay - 1; i >= 0; i--) {
            cells.push({ day: daysInPrev - i, inMonth: false, isToday: false });
        }
        for (let d = 1; d <= daysInMonth; d++) {
            const isT = (d === now.getDate() && viewMonth === now.getMonth() && viewYear === now.getFullYear());
            cells.push({ day: d, inMonth: true, isToday: isT });
        }
        let nextDay = 1;
        while (cells.length < 42) {
            cells.push({ day: nextDay++, inMonth: false, isToday: false });
        }
        root.calendarCells = cells;
    }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear--; }
        else { viewMonth--; }
        rebuildCalendar();
    }

    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++; }
        else { viewMonth++; }
        rebuildCalendar();
    }

    function goToday() {
        const now = new Date();
        viewYear = now.getFullYear();
        viewMonth = now.getMonth();
        rebuildCalendar();
    }

    Component.onCompleted: rebuildCalendar()
    onIsOpenChanged: { if (isOpen) goToday(); }

    ColumnLayout {
        id: calCol
        width: parent.width
        spacing: 12

        // Cabeçalho com Mês/Ano e Navegação
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Text {
                    text: root.monthNames[root.viewMonth] + " " + root.viewYear
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeLarge
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: "Calendário"
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    color: Theme.primary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 26; height: 26; radius: 8
                color: prevM.containsMouse ? Theme.cardHoverBg : Theme.cardBg
                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: prevM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.prevMonth()
                }
            }

            Rectangle {
                width: 44; height: 26; radius: 8
                color: todayM.containsMouse ? Theme.primary : Theme.cardBg
                Text {
                    anchors.centerIn: parent
                    text: "Hoje"
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: todayM.containsMouse ? Theme.onPrimary : Theme.primary
                }
                MouseArea {
                    id: todayM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToday()
                }
            }

            Rectangle {
                width: 26; height: 26; radius: 8
                color: nextM.containsMouse ? Theme.cardHoverBg : Theme.cardBg
                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: nextM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextMonth()
                }
            }
        }

        // Cabeçalho de Dias da Semana
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 4

            Repeater {
                model: root.weekHeaders
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: index === 0 || index === 6 ? Theme.primary : Theme.textSecondary
                    }
                }
            }
        }

        // Grade dos 42 dias
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: root.calendarCells
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 9
                    color: modelData.isToday
                        ? Theme.primary
                        : (dayMouse.containsMouse && modelData.inMonth ? Theme.cardHoverBg : "transparent")
                    border.width: modelData.isToday ? 0 : (dayMouse.containsMouse && modelData.inMonth ? 1 : 0)
                    border.color: Theme.alpha(Theme.primary, 0.45)

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: modelData.isToday
                        color: {
                            if (modelData.isToday) return Theme.onPrimary;
                            if (modelData.inMonth) return Theme.textPrimary;
                            return Theme.alpha(Theme.textSecondary, 0.35);
                        }
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }
}
