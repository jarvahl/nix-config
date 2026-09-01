import QtQuick
import Quickshell

PanelWindow {
    id: root

    property Component idleComponent
    property Component activeComponent
    property Component pendingComponent
    property Component layoutComponent: idleComponent

    screen: Quickshell.screens[0]
    anchors.top: true
    implicitWidth: layoutLoader.item ? layoutLoader.item.implicitWidth + 24 : 0
    implicitHeight: layoutLoader.item ? layoutLoader.item.implicitHeight + 12 : 0
    margins.top: 15
    color: "transparent"
    exclusiveZone: 59

    Rectangle {
        id: island

        anchors.fill: parent
        color: "#090a0c"
        border.color: "#24ffffff"
        border.width: 1
        radius: height / 2
        clip: true

        Loader {
            id: loader

            anchors.centerIn: parent
            sourceComponent: root.activeComponent
                ? root.activeComponent
                : root.idleComponent
        }

        Loader {
            id: layoutLoader

            visible: false
            sourceComponent: root.layoutComponent
        }
    }

    Connections {
        target: OsdBus

        function onShow(component) {
            if (root.activeComponent === component) {
                hideTimer.restart();
                return;
            }

            root.stopTransitions();
            root.pendingComponent = component;

            if (root.activeComponent)
                modeTransition.start();
            else {
                root.layoutComponent = component;
                enterTransition.start();
            }

            hideTimer.restart();
        }
    }

    function stopTransitions() {
        enterTransition.stop();
        modeTransition.stop();
        exitTransition.stop();
    }

    SequentialAnimation {
        id: enterTransition

        PauseAnimation {
            duration: 165
        }

        ScriptAction {
            script: {
                loader.opacity = 0;
                root.activeComponent = root.pendingComponent;
            }
        }

        NumberAnimation {
            target: loader
            property: "opacity"
            to: 1
            duration: 120
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: modeTransition

        NumberAnimation {
            target: loader
            property: "opacity"
            to: 0
            duration: 90
            easing.type: Easing.InOutCubic
        }

        ScriptAction {
            script: root.activeComponent = root.pendingComponent
        }

        NumberAnimation {
            target: loader
            property: "opacity"
            to: 1
            duration: 110
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: exitTransition

        ScriptAction {
            script: root.layoutComponent = root.idleComponent
        }

        PauseAnimation {
            duration: 165
        }

        ScriptAction {
            script: {
                loader.opacity = 0;
                root.activeComponent = null;
            }
        }

        NumberAnimation {
            target: loader
            property: "opacity"
            to: 1
            duration: 120
            easing.type: Easing.InOutCubic
        }
    }

    Timer {
        id: hideTimer

        interval: 2000
        onTriggered: {
            if (!root.activeComponent)
                return;

            root.stopTransitions();
            exitTransition.start();
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 220
            easing.type: Easing.InOutCubic
        }
    }
}
