import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    signal closeRequested()

    readonly property var apps: listApps()
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var matches: filterApps(search.text)
    readonly property var bestMatch: matches.length > 0 ? matches[0] : null
    readonly property bool hasSuggestion: query !== "" && bestMatch !== null

    width: 440
    height: 42

    function listApps() {
        const applications = DesktopEntries.applications;

        if (!applications)
            return [];

        if (typeof applications.values === "function")
            return Array.from(applications.values());

        return Array.from(applications.values || applications);
    }

    function filterApps(query) {
        const needle = query.trim().toLowerCase();
        const source = [];

        if (needle === "")
            return source;

        for (const app of apps) {
            if (!app || !app.name)
                continue;

            if (app.name.toLowerCase().includes(needle))
                source.push(app);
        }

        source.sort(function(a, b) {
            const an = a.name.toLowerCase();
            const bn = b.name.toLowerCase();
            return (bn.startsWith(needle) ? 1 : 0) - (an.startsWith(needle) ? 1 : 0);
        });

        return source.slice(0, 5);
    }

    function focusSearch() {
        search.focus = true;
        search.forceActiveFocus();
        Qt.callLater(function() { search.forceActiveFocus(); });
    }

    function reset() {
        search.text = "";
        focusSearch();
    }

    function launchSelected() {
        const app = bestMatch;

        if (!app)
            return;

        Quickshell.execDetached(["gtk-launch", app.id]);
        closeRequested();
    }

    Rectangle {
        id: searchPill

        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.color: "transparent"
        border.width: 0

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            color: "#70737a"
            font.pixelSize: 14
            text: "⌕"
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 42
            anchors.right: appIcon.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: "#5f636b"
            elide: Text.ElideRight
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 14
            opacity: root.hasSuggestion ? 0.7 : 0
            text: root.bestMatch ? root.bestMatch.name : ""
            verticalAlignment: Text.AlignVCenter

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.InOutCubic
                }
            }
        }

        TextInput {
            id: search

            anchors.left: parent.left
            anchors.leftMargin: 42
            anchors.right: appIcon.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            color: "#f2f2f3"
            selectionColor: "#3d5afe"
            selectedTextColor: "#ffffff"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 14
            focus: true
            clip: true
            verticalAlignment: TextInput.AlignVCenter
            Keys.priority: Keys.BeforeItem

            Text {
                anchors.fill: parent
                color: "#70737a"
                font.family: search.font.family
                font.pixelSize: search.font.pixelSize
                verticalAlignment: Text.AlignVCenter
                text: "Search apps…"
                visible: search.text === ""
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.closeRequested();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.launchSelected();
                    event.accepted = true;
                }
            }
        }

        IconImage {
            id: appIcon

            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 22
            opacity: root.hasSuggestion ? 0.72 : 0
            source: root.bestMatch ? Quickshell.iconPath(root.bestMatch.icon, "application-x-executable") : ""

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.InOutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.hasSuggestion
                onClicked: root.launchSelected()
            }
        }
    }
}
