import QtQuick
import qs.config
import qs.services

// The machine written on the sky as a constellation: a star per core, memory as the
// nebula behind, comets for the network. The numbers sit underneath, small and quiet.
Column {
    id: root

    property real sky: 1080
    property var options: ({})
    // Kept as text, so moving the widget doesn't rebuild its readings
    readonly property string readings: (options?.readings ?? ["cpu", "memory", "network", "temperature"]).join()

    // The numbers, held still behind windows like the stars above them
    property var snap: ({ cpu: 0, memory: 0, download: 0, upload: 0, temperature: 0, cores: 0 })

    Binding on snap {
        when: Planet.pageEmpty || root.snap.cores === 0
        value: ({ cpu: Machine.cpu, memory: Machine.memory, download: Machine.download, upload: Machine.upload, temperature: Machine.temperature, cores: Machine.cores.length })
        restoreMode: Binding.RestoreNone
    }

    spacing: sky * 0.014
    width: sky * 0.36

    CoreConstellation {
        width: parent.width
        height: root.sky * 0.15
        ink: Desk.ink
    }

    Row {
        spacing: root.sky * 0.032

        Repeater {
            model: [
                { id: "cpu", label: root.snap.cores ? Lang.t("{0} cœurs", root.snap.cores) : Lang.t("Processeur"), value: `${Math.round(root.snap.cpu * 100)} %` },
                { id: "memory", label: Lang.t("Mémoire"), value: `${Math.round(root.snap.memory * 100)} %` },
                { id: "network", label: `↑ ${Machine.rate(root.snap.upload)}`, value: `↓ ${Machine.rate(root.snap.download)}` },
                { id: "temperature", label: Lang.t("Chaleur"), value: root.snap.temperature ? `${Math.round(root.snap.temperature)}°` : "–" }
            ].filter(reading => (root?.readings ?? "").includes(reading.id))

            Column {
                required property var modelData

                spacing: root.sky * 0.002

                Text {
                    text: parent.modelData.label
                    color: Qt.alpha(Desk.ink, 0.65)
                    font.family: Theme.font
                    font.pixelSize: root.sky * 0.013
                }

                Text {
                    text: parent.modelData.value
                    color: Desk.ink
                    font.family: Theme.font
                    font.pixelSize: root.sky * 0.03
                    font.weight: Font.Medium
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
