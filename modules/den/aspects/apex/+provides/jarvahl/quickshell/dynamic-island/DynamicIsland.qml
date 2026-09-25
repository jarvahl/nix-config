import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "battery" as Battery
import "brightness" as Brightness
import "clock" as Clock
import "launcher" as Launcher
import "volume" as Volume

PanelWindow {
    id: root

    Battery.BatterySource {}

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleLauncher();
        }
    }

    function toggleLauncher() {
        if (activeIsland === "launcher") {
            closeActive();
            return;
        }

        hideTimer.stop();
        collapseTimer.stop();
        activeData = ({});
        activeIsland = "launcher";
        contentVisible = false;
        launcherFocusAttempts = 0;
        launcherWidget.reset();
        showTimer.restart();
        launcherFocusTimer.restart();
    }

    function closeActive() {
        hideTimer.stop();
        contentVisible = false;
        collapseTimer.restart();
    }

    property string activeIsland: ""
    property var activeData: ({})
    property bool contentVisible: true
    property int launcherFocusAttempts: 0
    property Item activeWidget: activeIsland === "launcher"
        ? launcherWidget
        : activeIsland === "battery" ? batteryWidget
        : activeIsland === "brightness" ? brightnessWidget
        : activeIsland === "volume" ? volumeWidget : null

    screen: Quickshell.screens[0]
    anchors.top: true
    visible: true
    focusable: activeIsland === "launcher"
    WlrLayershell.keyboardFocus: activeIsland === "launcher" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: activeIsland === "launcher" ? 520 : 480
    implicitHeight: activeIsland === "launcher" ? 360 : 72
    margins.top: 12
    color: "transparent"
    exclusiveZone: 64

    HyprlandFocusGrab {
        windows: [root]
        active: root.activeIsland === "launcher"

        onCleared: {
            if (root.activeIsland === "launcher")
                root.closeActive();
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.activeWidget ? root.activeWidget.width + (root.activeIsland === "launcher" ? 0 : 40) : 128
        height: root.activeWidget ? root.activeWidget.height + (root.activeIsland === "launcher" ? 0 : 18) : 32
        color: "#08090b"
        border.color: root.activeIsland === "launcher" ? (launcherWidget.activeFocus ? "#35ffffff" : "#28ffffff") : "#28ffffff"
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
        clip: root.activeIsland !== "launcher"

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

        Launcher.LauncherIsland {
            id: launcherWidget
            anchors.centerIn: parent
            opacity: root.contentVisible && root.activeIsland === "launcher" ? 1 : 0
            scale: root.contentVisible ? 1 : 0.94

            onCloseRequested: root.closeActive()

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

        Battery.BatteryIsland {
            id: batteryWidget
            anchors.centerIn: parent
            eventLabel: root.activeData.label || "Battery"
            opacity: root.contentVisible && root.activeIsland === "battery" ? 1 : 0
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
                if (island !== "launcher")
                    hideTimer.restart();
                return;
            }

            root.activeIsland = island;
            root.contentVisible = false;
            showTimer.restart();

            if (island !== "launcher")
                hideTimer.restart();
        }
    }

    Timer {
        id: showTimer
        interval: 420

        onTriggered: {
            root.contentVisible = true;

            if (root.activeIsland === "launcher")
                launcherFocusTimer.restart();
        }
    }

    Timer {
        id: launcherFocusTimer
        interval: 50
        repeat: true

        onTriggered: {
            if (root.activeIsland !== "launcher") {
                stop();
                return;
            }

            launcherWidget.focusSearch();
            root.launcherFocusAttempts += 1;

            if (root.launcherFocusAttempts >= 5)
                stop();
        }
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
