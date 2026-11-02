import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.config
import qs.services

// System info. Config.status picks what stays and in which order.
Row {
    id: root

    // Everything we know about the machine, gathered in one spot
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifi: {
        const device = Networking.devices.values.find(d => d.connected && d.networks !== undefined);
        return device?.networks.values.find(n => n.connected) ?? null;
    }
    readonly property bool wired: Networking.devices.values.some(d => d.connected && d.networks === undefined)
    readonly property int bluetoothDevices: Bluetooth.devices.values.filter(d => d.connected).length
    readonly property var battery: UPower.displayDevice

    spacing: Theme.barSpacing

    // Without this, Pipewire won't tell us the volume
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Repeater {
        model: Config.status

        Item {
            id: item

            required property string modelData
            // Each item boils down to an icon and sometimes a value
            readonly property var info: {
                switch (modelData) {
                case "notifications":
                    return [Notifs.quiet ? "bell-slash" : "bell", Notifs.count ? String(Notifs.count) : ""];
                case "settings":
                    return ["gear-six", ""];
                case "session":
                    return ["power", ""];
                case "network":
                    if (root.wifi)
                        return [root.wifi.signalStrength > 0.66 ? "wifi-high" : root.wifi.signalStrength > 0.33 ? "wifi-medium" : "wifi-low", ""];
                    return [root.wired ? "plugs-connected" : "wifi-slash", ""];
                case "bluetooth":
                    if (!Bluetooth.defaultAdapter?.enabled)
                        return ["bluetooth-slash", ""];
                    return [root.bluetoothDevices ? "bluetooth-connected" : "bluetooth", root.bluetoothDevices ? String(root.bluetoothDevices) : ""];
                case "volume":
                    if (!root.sink?.audio)
                        return ["", ""];
                    return [root.sink.audio.muted ? "speaker-x" : root.sink.audio.volume > 0.5 ? "speaker-high" : "speaker-low", Config.barPercent ? Math.round(root.sink.audio.volume * 100) + "%" : ""];
                case "battery":
                    if (!root.battery?.isLaptopBattery)
                        return ["", ""];
                    const level = root.battery.percentage;
                    const icon = !UPower.onBattery ? "battery-charging" : level > 0.8 ? "battery-full" : level > 0.5 ? "battery-high" : level > 0.25 ? "battery-medium" : level > 0.12 ? "battery-low" : "battery-warning";
                    return [icon, Config.barPercent ? Math.round(level * 100) + "%" : ""];
                }
                return ["", ""];
            }
            readonly property color tint: modelData === "battery" && UPower.onBattery && root.battery?.percentage < 0.15 ? "#f0947c" : Theme.text

            visible: info[0] !== ""
            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: content

                spacing: 6

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: item.info[0]
                    size: Theme.iconSize
                    tint: item.tint
                }

                Text {
                    visible: text !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: item.info[1]
                    color: item.tint
                    font.family: Theme.font
                    font.pixelSize: Theme.textSize
                }
            }

            // On the volume: click to mute, scroll to adjust
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => {
                    if (item.modelData === "settings") {
                        Menus.settingsOpen = !Menus.settingsOpen;
                    } else if (item.modelData === "session") {
                        Menus.sessionOpen = !Menus.sessionOpen;
                    } else if (item.modelData === "notifications") {
                        if (mouse.button === Qt.RightButton)
                            Notifs.quiet = !Notifs.quiet;
                        else
                            Menus.togglePanel("right");
                    } else if (item.modelData === "volume" && mouse.button === Qt.RightButton) {
                        root.sink.audio.muted = !root.sink.audio.muted;
                    } else {
                        Menus.toggle({ volume: "sound", network: "network", bluetooth: "bluetooth", battery: "power" }[item.modelData], item.mapToItem(null, item.width / 2, 0).x);
                    }
                }
                onWheel: wheel => item.modelData === "volume" && (root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
            }
        }
    }
}
