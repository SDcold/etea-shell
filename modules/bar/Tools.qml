import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config
import qs.services

// Little tools within reach: capture, clipboard, colour picker, night light, microphone.
Row {
    id: root

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool wanted: Config.barTools.length > 0

    spacing: Math.round(Theme.barSpacing * 0.8)

    PwObjectTracker {
        objects: root.source ? [root.source] : []
    }

    Process {
        id: picker

        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    announcer.exec(["notify-send", "-a", "Pipette", "Couleur copiée", text.trim()]);
            }
        }
    }

    Process {
        id: announcer
    }

    Repeater {
        model: Config.barTools

        Item {
            id: tool

            required property string modelData
            readonly property bool on: modelData === "nightlight" ? NightLight.on : modelData === "microphone" ? !(root.source?.audio?.muted ?? true) : false

            implicitWidth: Theme.iconSize
            implicitHeight: Theme.iconSize

            Icon {
                anchors.centerIn: parent
                name: tool.modelData === "microphone" && !tool.on ? "microphone-off" : Config.toolChoices.find(choice => choice.id === tool.modelData)?.icon ?? ""
                size: Theme.iconSize
                tint: tool.on ? Theme.windowLit : Theme.text
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -5
                cursorShape: Qt.PointingHandCursor
                onPressed: {
                    switch (tool.modelData) {
                    case "capture":
                        Menus.captureOpen = true;
                        break;
                    case "clipboard":
                        Menus.clipboardOpen = !Menus.clipboardOpen;
                        break;
                    case "picker":
                        picker.running = true;
                        break;
                    case "nightlight":
                        NightLight.toggle();
                        break;
                    case "microphone":
                        if (root.source?.audio)
                            root.source.audio.muted = !root.source.audio.muted;
                        break;
                    }
                }
            }
        }
    }
}
