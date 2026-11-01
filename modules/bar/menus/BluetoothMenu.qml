import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.config

// Bluetooth on or off, and the devices you already know.
ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var known: Bluetooth.devices.values.filter(device => device.paired || device.connected).sort((a, b) => b.connected - a.connected).slice(0, 7)

    spacing: 6
    width: 320

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: "Bluetooth"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 18
        }

        MenuSwitch {
            on: root.adapter?.enabled ?? false
            onToggled: root.adapter.enabled = !root.adapter.enabled
        }
    }

    Repeater {
        model: root.adapter?.enabled ? root.known : []

        MenuRow {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.name || modelData.deviceName
            detail: modelData.batteryAvailable ? `${Math.round(modelData.battery * 100)} %` : modelData.connected ? "connecté" : ""
            active: modelData.connected
            onPicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }

    Text {
        visible: (root.adapter?.enabled ?? false) && root.known.length === 0
        text: "Aucun appareil connu."
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 14
    }
}
