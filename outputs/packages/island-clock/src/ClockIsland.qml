import QtQuick
import Quickshell

Item {
    property var api
    property var eventData: ({})

    implicitWidth: 72
    implicitHeight: 18

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.centerIn: parent
        color: "#f8f8f2"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 13
        font.weight: Font.Medium
        text: Qt.formatDateTime(clock.date, "HH:mm")
    }
}
