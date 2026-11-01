import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config

// How loud, and where the sound goes.
ColumnLayout {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var outputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio)

    // The horizon climbs with the volume
    readonly property color cardTint: "#e98fb0"
    readonly property real cardRise: 0.05 + Math.min(1, (sink?.audio.volume ?? 0)) * 0.3

    spacing: 6
    width: 320

    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node)
    }

    MenuTitle {
        text: "Sortie"
    }

    MenuSlider {
        Layout.fillWidth: true
        value: root.sink?.audio.volume ?? 0
        maximum: 1.5
        onMoved: value => root.sink.audio.volume = value
    }

    MenuTitle {
        Layout.topMargin: 6
        text: "Micro"
    }

    MenuSlider {
        Layout.fillWidth: true
        value: root.source?.audio.volume ?? 0
        maximum: 1.5
        onMoved: value => root.source.audio.volume = value
    }

    MenuTitle {
        Layout.topMargin: 6
        visible: root.outputs.length > 1
        text: "Écouter sur"
    }

    Repeater {
        model: root.outputs.length > 1 ? root.outputs : []

        MenuRow {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.description || modelData.name
            active: modelData === root.sink
            onPicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
}
