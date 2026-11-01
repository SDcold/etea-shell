import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config

// Wi-Fi on or off, and the networks in range.
ColumnLayout {
    id: root

    readonly property var wifi: Networking.devices.values.find(device => device.networks !== undefined) ?? null
    readonly property var networks: (wifi?.networks.values ?? []).slice().sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength).slice(0, 7)

    spacing: 6
    width: 320

    // Only scan while someone is looking
    Component.onCompleted: {
        if (wifi)
            wifi.scannerEnabled = true;
    }
    Component.onDestruction: {
        if (wifi)
            wifi.scannerEnabled = false;
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: "Wi-Fi"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 18
        }

        MenuSwitch {
            on: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Repeater {
        model: Networking.wifiEnabled ? root.networks : []

        MenuRow {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.name
            detail: modelData.connected ? "connecté" : `${Math.round(modelData.signalStrength * 100)} %`
            active: modelData.connected
            onPicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }
}
