import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.modules.stage
import qs.services

// Which planet you live on. Each one is alive, and picking it changes everything at once.
ColumnLayout {
    spacing: 18

    Text {
        text: Lang.t("Choisis ton monde")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: Lang.t("Tu peux aussi les rejoindre en vrai : Super + Tab deux fois, puis Entrée pour te poser.")
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
                        text: Lang.t("Tu vis ici")
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
                        Planet.changeWorld(choice.modelData.id);
                    }
                }

                // Planets you made yourself can be let go
                Icon {
                    visible: choice.modelData.id.startsWith("forge-")
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    name: "close"
                    size: 18

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onPressed: Forge.forget(choice.modelData.id)
                    }
                }
            }
        }
    }

    // Every setting a world can bring, switched over at once. Off keeps what's worn now.
    SettingSwitch {
        readonly property var styles: ["barStyle", "pageStyle", "widgetStyle", "lockScene"]

        Layout.fillWidth: true
        label: Lang.t("Chaque planète a son style")
        hint: Lang.t("La barre, les pages, les widgets et l'écran de verrouillage prennent le style du monde où tu vis. Tu peux toujours en reprendre un à la main.")
        on: styles.every(setting => Config[setting] === "planet")
        onToggled: {
            const follow = !on;
            for (const setting of styles)
                Config[setting] = follow ? "planet" : Theme[setting];
        }
    }

    Text {
        Layout.topMargin: 8
        text: Lang.t("Créer ma planète")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: Lang.t("Donne une image, ETEA en tire un ciel, un terrain et une lumière.")
        color: Qt.alpha(Theme.text, 0.65)
        font.family: Theme.font
        font.pixelSize: 13
    }

    SettingButton {
        label: Forge.draft ? Lang.t("Choisir une autre image") : Lang.t("Choisir une image")
        onPicked: Forge.chooseImage()
    }

    // The new world, waiting for your decision
    Item {
        visible: Forge.draft !== null
        Layout.fillWidth: true
        Layout.preferredHeight: 190

        HandCard {
            anchors.fill: parent
            seed: Forge.draft?.id ?? "forge"
            tint: Forge.draft?.light ?? Theme.windowLit
            rise: 0.08
        }

        Loader {
            x: -10
            y: 5
            width: 180
            height: 180
            active: Forge.draft !== null

            sourceComponent: PlanetView {
                planet: Forge.draft
            }
        }

        ColumnLayout {
            x: 178
            y: 22
            width: parent.width - x - 22
            spacing: 10

            TextInput {
                id: planetName

                Layout.fillWidth: true
                text: Forge.draft?.name ?? ""
                color: Theme.text
                selectByMouse: true
                font.family: Theme.font
                font.pixelSize: 22
            }

            Row {
                spacing: 6

                Repeater {
                    model: Forge.draft ? [Forge.draft.skyTop, Forge.draft.skyMid, Forge.draft.skyLow].concat(Forge.draft.terrain) : []

                    Rectangle {
                        required property string modelData

                        width: 26
                        height: 26
                        radius: 13
                        color: modelData
                    }
                }
            }

            Row {
                spacing: 10

                SettingButton {
                    label: Lang.t("M'y installer")
                    onPicked: Forge.keep(planetName.text)
                }

                SettingButton {
                    label: Lang.t("Laisser filer")
                    quiet: true
                    onPicked: Forge.draft = null
                }
            }
        }
    }

    SettingSwitch {
        visible: Forge.draft !== null
        label: Lang.t("Garder l'image comme ciel")
        hint: Lang.t("Ton image devient le fond. Le terrain, la barre et les fenêtres prennent ses couleurs.")
        on: Forge.keepSky
        onToggled: Forge.keepSky = !Forge.keepSky
    }

    SettingSwitch {
        visible: Forge.draft !== null
        label: Lang.t("Garder le relief")
        hint: Lang.t("Les collines restent devant. Sans elles, ton image est seule à l'écran.")
        on: Forge.keepGround
        onToggled: Forge.keepGround = !Forge.keepGround
    }
}
