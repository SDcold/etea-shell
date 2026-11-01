import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.modules.stage

// Which planet you live on. Each one is alive, and picking it changes everything at once.
ColumnLayout {
    spacing: 18

    Text {
        text: "Choisis ton monde"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Tu peux aussi les rejoindre en vrai : Super + Tab deux fois, puis Entrée pour te poser."
        color: Qt.alpha(Theme.text, 0.65)
        font.family: Theme.font
        font.pixelSize: 13
    }

    GridLayout {
        columns: 2
        rowSpacing: 16
        columnSpacing: 16
        Layout.fillWidth: true

        Repeater {
            model: Planets.all

            Item {
                id: choice

                required property var modelData

                readonly property bool current: modelData.id === Theme.planet.id

                Layout.fillWidth: true
                Layout.preferredHeight: 164

                HandCard {
                    id: card

                    anchors.fill: parent
                    seed: choice.modelData.id
                    tint: choice.modelData.light
                    ink: choice.current ? 1 : 0.5
                    rise: 0.08
                }

                PlanetView {
                    x: -18
                    y: 2
                    width: 160
                    height: 160
                    planet: choice.modelData
                    spinning: true
                }

                Column {
                    x: 148
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - 16
                    spacing: 2

                    Text {
                        text: choice.modelData.name
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 19
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: choice.modelData.line
                        color: Qt.alpha(Theme.text, 0.7)
                        font.family: Theme.font
                        font.pixelSize: 13
                    }

                    Text {
                        visible: choice.current
                        topPadding: 6
                        text: "Tu vis ici"
                        color: choice.modelData.light
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                StarRipple {
                    id: ripple
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => {
                        ripple.burst(mouse.x, mouse.y);
                        Config.theme = choice.modelData.id;
                    }
                }
            }
        }
    }
}
