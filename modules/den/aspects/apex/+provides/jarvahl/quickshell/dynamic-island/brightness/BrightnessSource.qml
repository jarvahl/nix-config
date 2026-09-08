import QtQuick
import ".." as Island

Scope {
    Connections {
        target: Brightness

        function onChanged(value) {
            Island.DynamicIslandBus.show("brightness", {
                value: value
            });
        }
    }
}
