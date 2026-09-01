import QtQuick
import Quickshell
import "osd" as Osd
import "osd/brightness" as Brightness
import "osd/clock" as Clock
import "osd/volume" as Volume

Scope {
    Component {
        id: clockComponent

        Clock.ClockWidget {}
    }

    Osd.OsdHost {
        idleComponent: clockComponent
    }

    Brightness.BrightnessOsd {}
    Volume.VolumeOsd {}
}
