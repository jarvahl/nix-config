import QtQuick

Item {
    id: root

    property var api

    property var eventData: ({})
    readonly property real value: Math.max(0, Math.min(1, eventData.value || 0))

    implicitWidth: 248
    implicitHeight: 36

    Text {
        id: sun
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "☀"
        color: "#ffd60a"
        font.pixelSize: 21
    }

    Text {
        anchors.left: sun.right
        anchors.leftMargin: 12
        anchors.top: parent.top
        text: "Display"
        color: "#aeb0b6"
        font.pixelSize: 11
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: Math.round(root.value * 100) + "%"
        color: "#f2f2f3"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 12
    }

    Rectangle {
        anchors.left: sun.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 6
        radius: 3
        color: "#303238"

        Rectangle {
            width: parent.width * root.value
            height: parent.height
            radius: parent.radius
            color: "#ffd60a"
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }
}
