import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var sourceParent
    property var api
    property var plugins: []
    property var sources: []
    property string defaultId: Quickshell.env("DYNAMIC_ISLAND_DEFAULT") || ""
    readonly property var defaultPlugin: plugin(defaultId)

    function plugin(id) {
        return plugins.find(entry => entry.id === id) || null;
    }

    function loadSource(entry) {
        if (!entry.source)
            return;

        const component = Qt.createComponent(Qt.resolvedUrl(entry.source));
        const create = function() {
            if (component.status === Component.Ready) {
                const instance = component.createObject(sourceParent, { api: root.api });
                if (instance)
                    sources.push(instance);
                else
                    console.error("Dynamic Island: failed to instantiate source", entry.id);
            } else if (component.status === Component.Error) {
                console.error("Dynamic Island: failed to load source", entry.id, component.errorString());
            }
        };

        if (component.status === Component.Loading)
            component.statusChanged.connect(create);
        else
            create();
    }

    FileView {
        path: Qt.resolvedUrl("widgets.json")

        onLoaded: {
            try {
                const entries = JSON.parse(text());
                if (!root.defaultId || !entries.some(entry => entry.id === root.defaultId)
                        || entries.some(entry => !entry.id || !entry.component)
                        || entries.some((entry, index) => entries.findIndex(other => other.id === entry.id) !== index)) {
                    console.error("Dynamic Island: set DYNAMIC_ISLAND_DEFAULT to a registered widget ID; widget IDs must be unique");
                    return;
                }

                root.plugins = entries;
                for (const entry of entries)
                    root.loadSource(entry);
            } catch (error) {
                console.error("Dynamic Island: invalid widget registry", error);
            }
        }

        onLoadFailed: error => console.error("Dynamic Island: cannot read widget registry", error)
    }
}
