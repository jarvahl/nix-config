import QtQuick
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root

    property var api
    property var eventData: ({})

    readonly property real rawPercent: UPower.displayDevice.percentage
    readonly property int percent: Math.round(rawPercent <= 1 ? rawPercent * 100 : rawPercent)
    readonly property real fill: Math.max(0, Math.min(1, percent / 100))
    readonly property bool charging: !UPower.onBattery
    readonly property string eventLabel: eventData.label || (charging ? "Charging" : "Battery")

    implicitWidth: 208
    implicitHeight: 48

    Rectangle {
        id: cell
        width: 34
        height: 18
        radius: 5
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.width: 1.5
        border.color: root.charging ? "#64d2ff" : root.percent <= 20 ? "#ff453a" : "#30d158"

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            width: (parent.width - 7) * root.fill
            height: parent.height - 6
            radius: 2
            color: cell.border.color
        }
    }

    Rectangle {
        anchors.left: cell.right
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 8
        radius: 1
        color: cell.border.color
    }

    Text {
        anchors.left: cell.right
        anchors.leftMargin: 14
        anchors.top: parent.top
        text: root.eventLabel
        color: "#aeb0b6"
        font.pixelSize: 11
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.percent + "%"
        color: "#f2f2f3"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 12
    }

    Text {
        anchors.left: cell.right
        anchors.leftMargin: 14
        anchors.bottom: parent.bottom
        text: root.charging ? "Power connected" : root.percent <= 20 ? "Low power" : "On battery"
        color: root.charging ? "#64d2ff" : root.percent <= 20 ? "#ff453a" : "#8e9299"
        font.pixelSize: 11
    }
}
