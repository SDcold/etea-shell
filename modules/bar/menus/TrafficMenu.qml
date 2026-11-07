import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.modules.bar
import qs.services

// Behind the speeds in the bar: how fast it goes both ways, how much went through since
// the computer started, and where you're connected, address by address.
ColumnLayout {
    id: root

    readonly property color cardTint: "#8fc7e8"
    readonly property real cardRise: 0.05 + Math.min(1, (Machine.download + Machine.upload) / 5242880) * 0.3

    property var links: [] // { device, type, name, mac, address, gateway, dns, address6 }, one per connection that's up
    property real received: 0 // bytes since boot, every interface but the loopback
    property real sent: 0

    spacing: 6
    width: 320

    // The devices that are up, then what NetworkManager knows about each
    Process {
        id: reader

        command: ["sh", "-c", `
            tail -n +3 /proc/net/dev | awk '$1 != "lo:" { split($0, side, ":"); split(side[2], n, " "); r += n[1]; s += n[9] } END { print r, s }'
            nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device | while IFS=: read -r device type state name; do
                [ "$state" = connected ] || continue
                case $type in wifi|ethernet) ;; *) continue ;; esac
                echo @
                echo "$device"; echo "$type"; echo "$name"
                nmcli -g GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS device show "$device"
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const [totals, ...devices] = text.split("@\n");
                const [received, sent] = totals.trim().split(" ").map(Number);
                root.received = received || 0;
                root.sent = sent || 0;
                // nmcli -g escapes the colons of a MAC address and joins several values with |
                const first = value => (value ?? "").split(" | ")[0].replace(/\\:/g, ":").trim();
                root.links = devices.map(part => {
                    const lines = part.split("\n");
                    return {
                        device: lines[0],
                        type: lines[1],
                        name: lines[2],
                        mac: first(lines[3]),
                        address: first(lines[4]).split("/")[0],
                        gateway: first(lines[5]),
                        dns: (lines[6] ?? "").split(" | ").filter(dns => dns).slice(0, 2).join(", "),
                        address6: (lines[7] ?? "").replace(/\\:/g, ":").split(" | ").map(address => address.split("/")[0].trim()).find(address => address && !address.startsWith("fe80")) ?? ""
                    };
                });
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: reader.running = true
    }

    MenuTitle {
        text: Lang.t("Débit")
    }

    MenuFact {
        Layout.fillWidth: true
        label: Lang.t("Réception")
        value: Machine.rate(Machine.download)
    }

    MenuFact {
        Layout.fillWidth: true
        label: Lang.t("Envoi")
        value: Machine.rate(Machine.upload)
    }

    MenuFact {
        Layout.fillWidth: true
        visible: root.received > 0
        label: Lang.t("Depuis l'allumage")
        value: `↓ ${Machine.size(root.received / 1024)}  ·  ↑ ${Machine.size(root.sent / 1024)}`
    }

    Repeater {
        model: root.links

        ColumnLayout {
            required property var modelData

            Layout.fillWidth: true
            spacing: 6

            MenuTitle {
                Layout.topMargin: 6
                text: `${modelData.type === "wifi" ? "Wi-Fi" : Lang.t("Câble")}  ·  ${modelData.name}`
            }

            MenuFact {
                Layout.fillWidth: true
                visible: modelData.address !== ""
                label: Lang.t("Adresse IP")
                value: modelData.address
            }

            MenuFact {
                Layout.fillWidth: true
                visible: modelData.address6 !== ""
                label: "IPv6"
                value: modelData.address6
            }

            MenuFact {
                Layout.fillWidth: true
                visible: modelData.gateway !== ""
                label: Lang.t("Passerelle")
                value: modelData.gateway
            }

            MenuFact {
                Layout.fillWidth: true
                visible: modelData.dns !== ""
                label: "DNS"
                value: modelData.dns
            }

            MenuFact {
                Layout.fillWidth: true
                label: Lang.t("Interface")
                value: modelData.mac ? `${modelData.device}  ·  ${modelData.mac}` : modelData.device
            }
        }
    }

    MenuFact {
        Layout.fillWidth: true
        visible: root.links.length === 0
        label: Lang.t("Hors ligne")
    }

    // Choosing a network is the Wi-Fi menu's job
    MenuRow {
        Layout.fillWidth: true
        Layout.topMargin: 6
        label: Lang.t("Wi-Fi et connexions…")
        onPicked: Menus.open = "network"
    }
}
