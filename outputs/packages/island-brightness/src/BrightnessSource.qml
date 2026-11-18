import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var api
    property int current: -1
    property int maximum: -1
    property bool baselineReady: false

    Process {
        id: reader

        command: [
            "brightnessctl",
            "--class=backlight",
            "--machine-readable",
            "info"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split(",");
                if (fields.length < 5)
                    return;

                const nextCurrent = Number(fields[2]);
                const nextMaximum = Number(fields[4]);

                if (!Number.isFinite(nextCurrent) || !Number.isFinite(nextMaximum) || nextMaximum <= 0)
                    return;

                root.maximum = nextMaximum;

                if (!root.baselineReady) {
                    root.current = nextCurrent;
                    root.baselineReady = true;
                    return;
                }

                if (nextCurrent === root.current)
                    return;

                root.current = nextCurrent;
                if (root.api)
                    root.api.show("brightness", {
                        value: Math.max(0, Math.min(1, nextCurrent / nextMaximum))
                    });
            }
        }
    }

    Timer {
        interval: 150
        repeat: true
        running: true
        onTriggered: {
            if (!reader.running)
                reader.running = true;
        }
    }

    Component.onCompleted: reader.running = true
}
