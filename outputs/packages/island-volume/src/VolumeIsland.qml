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
        text: root.muted ? "×" : "♫"
        color: root.muted ? "#ff453a" : "#64d2ff"
        font.pixelSize: 18
    }

    Text {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? "Muted" : "Volume"
        color: "#f2f2f3"
        font.pixelSize: 12
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? "—" : Math.round(root.value * 100) + "%"
        color: root.muted ? "#ff453a" : "#aeb0b6"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 12
    }
}
