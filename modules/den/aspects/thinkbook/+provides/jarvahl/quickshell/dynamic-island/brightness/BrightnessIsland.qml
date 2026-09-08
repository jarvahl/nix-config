import QtQuick

Item {
    property var data: ({})

    implicitWidth: 120
    implicitHeight: 17

    Row {
        anchors.fill: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: "#b8b9bf"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.Medium
            text: "󰃠"
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 96
            height: 4
            radius: height / 2
            color: "#292a2f"

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, data.value))
                height: parent.height
                radius: parent.radius
                color: "#d7d8dc"

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }
    }
}
