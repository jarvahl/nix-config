pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string deviceName: internalDeviceName
    readonly property bool ready: baselineReady
    readonly property real value: maximum > 0 && current >= 0
        ? Math.max(0, Math.min(1, current / maximum))
        : 0

    property string internalDeviceName: ""
    property real current: -1
    property real maximum: -1
    property bool baselineReady: false

    signal changed(real value)

    function selectDevice(output) {
        const lines = output.trim().split("\n");

        for (const line of lines) {
            const candidate = line.split(",")[0].trim();

            if (candidate !== "" && candidate !== ".." && !candidate.includes("/")) {
                internalDeviceName = candidate;
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
            onStreamFinished: root.selectDevice(this.text)
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
