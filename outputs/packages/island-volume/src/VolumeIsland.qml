import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root

    property var api
    property var eventData: ({})
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real value: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    implicitWidth: 248
    implicitHeight: 40

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }


    Rectangle {
        id: iconBadge
        width: 36
        height: 36
        radius: 18
        color: "#191b20"
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.centerIn: parent
            text: root.muted ? "×" : "♫"
            color: root.muted ? "#ff453a" : "#64d2ff"
            font.pixelSize: 18
        }
    }

    Text {
        anchors.left: iconBadge.right
        anchors.leftMargin: 12
        anchors.top: parent.top
        text: root.muted ? "Muted" : "Output volume"
        color: "#aeb0b6"
        font.pixelSize: 12
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.muted ? "—" : Math.round(root.value * 100) + "%"
        color: "#f2f2f3"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 12
    }

    Rectangle {
        anchors.left: iconBadge.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 5
        radius: 3
        color: "#303238"

        Rectangle {
            width: parent.width * (root.muted ? 0 : Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: root.muted ? "#ff453a" : "#64d2ff"
            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }
}
