import QtQuick
import Quickshell

Item {
    property var api
    property var eventData: ({})

    implicitWidth: 100
    implicitHeight: 22

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.centerIn: parent
        color: "#f2f2f3"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 15
        font.weight: Font.Medium
        text: Qt.formatDateTime(clock.date, "HH:mm")
    }
}
