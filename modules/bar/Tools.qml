import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.services

// Little tools within reach: capture, clipboard, colour picker, night light, staying awake,
// microphone, wallpaper.
Row {
    id: root

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool wanted: Config.barTools.length > 0

    spacing: Math.round(Theme.barSpacing * 0.8)

    PwObjectTracker {
        objects: root.source ? [root.source] : []
    }

    Repeater {
        model: Config.barTools

        Item {
            id: tool

            required property string modelData
            readonly property bool on: modelData === "nightlight" ? NightLight.on : modelData === "awake" ? Wake.on : modelData === "microphone" ? !(root.source?.audio?.muted ?? true) : modelData === "wallpaper" ? (Config.planetTweaks[Config.theme]?.sky ?? "") !== "" : false

            implicitWidth: Theme.iconSize
            implicitHeight: Theme.iconSize

            Icon {
                anchors.centerIn: parent
                name: tool.modelData === "microphone" && !tool.on ? "microphone-off" : Config.toolChoices.find(choice => choice.id === tool.modelData)?.icon ?? ""
                size: Theme.iconSize
                tint: tool.on ? Theme.windowLit : Theme.text
            }

            Hover {
                onPressed: {
                    switch (tool.modelData) {
                    case "capture":
                        Menus.captureOpen = true;
                        break;
                    case "clipboard":
                        Menus.clipboardOpen = !Menus.clipboardOpen;
                        break;
                    case "picker":
                        Picker.pick();
                        break;
                    case "awake":
                        Wake.on = !Wake.on;
                        break;
                    case "nightlight":
                        NightLight.toggle();
                        break;
                    case "microphone":
                        if (root.source?.audio)
                            root.source.audio.muted = !root.source.audio.muted;
                        break;
                    // A short climb to the belt of skies: the world you're on takes the picture you
                    // land and its colours. No new planet, worlds are made in Settings.
                    case "wallpaper":
                        Skies.ask({ role: "sky", title: Lang.t("Un fond d'écran"), answer: null, from: null, planetId: Theme.planet.id });
                        break;
                    }
                }
            }
        }
    }
}
