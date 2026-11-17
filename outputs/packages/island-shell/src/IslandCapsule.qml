import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    property url widgetUrl
    property string activeId: ""
    property var eventData: ({})
    property var api
    property bool contentVisible: true
    readonly property Item activeWidget: widgetLoader.item
    property int horizontalPadding: 16
    property int verticalPadding: 12
    property int topOffset: 12
    objectName: "island"

    signal launcherRequested()
    signal closeRequested()

    width: Math.min(parent.width, (activeWidget?.implicitWidth || 100) + 2 * horizontalPadding)
    height: Math.min(parent.height - topOffset, (activeWidget?.implicitHeight || 22) + 2 * verticalPadding)
    color: "#08090b"
    border.color: activeId === "launcher" && activeWidget?.activeFocus ? "#35ffffff" : "#28ffffff"
    border.width: 1
    radius: Math.min(28, height / 2)
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#48000000"
        shadowBlur: 0.65
        shadowVerticalOffset: 6
    }
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    clip: true

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 1
        radius: 1
        color: "#18ffffff"
    }

    Loader {
        id: widgetLoader
        anchors.centerIn: parent
        opacity: root.contentVisible ? 1 : 0
        scale: root.contentVisible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        function loadWidget(url) {
            if (url.toString() === "") {
                source = "";
                return;
            }
            setSource(url, { api: root.api, eventData: root.eventData });
        }

        Component.onCompleted: loadWidget(root.widgetUrl)
        onLoaded: if (root.activeId === "launcher" && item && item.reset) item.reset()

        Connections {
            target: root
            function onWidgetUrlChanged() { widgetLoader.loadWidget(root.widgetUrl); }
            function onApiChanged() { if (widgetLoader.item) widgetLoader.item.api = root.api; }
            function onEventDataChanged() { if (widgetLoader.item) widgetLoader.item.eventData = root.eventData; }
        }
    }

    Connections {
        target: widgetLoader.item
        ignoreUnknownSignals: true
        function onCloseRequested() { root.closeRequested(); }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.activeId === ""
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.launcherRequested()
    }
}
