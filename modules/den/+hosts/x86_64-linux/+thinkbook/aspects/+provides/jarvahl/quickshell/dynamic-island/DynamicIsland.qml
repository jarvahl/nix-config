import QtQuick
import Quickshell

PanelWindow {
    id: root

    property Component idleComponent
    property var registry: ({})
    property string activeIsland: ""
    property var activeData: ({})

    screen: Quickshell.screens[0]
    anchors.top: true
    implicitWidth: loader.item ? loader.item.implicitWidth + 24 : 0
    implicitHeight: loader.item ? loader.item.implicitHeight + 12 : 0
    margins.top: 15
    color: "transparent"
    exclusiveZone: 59

    Rectangle {
        anchors.fill: parent
        color: "#090a0c"
        border.color: "#24ffffff"
        border.width: 1
        radius: height / 2
        clip: true

        Loader {
            id: loader

            anchors.centerIn: parent
            sourceComponent: root.activeIsland === ""
                ? root.idleComponent
                : root.registry[root.activeIsland]
        }
    }

    Connections {
        target: DynamicIslandBus

        function onShow(island, data) {
            if (root.activeIsland === island) {
                root.activeData = data;
                if (loader.item)
                    loader.item.data = data;
                hideTimer.restart();
                return;
            }

            fade.stop();
            loader.opacity = 0;
            root.activeIsland = island;
            root.activeData = data;
            hideTimer.restart();
            fade.restart();
        }
    }

    NumberAnimation {
        id: fade

        target: loader
        property: "opacity"
        from: 0
        to: 1
        duration: 120
        easing.type: Easing.InOutCubic
    }

    Timer {
        id: hideTimer

        interval: 2000

        onTriggered: {
            fade.stop();
            loader.opacity = 0;
            root.activeIsland = "";
            root.activeData = ({});
            fade.restart();
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }
}
