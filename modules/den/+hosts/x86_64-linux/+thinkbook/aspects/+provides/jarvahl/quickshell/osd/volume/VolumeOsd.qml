import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".." as Osd

Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    property bool baselineReady: false

    function show() {
        if (!baselineReady) {
            baselineReady = true;
            return;
        }

        Osd.OsdBus.show(volumeComponent);
    }

    onSinkChanged: baselineReady = false

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Component {
        id: volumeComponent

        VolumeWidget {
            muted: root.muted
            value: root.volume
        }
    }

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null

        function onMutedChanged() {
            root.show();
        }

        function onVolumesChanged() {
            root.show();
        }
    }
}
