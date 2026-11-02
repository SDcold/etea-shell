import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.config
import qs.modules.bar
import qs.modules.bar.menus
import qs.modules.notifications
import qs.services

// The control centre: quick settings, sound and light, what's playing and every message.
ColumnLayout {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var network: {
        const wifi = Networking.devices.values.find(device => device.networks !== undefined);
        return wifi?.networks.values.find(network => network.connected) ?? null;
    }
    readonly property var paired: Bluetooth.devices.values.find(device => device.connected) ?? null
    readonly property var profiles: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
    readonly property var profileNames: ["Économie", "Équilibré", "Performance"]

    spacing: 14

    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node)
    }

    Component.onCompleted: Brightness.refresh()

    // The charge, then the way to the settings and out of the session
    RowLayout {
        Layout.fillWidth: true

        Column {
            Layout.fillWidth: true

            Text {
                text: root.battery?.isLaptopBattery ? `${Math.round(root.battery.percentage * 100)} %` : Qt.formatTime(new Date(), "HH:mm")
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 34
                font.weight: Font.Light
            }

            Text {
                text: UPower.onBattery ? "Sur batterie" : "Sur secteur"
                color: Qt.alpha(Theme.text, 0.6)
                font.family: Theme.font
                font.pixelSize: 12
            }
        }

        Repeater {
            model: [
                { icon: "gear-six", run: () => Menus.settingsOpen = true },
                { icon: "power", run: () => Menus.sessionOpen = true }
            ]

            Item {
                required property var modelData

                Layout.preferredWidth: 42
                Layout.preferredHeight: 42

                Rectangle {
                    anchors.fill: parent
                    radius: 21
                    color: Qt.alpha(Theme.windowLit, pointer.containsMouse ? 0.18 : 0.08)
                }

                Icon {
                    anchors.centerIn: parent
                    name: parent.modelData.icon
                    size: 20
                }

                MouseArea {
                    id: pointer

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: {
                        Menus.closePanel("right");
                        parent.modelData.run();
                    }
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: 10
        columnSpacing: 10

        QuickTile {
            icon: Networking.wifiEnabled ? "wifi-high" : "wifi-slash"
            label: "Wi-Fi"
            detail: root.network?.name ?? (Networking.wifiEnabled ? "Recherche" : "Coupé")
            on: Networking.wifiEnabled
            tint: "#8fc7e8"
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }

        QuickTile {
            icon: root.adapter?.enabled ? "bluetooth" : "bluetooth-slash"
            label: "Bluetooth"
            detail: root.paired?.name ?? (root.adapter?.enabled ? "Allumé" : "Coupé")
            on: root.adapter?.enabled ?? false
            available: root.adapter !== null
            tint: "#b9a2f0"
            onToggled: root.adapter.enabled = !root.adapter.enabled
        }

        QuickTile {
            icon: Notifs.quiet ? "bell-slash" : "bell"
            label: "Silence"
            detail: Notifs.quiet ? "Activé" : ""
            on: Notifs.quiet
            tint: "#e98fb0"
            onToggled: Notifs.quiet = !Notifs.quiet
        }

        QuickTile {
            icon: "nightlight"
            label: "Veilleuse"
            detail: NightLight.on ? `${NightLight.temperature} K` : ""
            on: NightLight.on
            available: NightLight.available
            tint: "#ffc98a"
            onToggled: NightLight.toggle()
        }

        QuickTile {
            icon: root.source?.audio?.muted ? "microphone-off" : "microphone"
            label: "Micro"
            detail: root.source?.audio?.muted ? "Coupé" : "Ouvert"
            on: !(root.source?.audio?.muted ?? true)
            available: root.source?.audio !== undefined
            tint: "#f59a7a"
            onToggled: root.source.audio.muted = !root.source.audio.muted
        }

        QuickTile {
            readonly property int current: Math.max(0, root.profiles.indexOf(PowerProfiles.profile))

            icon: "energy"
            label: "Énergie"
            detail: root.profileNames[current]
            on: PowerProfiles.profile !== PowerProfile.Balanced
            tint: "#8fd6b4"
            onToggled: {
                const next = root.profiles[(current + 1) % root.profiles.length];
                PowerProfiles.profile = next === PowerProfile.Performance && !PowerProfiles.hasPerformanceProfile ? PowerProfile.PowerSaver : next;
            }
        }
    }

    SliderRow {
        icon: root.sink?.audio?.muted ? "speaker-x" : "speaker-high"
        value: root.sink?.audio?.volume ?? 0
        maximum: 1
        tint: "#e98fb0"
        onMoved: value => root.sink.audio.volume = value
        onIconPressed: root.sink.audio.muted = !root.sink.audio.muted
    }

    SliderRow {
        icon: "brightness"
        value: Brightness.value
        tint: "#ffd08a"
        onMoved: value => Brightness.set(value)
    }

    // What's playing, when something is
    ColumnLayout {
        visible: Music.player !== null
        Layout.fillWidth: true
        spacing: 6

        ContentTint {
            id: colour

            image: Music.player?.trackArtUrl ?? ""
            name: Music.player?.trackTitle ?? "etea"
        }

        SectionTitle {
            text: "En écoute"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle {
                visible: cover.status === Image.Ready
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                radius: 12
                color: "transparent"

                Image {
                    id: cover

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(108, 108)
                    source: Music.player?.trackArtUrl ?? ""
                }
            }

            Column {
                Layout.fillWidth: true

                Text {
                    width: parent.width
                    text: Music.player?.trackTitle ?? ""
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                Text {
                    width: parent.width
                    text: Music.player?.trackArtist ?? ""
                    elide: Text.ElideRight
                    color: Qt.alpha(Theme.text, 0.65)
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
        }

        MediaProgress {
            Layout.fillWidth: true
            tint: colour.color
        }

        MediaControls {
            Layout.alignment: Qt.AlignHCenter
            tint: colour.color
        }
    }

    SectionTitle {
        text: Notifs.count ? `Signaux · ${Notifs.count}` : "Signaux"
        action: Notifs.count ? "Tout effacer" : ""
        onActed: Notifs.clear()
    }

    Text {
        visible: Notifs.count === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 8
        text: "Aucun signal. Le ciel est calme."
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 13
    }

    Repeater {
        model: Notifs.log.slice(0, 20)

        NotificationCard {
            required property var modelData

            Layout.fillWidth: true
            width: root.width
            entry: modelData
            inJournal: true
        }
    }
}
