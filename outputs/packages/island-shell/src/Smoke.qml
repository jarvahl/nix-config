import QtQuick
import Quickshell

Scope {
    Host { id: shell }
    property int step: 0

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            try {
                check(shell.defaultWidgetId === "clock", "default widget was not configured");
                check(shell.exclusiveZone === 30, "reservation changed");
                const capsule = shell.contentItem.children.find(child => child.objectName === "island");
                check(shell.mask !== null, "missing click-through mask");
                if (step === 0) shell.pluginApi.show("volume", {});
                else if (step === 1) {
                    check(shell.activeIsland === "volume", "volume not shown");
                    check(shell.activeWidget.implicitWidth === 248 && shell.activeWidget.implicitHeight === 40, "volume geometry");
                    shell.activeWidget.implicitWidth = 300;
                    shell.activeWidget.implicitHeight = 52;
                } else if (step === 2) {
                    check(Math.abs(capsule.width - (300 + 2 * shell.horizontalPadding)) < 1, "widget width ignored");
                    check(Math.abs(capsule.height - (52 + 2 * shell.verticalPadding)) < 1, "widget height ignored");
                    shell.pluginApi.show("brightness", {});
                    check(shell.activeIsland === "brightness", "brightness not shown");
                    shell.pluginApi.show("battery", {label: "Charging"});
                } else if (step === 3) {
                    check(shell.activeIsland === "battery", "battery not shown");
                    shell.toggleLauncher();
                    shell.pluginApi.show("volume", {});
                    check(shell.activeIsland === "launcher", "feedback stole launcher focus");
                } else if (step === 4) shell.closeActive();
                else if (step === 5 && shell.activeIsland !== "") return;
                else {
                    check(shell.activeIsland === "", "did not return to clock");
                    console.log("ISLAND_SMOKE_PASS");
                    Qt.quit();
                }
                step++;
            } catch (error) {
                console.error("ISLAND_SMOKE_FAIL: " + error);
                Qt.quit();
            }
        }
    }
}
