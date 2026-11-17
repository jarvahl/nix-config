import QtQuick
import Quickshell
import "." as BrightnessModule

Scope {
    id: root
    property var api

    Connections {
        target: BrightnessModule.Brightness

        function onChanged(value) {
            if (root.api)
                root.api.show("brightness", { value: value });
        }
    }
}
