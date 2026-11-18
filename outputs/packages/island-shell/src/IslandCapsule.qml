import QtQuick

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
    property real targetWidgetWidth: 100
    property real targetWidgetHeight: 22
    objectName: "island"

    signal launcherRequested()
    signal closeRequested()

    width: Math.min(parent.width, targetWidgetWidth + 2 * horizontalPadding)
    height: Math.min(parent.height - topOffset, targetWidgetHeight + 2 * verticalPadding)
    color: "#272822"
    border.color: activeId === "launcher" && activeWidget?.activeFocus ? "#a6e22e" : "#75715e"
    border.width: activeId === "" ? 0 : 1
    radius: Math.min(28, height / 2)
    topLeftRadius: activeId === "" ? 0 : 22
    topRightRadius: activeId === "" ? 0 : 22
    Behavior on topLeftRadius { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
    Behavior on topRightRadius { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
    layer.enabled: false
    Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
    Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
    clip: true

    onActiveWidgetChanged: captureWidgetGeometry()

    onContentVisibleChanged: {
        if (contentVisible)
            contentLayer.visible = true;
        animateContent();
    }

    function animateContent() {
        opacityAnimation.to = contentVisible ? 1 : 0;
        opacityAnimation.restart();
        scaleAnimation.to = contentVisible ? 1 : 0.96;
        scaleAnimation.restart();
    }

    function captureWidgetGeometry() {
        if (!activeWidget)
            return;

        targetWidgetWidth = activeWidget.implicitWidth;
        targetWidgetHeight = activeWidget.implicitHeight;
    }

    Item {
        id: contentLayer
        anchors.centerIn: parent
        width: widgetLoader.implicitWidth
        height: widgetLoader.implicitHeight
        opacity: 1
        scale: 1
        visible: true

        NumberAnimation {
            id: opacityAnimation
            target: contentLayer
            property: "opacity"
            duration: 320
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            id: scaleAnimation
            target: contentLayer
            property: "scale"
            duration: 320
            easing.type: Easing.InOutCubic
        }

        Loader {
            id: widgetLoader
            anchors.fill: parent

            function loadWidget(url) {
                contentLayer.visible = root.contentVisible;
                contentLayer.opacity = root.contentVisible ? 1 : 0;
                contentLayer.scale = root.contentVisible ? 1 : 0.96;

                if (url.toString() === "") {
                    source = "";
                    return;
                }

                setSource(url, { api: root.api, eventData: root.eventData });
            }

            Component.onCompleted: {
                loadWidget(root.widgetUrl);
                contentLayer.opacity = root.contentVisible ? 1 : 0;
                contentLayer.scale = root.contentVisible ? 1 : 0.96;
            }
            onLoaded: {
                contentLayer.visible = root.contentVisible;
                contentLayer.opacity = root.contentVisible ? 1 : 0;
                contentLayer.scale = root.contentVisible ? 1 : 0.96;
                root.captureWidgetGeometry();
                if (root.activeId === "launcher" && item && item.reset)
                    item.reset();
            }

            Connections {
                target: root
                function onWidgetUrlChanged() { widgetLoader.loadWidget(root.widgetUrl); }
                function onApiChanged() { if (widgetLoader.item) widgetLoader.item.api = root.api; }
                function onEventDataChanged() { if (widgetLoader.item) widgetLoader.item.eventData = root.eventData; }
            }
        }
    }

    Connections {
        target: widgetLoader.item
        ignoreUnknownSignals: true
        function onCloseRequested() { root.closeRequested(); }
        function onImplicitWidthChanged() { root.captureWidgetGeometry(); }
        function onImplicitHeightChanged() { root.captureWidgetGeometry(); }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.activeId === ""
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.launcherRequested()
    }
}
