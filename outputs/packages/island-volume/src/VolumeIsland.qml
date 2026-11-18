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

    implicitWidth: 184
    implicitHeight: 24

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? "󰖁" : "󰕾"
        color: root.muted ? "#FF453A" : "#F2F2F7"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 19
    }

    Rectangle {
        id: track
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 5
        radius: 2.5
        color: "#48484A"

        Rectangle {
            id: fill
            width: parent.width * (root.muted ? 0 : Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: root.muted ? "#FF453A" : "#F2F2F7"

            Behavior on width {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            width: 8
            height: 8
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(
                0,
                Math.min(
                    parent.width - width,
                    parent.width * (root.muted ? 0 : Math.max(0, Math.min(1, root.value))) - width / 2
                )
            )
            color: root.muted ? "#FF453A" : "#FFFFFF"

            Behavior on x {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
