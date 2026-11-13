import QtQuick
import Quickshell

Item {
    width: 88
    height: 18

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        anchors.fill: parent
        color: "#d9dadd"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 13
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
    }
}
