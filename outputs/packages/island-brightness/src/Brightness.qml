pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real value: maximum > 0 && current >= 0
        ? Math.max(0, Math.min(1, current / maximum))
        : 0

    property string deviceName: ""
    property real current: -1
    property real maximum: -1
    property bool baselineReady: false

    signal changed(real value)

    function selectDevice(output) {
        const lines = output.trim().split("\n");

        for (const line of lines) {
            const candidate = line.split(",")[0].trim();

            if (candidate !== "" && candidate !== ".." && !candidate.includes("/")) {
                deviceName = candidate;
                return;
            }
        }

        console.warn("Brightness: brightnessctl did not return a backlight device");
    }

    function acceptCurrent(candidate) {
        if (!Number.isFinite(candidate) || candidate < 0)
            return;

        const previous = current;
        current = candidate;

        if (maximum <= 0)
            return;

        if (!baselineReady) {
            baselineReady = true;
            return;
        }

        if (current !== previous)
            changed(value);
    }

    function acceptMaximum(candidate) {
        if (!Number.isFinite(candidate) || candidate <= 0)
            return;

        maximum = candidate;

        if (current >= 0)
            baselineReady = true;
    }

    Process {
        id: discovery

        command: [
            "brightnessctl",
            "--class=backlight",
            "--machine-readable",
            "info"
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.selectDevice(this.text);
                currentProcess.running = root.deviceName !== "";
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0)
                console.warn("Brightness: device discovery failed with exit code", exitCode);
        }
    }

    FileView {
        id: brightnessFile

        path: root.deviceName === ""
            ? ""
            : "/sys/class/backlight/" + root.deviceName + "/brightness"
        watchChanges: path !== ""

        onFileChanged: reload()
        onLoaded: root.acceptCurrent(Number(text().trim()))
        onLoadFailed: function(error) {
            console.warn("Brightness: failed to read brightness:", error);
        }
    }

    Process {
        id: currentProcess

        command: [
            "brightnessctl",
            "--class=backlight",
            "--machine-readable",
            "info"
        ]
        running: root.deviceName !== ""

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split(",");
                if (fields.length >= 5) {
                    root.acceptCurrent(Number(fields[2]));
                    root.acceptMaximum(Number(fields[4]));
                }
            }
        }
    }

    Timer {
        // Some backlight sysfs files do not emit reliable change events.
        // Poll brightnessctl itself so hardware-key changes always reach the UI.
        interval: 150
        repeat: true
        running: root.deviceName !== ""
        onTriggered: {
            if (!currentProcess.running)
                currentProcess.running = true;
        }
    }

    FileView {
        id: maximumFile

        path: root.deviceName === ""
            ? ""
            : "/sys/class/backlight/" + root.deviceName + "/max_brightness"

        onLoaded: root.acceptMaximum(Number(text().trim()))
        onLoadFailed: function(error) {
            console.warn("Brightness: failed to read maximum brightness:", error);
        }
    }
}
