import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.services

// The machine in a porthole, as a constellation: a star per core, memory as the nebula
// behind, comets for the network, and the numbers along the bottom. The card warms up
// when the processor does.
Item {
    id: root

    property var options: ({})
    readonly property string readings: (options?.readings ?? ["cpu", "memory", "network", "temperature"]).join()

    property var snap: ({ cpu: 0, memory: 0, download: 0, upload: 0, temperature: 0, cores: 0 })

    Binding on snap {
        when: Planet.pageEmpty || root.snap.cores === 0
        value: ({ cpu: Machine.cpu, memory: Machine.memory, download: Machine.download, upload: Machine.upload, temperature: Machine.temperature, cores: Machine.cores.length })
        restoreMode: Binding.RestoreNone
    }

    implicitWidth: 360
    implicitHeight: 230

    HandCard {
        anchors.fill: parent
        seed: "system"
        tint: root.snap.cpu > 0.8 ? "#f0705f" : "#8fc7e8"
        rise: 0.06 + root.snap.cpu * 0.16
        alive: Planet.pageEmpty
    }

    CoreConstellation {
        x: 20
        y: 18
        width: parent.width - 40
        height: 120
        ink: Theme.text
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 22
        spacing: 12

        Repeater {
            model: [
                { id: "cpu", label: root.snap.cores ? Lang.t("{0} cœurs", root.snap.cores) : Lang.t("Processeur"), value: `${Math.round(root.snap.cpu * 100)} %` },
                { id: "memory", label: Lang.t("Mémoire"), value: `${Math.round(root.snap.memory * 100)} %` },
                { id: "network", label: `↑ ${Machine.rate(root.snap.upload)}`, value: `↓ ${Machine.rate(root.snap.download)}` },
                { id: "temperature", label: Lang.t("Chaleur"), value: root.snap.temperature ? `${Math.round(root.snap.temperature)}°` : "–" }
            ].filter(reading => (root?.readings ?? "").includes(reading.id))

            ColumnLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: parent.modelData.label
                    color: Qt.alpha(Theme.text, 0.6)
                    font.family: Theme.font
                    font.pixelSize: 10
                }

                Text {
                    text: parent.modelData.value
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 17
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
