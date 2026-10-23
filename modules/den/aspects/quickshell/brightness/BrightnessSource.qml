import QtQuick
import Quickshell
import ".." as Island

Scope {
    Connections {
        target: Brightness

        function onChanged(value) {
            Island.Bus.show("brightness", {
                value: value
            });
        }
    }
}
