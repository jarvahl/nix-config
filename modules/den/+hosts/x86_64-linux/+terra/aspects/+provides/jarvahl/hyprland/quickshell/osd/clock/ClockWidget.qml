import QtQuick
import Quickshell

Item {
    implicitWidth: 88
    implicitHeight: 17

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Text {
        anchors.centerIn: parent
        color: "#b8b9bf"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.weight: Font.Medium
        text: Qt.formatDateTime(clock.date, "HH:mm")
    }
}
