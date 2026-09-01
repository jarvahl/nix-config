import QtQuick
import Quickshell
import ".." as Osd

Scope {
    Component {
        id: brightnessComponent

        BrightnessWidget {}
    }

    Connections {
        target: Brightness

        function onChanged(value) {
            Osd.OsdBus.show(brightnessComponent);
        }
    }
}
