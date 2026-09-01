import QtQuick
import Quickshell
import ".." as Island

Item {
    id: root

    readonly property real value: Brightness.value

    width: 232
    height: 34

    Connections {
        target: Brightness

        function onChanged(value) {
            Island.DynamicIslandBus.show("brightness", { value: value });
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 10

        Rectangle {
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            radius: 14
            color: "#17191d"

            Text {
                anchors.fill: parent
                color: "#f2f2f3"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "☀"
            }
        }

        Column {
            width: 132
            height: parent.height
            spacing: 5

            Text {
                width: parent.width
                height: 14
                color: "#aeb0b6"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
                text: "Brightness"
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: "#303238"

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    radius: parent.radius
                    color: "#e4e5e7"

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Text {
            width: 42
            height: parent.height
            color: "#f2f2f3"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            rightPadding: 4
            text: Math.round(root.value * 100) + "%"
        }
    }
}
