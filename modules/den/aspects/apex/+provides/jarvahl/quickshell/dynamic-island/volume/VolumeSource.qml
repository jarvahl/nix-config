import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".." as Island

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

        Island.DynamicIslandBus.show("volume", {
            value: root.volume,
            muted: root.muted
        });
    }

    onSinkChanged: baselineReady = false

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
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
