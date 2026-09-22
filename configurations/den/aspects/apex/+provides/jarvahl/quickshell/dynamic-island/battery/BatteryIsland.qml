import QtQuick
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root

    property string eventLabel: "Battery"

    readonly property real rawPercent: UPower.displayDevice.percentage
    readonly property int percent: Math.round(rawPercent <= 1 ? rawPercent * 100 : rawPercent)
    readonly property real fill: Math.max(0, Math.min(1, percent / 100))
    readonly property color fillColor: percent <= 20 && UPower.onBattery
        ? "#ff453a"
        : percent <= 50 && UPower.onBattery ? "#ff9f0a" : "#30d158"

    width: 232
    height: 34

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
                color: root.fillColor
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: !UPower.onBattery ? "⚡" : root.percent <= 20 ? "!" : "▰"
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
                text: root.eventLabel
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: "#303238"

                Rectangle {
                    width: parent.width * root.fill
                    height: parent.height
                    radius: parent.radius
                    color: root.fillColor

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
            text: root.percent + "%"
        }
    }
}
