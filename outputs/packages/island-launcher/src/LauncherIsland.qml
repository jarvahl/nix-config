import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property var api
    property var eventData: ({})

    signal closeRequested()

    readonly property var apps: listApps()
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var matches: filterApps(search.text)
    property int selectedIndex: 0
    readonly property var bestMatch: matches[selectedIndex] || null
    onQueryChanged: selectedIndex = 0
    readonly property bool hasSuggestion: query !== "" && bestMatch !== null

    implicitWidth: 488
    implicitHeight: 288

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
        id: field
        width: parent.width
        height: 44
        radius: 14
        color: "#191b20"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "⌕"
            color: "#aeb0b6"
            font.pixelSize: 22
        }
        TextInput {
            id: search
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 42; rightMargin: 14 }
            color: "#f2f2f3"
            font.family: "sans-serif"
            font.pixelSize: 15
            selectionColor: "#466c99"
            clip: true
            Text {
                anchors.fill: parent
                text: "Search applications…"
                visible: search.text === ""
                color: "#858992"
                font: search.font
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) root.closeRequested();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.launchSelected();
                else if (event.key === Qt.Key_Down) root.selectedIndex = Math.min(root.matches.length - 1, root.selectedIndex + 1);
                else if (event.key === Qt.Key_Up) root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                else return;
                event.accepted = true;
            }
        }
    }

    Column {
        anchors { top: field.bottom; topMargin: 12; left: parent.left; right: parent.right }
        spacing: 4
        Repeater {
            model: root.matches
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: root.width
                height: 40
                radius: 12
                color: root.selectedIndex === index ? "#252830" : "transparent"
                IconImage {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    implicitSize: 24
                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                }
                Text {
                    anchors { left: parent.left; leftMargin: 48; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    text: modelData.name
                    font.family: "sans-serif"
                    font.pixelSize: 14
                    color: "#f2f2f3"
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedIndex = parent.index
                    onClicked: { root.selectedIndex = parent.index; root.launchSelected(); }
                }
            }
        }
        Text {
            visible: root.matches.length === 0
            text: "No matching applications"
            color: "#858992"
            font.pixelSize: 13
        }
    }
}
