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

    function glyph(code) {
        return String.fromCodePoint(code);
    }

    spacing: 18
    anchors.verticalCenter: parent.verticalCenter

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
                    return [root.glyph(Notifs.quiet ? 0xf009b : 0xf009a), Notifs.count ? String(Notifs.count) : ""];
                case "network":
                    if (root.wifi)
                        return [root.glyph(root.wifi.signalStrength > 0.66 ? 0xf0928 : root.wifi.signalStrength > 0.33 ? 0xf0925 : 0xf091f), ""];
                    return [root.glyph(root.wired ? 0xf0200 : 0xf092d), ""];
                case "bluetooth":
                    if (!Bluetooth.defaultAdapter?.enabled)
                        return [root.glyph(0xf00b2), ""];
                    return [root.glyph(0xf00af), root.bluetoothDevices ? String(root.bluetoothDevices) : ""];
                case "volume":
                    if (!root.sink?.audio)
                        return ["", ""];
                    return [root.glyph(root.sink.audio.muted ? 0xf075f : 0xf057e), Math.round(root.sink.audio.volume * 100) + "%"];
                case "battery":
                    if (!root.battery?.isLaptopBattery)
                        return ["", ""];
                    return [root.glyph(UPower.onBattery ? 0xf0079 : 0xf0084), Math.round(root.battery.percentage * 100) + "%"];
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

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: item.info[0]
                    color: item.tint
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.textSize
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
                enabled: item.modelData === "volume" || item.modelData === "notifications"
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: mouse => {
                    if (item.modelData === "volume")
                        root.sink.audio.muted = !root.sink.audio.muted;
                    else if (mouse.button === Qt.RightButton)
                        Notifs.quiet = !Notifs.quiet;
                    else
                        Notifs.journalOpen = !Notifs.journalOpen;
                }
                onWheel: wheel => root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
            }
        }
    }
}
