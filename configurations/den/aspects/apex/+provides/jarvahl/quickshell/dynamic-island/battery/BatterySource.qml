import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".." as Island

Scope {
    id: root

    readonly property real rawPercent: UPower.displayDevice.percentage
    readonly property int percent: Math.round(rawPercent <= 1 ? rawPercent * 100 : rawPercent)
    readonly property string level: percent <= 20 ? "red" : percent <= 50 ? "orange" : "green"
    readonly property bool charged: !UPower.onBattery && percent >= 99

    property bool baselineReady: false
    property bool previousOnBattery: UPower.onBattery
    property string previousLevel: level
    property bool previouslyCharged: charged

    function label(reason) {
        if (reason === "charged")
            return "Charged";
        if (reason === "plugged")
            return "Charging";
        if (reason === "unplugged")
            return "On battery";
        return level === "red" ? "Low battery" : level === "orange" ? "Battery" : "Battery";
    }

    function show(reason) {
        Island.DynamicIslandBus.show("battery", {
            label: label(reason),
            reason: reason,
            percent: percent,
            onBattery: UPower.onBattery
        });
    }

    function update(reason) {
        if (!UPower.displayDevice.ready)
            return;

        if (!baselineReady) {
            baselineReady = true;
            previousOnBattery = UPower.onBattery;
            previousLevel = level;
            previouslyCharged = charged;
            return;
        }

        if (reason === "power" && UPower.onBattery !== previousOnBattery)
            show(UPower.onBattery ? "unplugged" : "plugged");
        else if (charged && !previouslyCharged)
            show("charged");
        else if (level !== previousLevel && (level === "orange" || level === "red"))
            show(level);

        previousOnBattery = UPower.onBattery;
        previousLevel = level;
        previouslyCharged = charged;
    }

    Component.onCompleted: update("init")

    Connections {
        target: UPower

        function onOnBatteryChanged() {
            root.update("power");
        }
    }

    Connections {
        target: UPower.displayDevice

        function onReadyChanged() {
            root.update("ready");
        }

        function onPercentageChanged() {
            root.update("percent");
        }
    }
}
