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
    implicitHeight: 36

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
        font.pixelSize: 21
    }

    Text {
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.top: parent.top
        text: root.muted ? "Muted" : "Volume"
        color: root.muted ? "#FF453A" : "#A6A6A0"
        font.pixelSize: 11
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.muted ? "—" : Math.round(root.value * 100) + "%"
        color: root.muted ? "#FF453A" : "#F2F2F7"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 12
    }

    Rectangle {
        id: track
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 6
        radius: 3
        color: "#48484A"

        Rectangle {
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
    }
}
