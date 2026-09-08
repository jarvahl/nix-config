import QtQuick
import Quickshell
import "dynamic-island" as Island
import "dynamic-island/brightness" as Brightness
import "dynamic-island/clock" as Clock
import "dynamic-island/volume" as Volume

Scope {
    Component {
        id: clockIsland

        Clock.ClockIsland {}
    }

    Component {
        id: volumeIsland

        Volume.VolumeIsland {}
    }

    Component {
        id: brightnessIsland

        Brightness.BrightnessIsland {}
    }

    Island.DynamicIsland {
        idleComponent: clockIsland
        registry: ({
            volume: volumeIsland,
            brightness: brightnessIsland
        })
    }

    Brightness.BrightnessSource {}
    Volume.VolumeSource {}
}
