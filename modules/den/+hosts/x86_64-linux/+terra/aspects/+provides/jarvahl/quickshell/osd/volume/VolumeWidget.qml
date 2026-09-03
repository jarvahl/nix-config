import QtQuick

Item {
    id: root

    required property bool muted
    required property real value

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
            text: root.muted || root.value <= 0.001 ? "󰝟" : "󰝞"
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 96
            height: 4
            color: "#292a2f"
            radius: height / 2

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                color: "#d7d8dc"
                radius: parent.radius

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
