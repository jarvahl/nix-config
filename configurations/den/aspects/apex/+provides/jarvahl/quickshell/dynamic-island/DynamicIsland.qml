import QtQuick
import Quickshell
import "brightness" as Brightness
import "clock" as Clock
import "volume" as Volume

PanelWindow {
    id: root

    property string activeIsland: ""
    property var activeData: ({})
    property bool contentVisible: true
    property Item activeWidget: activeIsland === "brightness"
        ? brightnessWidget
        : activeIsland === "volume" ? volumeWidget : null

    screen: Quickshell.screens[0]
    anchors.top: true
    visible: true
    implicitWidth: 480
    implicitHeight: 72
    margins.top: 12
    color: "transparent"
    exclusiveZone: 64

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.activeWidget ? root.activeWidget.width + 40 : 128
        height: root.activeWidget ? root.activeWidget.height + 18 : 32
        color: "#08090b"
        border.color: "#28ffffff"
        border.width: 1
        radius: height / 2

        Behavior on width {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutCubic
            }
        }
        clip: true

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            radius: 1
            color: "#18ffffff"
        }

        Clock.ClockIsland {
            anchors.centerIn: parent
            opacity: root.activeIsland === "" ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Brightness.BrightnessIsland {
            id: brightnessWidget
            anchors.centerIn: parent
            opacity: root.contentVisible && root.activeIsland === "brightness" ? 1 : 0
            scale: root.contentVisible ? 1 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        }

        Volume.VolumeIsland {
            id: volumeWidget
            anchors.centerIn: parent
            opacity: root.contentVisible && root.activeIsland === "volume" ? 1 : 0
            scale: root.contentVisible ? 1 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Connections {
        target: DynamicIslandBus

        function onShow(island, data) {
            collapseTimer.stop();
            root.activeData = data;

            if (root.activeIsland === island) {
                hideTimer.restart();
                return;
            }

            root.activeIsland = island;
            root.contentVisible = false;
            showTimer.restart();
            hideTimer.restart();
        }
    }

    Timer {
        id: showTimer
        interval: 420

        onTriggered: root.contentVisible = true
    }

    Timer {
        id: hideTimer
        interval: 2200

        onTriggered: {
            root.contentVisible = false;
            collapseTimer.restart();
        }
    }

    Timer {
        id: collapseTimer
        interval: 420

        onTriggered: {
            root.activeData = ({});
            root.activeIsland = "";
            root.contentVisible = true;
        }
    }
}
