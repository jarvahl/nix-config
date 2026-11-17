import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property string activeIsland: ""
    property var activeData: ({})
    property bool contentVisible: true
    property int launcherFocusAttempts: 0
    readonly property int horizontalPadding: 16
    readonly property int verticalPadding: 12
    readonly property int topOffset: 12
    readonly property var pluginApi: widgetApi
    readonly property var plugins: registry.plugins
    readonly property string defaultWidgetId: registry.defaultId
    readonly property Item activeWidget: capsule.activeWidget
    readonly property var activePlugin: registry.plugin(activeIsland || registry.defaultId)

    function toggleLauncher() {
        if (activeIsland === "launcher") {
            closeActive();
            return;
        }

        hideTimer.stop();
        collapseTimer.stop();
        showTimer.stop();
        activeData = ({});
        activeIsland = "launcher";
        contentVisible = false;
        launcherFocusAttempts = 0;
        showTimer.restart();
        launcherFocusTimer.restart();
    }

    function closeActive() {
        hideTimer.stop();
        showTimer.stop();
        launcherFocusTimer.stop();
        contentVisible = false;
        collapseTimer.restart();
    }

    screen: Quickshell.screens[0]
    anchors.top: true
    visible: true
    focusable: activeIsland === "launcher"
    WlrLayershell.keyboardFocus: activeIsland === "launcher" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dynamic-island"
    implicitWidth: Math.min(screen.width, 760)
    implicitHeight: Math.min(screen.height, 560)
    color: "transparent"
    exclusiveZone: activeIsland === "" && activeWidget
        ? activeWidget.implicitHeight + 2 * verticalPadding + topOffset
        : registry.defaultPlugin?.reserve || 48
    mask: Region { item: capsule }

    QtObject {
        id: widgetApi
        signal show(string islandName, var data)
    }

    WidgetRegistry {
        id: registry
        api: widgetApi
        sourceParent: root
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleLauncher(); }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.activeIsland === "launcher"
        onCleared: if (root.activeIsland === "launcher") root.closeActive()
    }

    IslandCapsule {
        id: capsule
        anchors.top: parent.top
        anchors.topMargin: root.topOffset
        anchors.horizontalCenter: parent.horizontalCenter
        widgetUrl: root.activePlugin ? Qt.resolvedUrl(root.activePlugin.component) : ""
        activeId: root.activeIsland
        eventData: root.activeData
        api: widgetApi
        contentVisible: root.contentVisible
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
        topOffset: root.topOffset
        onLauncherRequested: root.toggleLauncher()
        onCloseRequested: root.closeActive()
    }

    Connections {
        target: widgetApi
        function onShow(islandName, data) {
            if (root.activeIsland === "launcher")
                return;
            collapseTimer.stop();
            root.activeData = data;
            root.activeIsland = islandName;
            root.contentVisible = false;
            showTimer.restart();
            hideTimer.restart();
        }
    }

    Timer {
        id: showTimer
        interval: 100
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
            if (root.activeIsland !== "launcher" || !root.activeWidget?.focusSearch) {
                stop();
                return;
            }
            root.activeWidget.focusSearch();
            if (++root.launcherFocusAttempts >= 5)
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
        interval: 300
        onTriggered: {
            root.activeData = ({});
            root.activeIsland = "";
            root.contentVisible = true;
        }
    }
}
