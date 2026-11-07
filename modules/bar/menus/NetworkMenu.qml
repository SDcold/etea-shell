import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.config
import qs.services

// Wi-Fi on or off, the networks in range, a hidden one, your cables and your VPNs. The rest
// opens in NetworkManager's own editor.
ColumnLayout {
    id: root

    readonly property var wifi: Networking.devices.values.find(device => device.networks !== undefined) ?? null
    readonly property var inRange: (wifi?.networks.values ?? []).slice().sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
    readonly property var networks: showAll ? inRange : inRange.slice(0, 7)
    readonly property string joined: inRange.find(network => network.connected)?.name ?? ""

    readonly property color cardTint: Networking.wifiEnabled ? "#8fc7e8" : "#a9a4ad"
    readonly property real cardRise: Networking.wifiEnabled ? 0.12 : 0.05

    property string asking: ""
    property bool askingHidden: false
    property bool showAll: false
    property string address: "" // where the joined network put us
    property var saved: [] // { name, type, uuid, active }, from NetworkManager
    readonly property var cables: saved.filter(connection => connection.type === "802-3-ethernet")
    readonly property var vpns: saved.filter(connection => connection.type === "vpn" || connection.type === "wireguard")

    function readSaved() {
        savedReader.running = true;
    }

    function switchOver(connection) {
        switcher.command = ["nmcli", "connection", connection.active ? "down" : "up", "uuid", connection.uuid];
        switcher.running = true;
    }

    // NetworkManager's editor when it's there, otherwise nmtui in whatever terminal there is
    function openSettings() {
        Quickshell.execDetached(["sh", "-c", `
            command -v nm-connection-editor >/dev/null && exec nm-connection-editor
            command -v xdg-terminal-exec >/dev/null && exec xdg-terminal-exec nmtui
            [ -n "$TERMINAL" ] && command -v "$TERMINAL" >/dev/null && exec "$TERMINAL" -e nmtui
            for terminal in kitty foot alacritty konsole gnome-terminal xterm; do
                command -v $terminal >/dev/null || continue
                case $terminal in
                    kitty|foot) exec $terminal nmtui ;;
                    gnome-terminal) exec $terminal -- nmtui ;;
                    *) exec $terminal -e nmtui ;;
                esac
            done`]);
        Menus.close();
        Menus.closePanel("right");
    }

    onJoinedChanged: readAddress()

    function readAddress() {
        address = "";
        if (joined && wifi)
            addressReader.running = true;
    }

    spacing: 6
    width: 320

    // Only scan while someone is looking
    Component.onCompleted: {
        if (wifi)
            wifi.scannerEnabled = true;
        readSaved();
        readAddress();
    }

    Process {
        id: savedReader

        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE,UUID", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.saved = text.split("\n").map(line => line.split(":")).filter(fields => fields.length >= 4).map(fields => ({ name: fields[0], type: fields[1], active: fields[2] === "yes", uuid: fields[3] }))
        }
    }

    // A cable or a VPN takes a moment to come up or go down, look again once it has
    Process {
        id: switcher

        onExited: root.readSaved()
    }

    Process {
        id: addressReader

        command: ["nmcli", "-g", "IP4.ADDRESS", "device", "show", root.wifi?.name ?? ""]
        stdout: StdioCollector {
            onStreamFinished: root.address = text.split("|")[0].split("/")[0].trim()
        }
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
            font.pixelSize: 15
        }

        MenuSwitch {
            on: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    // A new network, one that needs a password before we can join, or a hidden one
    Loader {
        Layout.fillWidth: true
        active: root.asking !== "" || root.askingHidden
        visible: active

        sourceComponent: WifiPassword {
            network: root.asking
            onFinished: {
                root.asking = "";
                root.askingHidden = false;
            }
        }
    }

    Repeater {
        model: Networking.wifiEnabled ? root.networks : []

        MenuRow {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.name
            detail: modelData.connected ? root.address : ""
            level: modelData.signalStrength
            active: modelData.connected
            action: modelData.known ? Lang.t("Oublier") : ""
            onActed: modelData.forget()
            onPicked: {
                root.askingHidden = false;
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.known || modelData.security === WifiSecurityType.Open)
                    modelData.connect();
                else
                    root.asking = modelData.name;
            }
        }
    }

    MenuRow {
        visible: Networking.wifiEnabled && root.inRange.length > 7
        Layout.fillWidth: true
        label: root.showAll ? Lang.t("Moins de réseaux") : Lang.t("Tous les réseaux ({0})", root.inRange.length)
        onPicked: root.showAll = !root.showAll
    }

    MenuRow {
        visible: Networking.wifiEnabled && !root.askingHidden
        Layout.fillWidth: true
        label: Lang.t("Réseau caché…")
        onPicked: {
            root.asking = "";
            root.askingHidden = true;
        }
    }

    MenuTitle {
        visible: root.cables.length > 0
        Layout.topMargin: 6
        text: Lang.t("Câble")
    }

    Repeater {
        model: root.cables

        MenuRow {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.name
            active: modelData.active
            onPicked: root.switchOver(modelData)
        }
    }

    MenuTitle {
        visible: root.vpns.length > 0
        Layout.topMargin: 6
        text: "VPN"
    }

    Repeater {
        model: root.vpns

        MenuRow {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.name
            active: modelData.active
            onPicked: root.switchOver(modelData)
        }
    }

    MenuRow {
        Layout.fillWidth: true
        Layout.topMargin: 6
        label: Lang.t("Plus de réglages…")
        onPicked: root.openSettings()
    }
}
