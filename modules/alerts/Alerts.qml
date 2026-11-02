import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config

// The system speaking up when it matters: a battery running low, then nearly empty.
// Each warning comes once per discharge, plugging in resets them.
Scope {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool draining: UPower.onBattery && (battery?.isLaptopBattery ?? false)
    readonly property int percent: Math.round((battery?.percentage ?? 1) * 100)
    property int warned: 0 // 1 once told it's low, 2 once told it's nearly empty

    function check() {
        if (!draining) {
            warned = 0;
            return;
        }
        if (percent <= 5 && warned < 2) {
            warned = 2;
            say.exec(["notify-send", "-a", Lang.t("Batterie"), "-u", "critical", "-i", "battery-caution", Lang.t("Batterie presque vide"), Lang.t("{0} %. Branche le chargeur, ou enregistre ton travail.", percent)]);
        } else if (percent <= 15 && warned < 1) {
            warned = 1;
            say.exec(["notify-send", "-a", Lang.t("Batterie"), "-i", "battery-low", Lang.t("Batterie faible"), Lang.t("{0} % restants. Pense au chargeur.", percent)]);
        }
    }

    onPercentChanged: check()
    onDrainingChanged: check()
    Component.onCompleted: check()

    Process {
        id: say
    }
}
