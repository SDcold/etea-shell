import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config

// Battery, power profile and screen brightness.
ColumnLayout {
    id: root

    readonly property var battery: UPower.displayDevice
    property real brightness: 0

    function timeLeft() {
        const seconds = UPower.onBattery ? battery.timeToEmpty : battery.timeToFull;
        if (!seconds)
            return UPower.onBattery ? "Sur batterie" : "Sur secteur";
        const hours = Math.floor(seconds / 3600), minutes = Math.round(seconds % 3600 / 60);
        const left = hours ? `${hours} h ${String(minutes).padStart(2, "0")}` : `${minutes} min`;
        return UPower.onBattery ? `${left} restantes` : `Pleine dans ${left}`;
    }

    spacing: 6
    width: 320

    // Asks brightnessctl how bright the screen is, once when the menu opens
    Process {
        running: true
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const percent = text.split(",")[3];
                if (percent)
                    root.brightness = parseInt(percent) / 100;
            }
        }
    }

    Process {
        id: setBrightness
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: `${Math.round((root.battery?.percentage ?? 0) * 100)} %`
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 26
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: root.battery?.isLaptopBattery ? root.timeLeft() : ""
            color: Qt.alpha(Theme.text, 0.6)
            font.family: Theme.font
            font.pixelSize: 14
        }
    }

    MenuTitle {
        Layout.topMargin: 6
        text: "Énergie"
    }

    Repeater {
        model: [
            { label: "Économie", profile: PowerProfile.PowerSaver },
            { label: "Équilibré", profile: PowerProfile.Balanced },
            { label: "Performance", profile: PowerProfile.Performance }
        ]

        MenuRow {
            required property var modelData

            Layout.fillWidth: true
            visible: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
            label: modelData.label
            active: PowerProfiles.profile === modelData.profile
            onPicked: PowerProfiles.profile = modelData.profile
        }
    }

    MenuTitle {
        Layout.topMargin: 6
        text: "Luminosité"
    }

    MenuSlider {
        Layout.fillWidth: true
        value: root.brightness
        onMoved: value => {
            root.brightness = Math.max(0.02, value);
            setBrightness.exec(["brightnessctl", "s", `${Math.round(root.brightness * 100)}%`]);
        }
    }
}
