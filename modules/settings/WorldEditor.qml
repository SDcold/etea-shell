import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.config
import qs.modules.background
import qs.modules.bar
import qs.services

// Everything a world is made of, to change after the fact, one stratum at a time: its
// colours, its sky, its ground, its sun, what hangs in its sky and its style. The world
// stays in view above while you change it, and each stratum can be taken from another
// world or put back as it came.
ColumnLayout {
    id: root

    required property string planetId
    readonly property var planet: Planets.find(planetId)
    property int picked: 0 // which colour the three sliders are changing
    property string tab: "teintes" // the stratum open below the world
    // The strata in the order they're changed most, each with its tab
    readonly property var tabs: ["teintes", "ciel", "relief", "soleil", "astres", "allure"].map(id => Morph.strata.find(stratum => stratum.id === id))

    signal back // back to every world

    readonly property var colors: [
        { key: "skyTop", label: Lang.t("Haut du ciel") },
        { key: "skyMid", label: Lang.t("Milieu du ciel") },
        { key: "skyLow", label: Lang.t("Bas du ciel") },
        { key: "t0", label: Lang.t("Collines lointaines") },
        { key: "t1", label: Lang.t("Collines") },
        { key: "t2", label: Lang.t("Collines") },
        { key: "t3", label: Lang.t("Collines proches") },
        { key: "light", label: Lang.t("Lumière") }
    ]
    readonly property color current: colorOf(colors[picked].key)

    readonly property var others: Planets.all.filter(other => other.id !== planetId).map(other => ({ id: other.id, label: other.name }))
    readonly property var forms: [{ id: "ridges", label: Lang.t("Crêtes") }, { id: "tables", label: Lang.t("Tables") }, { id: "dunes", label: Lang.t("Dunes") }]

    function colorOf(key) {
        return /^t[0-3]$/.test(key) ? planet.terrain[Number(key[1])] : planet[key];
    }

    // Under the hand a colour follows at once; a whole set taken or put back comes as a day
    function setColor(key, color) {
        if (/^t[0-3]$/.test(key)) {
            const terrain = planet.terrain.slice();
            terrain[Number(key[1])] = String(color);
            Planets.tweak(planetId, { terrain: terrain });
        } else {
            Planets.tweak(planetId, { [key]: String(color) });
        }
    }

    // Picking a world's style makes that setting follow the planet, or it would show nowhere
    function setStyle(setting, value) {
        Planets.tweak(planetId, { style: Object.assign({}, planet.style ?? {}, { [setting]: value }) });
        if (Config[setting] !== "planet")
            Config[setting] = "planet";
    }

    spacing: 12

    // Back to every world, and this one's name
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Item {
            implicitWidth: 30
            implicitHeight: 30

            Rectangle {
                anchors.fill: parent
                radius: 15
                color: Theme.windowLit
                opacity: backPointer.containsMouse ? 0.12 : 0
            }

            Icon {
                anchors.centerIn: parent
                name: "caret-left"
                size: 18
                tint: Theme.text
            }

            MouseArea {
                id: backPointer

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        Text {
            text: Lang.t("Mondes")
            color: Qt.alpha(Theme.text, 0.6)
            font.family: Theme.font
            font.pixelSize: 13
        }

        Item {
            Layout.fillWidth: true
        }
    }

    // The world as it is right now, small
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: width * 0.3

        World {
            anchors.fill: parent
            planet: root.planet
            arrival: 0
            listening: false
            showWidgets: false
            cached: false
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: corners
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
        }

        Rectangle {
            id: corners

            anchors.fill: parent
            radius: 18
            visible: false
            layer.enabled: true
        }
    }


    // Its name and its line, written straight in
    Repeater {
        model: [{ key: "name", size: 22 }, { key: "line", size: 14 }]

        TextInput {
            required property var modelData

            Layout.fillWidth: true
            text: root.planet[modelData.key] ?? ""
            color: modelData.key === "name" ? Theme.text : Qt.alpha(Theme.text, 0.75)
            selectByMouse: true
            font.family: Theme.font
            font.pixelSize: modelData.size
            onEditingFinished: {
                if (text.trim() && text !== root.planet[modelData.key])
                    Planets.tweak(root.planetId, { [modelData.key]: text.trim() });
            }

            Rectangle {
                anchors.top: parent.bottom
                anchors.topMargin: 2
                width: parent.width
                height: 1
                color: Qt.alpha(Theme.text, parent.activeFocus ? 0.5 : 0.15)
            }
        }
    }


    // One tab per stratum, a lit star under the one open
    Item {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 46

        Row {
            id: tabRow

            spacing: 4

            Repeater {
                id: tabChips

                model: root.tabs

                Item {
                    id: chip

                    required property var modelData
                    readonly property bool open: modelData.id === root.tab
                    readonly property bool changed: modelData.keys.some(key => (Config.planetTweaks[root.planetId] ?? {})[key] !== undefined)

                    width: name.implicitWidth + 28
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        color: Theme.windowLit
                        opacity: chip.open ? 0.16 : tabPointer.containsMouse ? 0.08 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.fast }
                        }
                    }

                    Text {
                        id: name

                        anchors.centerIn: parent
                        text: chip.modelData.label
                        color: chip.open ? Theme.text : Qt.alpha(Theme.text, 0.65)
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: chip.open ? Font.Medium : Font.Normal
                    }

                    // A stratum you've changed on this world says so
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 5
                        width: 5
                        height: 5
                        radius: 2.5
                        visible: chip.changed
                        color: Theme.link
                    }

                    MouseArea {
                        id: tabPointer

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = chip.modelData.id
                    }
                }
            }
        }

        Star {
            readonly property Item under: (tabChips.count, tabChips.itemAt(root.tabs.findIndex(stratum => stratum.id === root.tab)))

            x: (under ? under.x + under.width / 2 : 0) - size
            y: 40 - size
            size: 5
            lit: true
            animated: false

            Behavior on x {
                NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }
        }
    }

    // What the open stratum is made of
    ColumnLayout {
        id: content

        Layout.fillWidth: true
        spacing: 14
        // A tab opening rises into place
        transform: Translate {
            id: rise
        }

        // Teintes: pick a colour, then slide it
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === "teintes"
            spacing: 12

            // Pick a colour, then slide it
            Row {
                spacing: 8

                Repeater {
                    model: root.colors

                    Item {
                        id: swatch

                        required property var modelData
                        required property int index

                        width: 34
                        height: 34

                        Rectangle {
                            anchors.centerIn: parent
                            width: swatch.index === root.picked ? 34 : 26
                            height: width
                            radius: width / 2
                            color: root.colorOf(swatch.modelData.key)
                            border.width: swatch.index === root.picked ? 2 : 0
                            border.color: Theme.text

                            Behavior on width {
                                NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: root.picked = swatch.index
                        }
                    }
                }
            }

            Text {
                text: root.colors[root.picked].label
                color: Qt.alpha(Theme.text, 0.75)
                font.family: Theme.font
                font.pixelSize: 13
            }

            SettingSlider {
                label: Lang.t("Teinte")
                value: Math.max(0, root.current.hsvHue)
                shownAs: 360
                unit: "°"
                onMoved: value => root.setColor(root.colors[root.picked].key, Qt.hsva(value, root.current.hsvSaturation, root.current.hsvValue, 1))
            }

            SettingSlider {
                label: Lang.t("Saturation")
                value: root.current.hsvSaturation
                shownAs: 100
                unit: " %"
                onMoved: value => root.setColor(root.colors[root.picked].key, Qt.hsva(Math.max(0, root.current.hsvHue), value, root.current.hsvValue, 1))
            }

            SettingSlider {
                label: Lang.t("Luminosité")
                value: root.current.hsvValue
                shownAs: 100
                unit: " %"
                onMoved: value => root.setColor(root.colors[root.picked].key, Qt.hsva(Math.max(0, root.current.hsvHue), root.current.hsvSaturation, value, 1))
            }
        }

        // Ciel: a picture, or the world's painted sky
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === "ciel"
            spacing: 12

            SettingRow {
                label: Lang.t("Image du ciel")
                hint: root.planet.sky ? root.planet.sky.split("/").pop() : Lang.t("Le ciel est peint.")

                Row {
                    spacing: 8

                    SettingButton {
                        id: chooseSky

                        label: root.planet.sky ? Lang.t("Changer") : Lang.t("Choisir une image")
                        onPicked: Forge.chooseSky(root.planetId, chooseSky)
                    }

                    SettingButton {
                        visible: (root.planet.sky ?? "") !== ""
                        label: Lang.t("Retirer")
                        quiet: true
                        onPicked: Forge.dropSky(root.planetId)
                    }
                }
            }
        }

        // Relief: the ground's forms, how high and how rough, and whether it's there at all
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === "relief"
            spacing: 12

            SettingSwitch {
                label: Lang.t("Collines")
                hint: Lang.t("Sans elles, le ciel est seul à l'écran.")
                on: Planets.groundOf(root.planet)
                onToggled: Morph.apply(root.planetId, { ground: !on })
            }

            // The far ground and the near one each take a form; a new one runs in as a front
            SettingChoice {
                label: Lang.t("Au loin")
                options: root.forms
                current: root.planet.form?.far ?? "ridges"
                onPicked: id => Morph.apply(root.planetId, { form: Object.assign({ far: "ridges", near: "ridges" }, root.planet.form ?? {}, { far: id }) })
            }

            SettingChoice {
                label: Lang.t("Au premier plan")
                options: root.forms
                current: root.planet.form?.near ?? "ridges"
                onPicked: id => Morph.apply(root.planetId, { form: Object.assign({ far: "ridges", near: "ridges" }, root.planet.form ?? {}, { near: id }) })
            }

            SettingSlider {
                label: Lang.t("Hauteur des collines")
                value: root.planet.relief ?? 1
                minimum: 0.2
                maximum: 1.8
                shownAs: 100
                unit: " %"
                onMoved: value => Planets.tweak(root.planetId, { relief: value })
            }

            SettingSlider {
                label: Lang.t("Graine")
                hint: Lang.t("Déplace les crêtes et les continents.")
                value: root.planet.seed ?? 1.2
                minimum: 0
                maximum: 12
                shownAs: 10
                onMoved: value => Planets.tweak(root.planetId, { seed: value })
            }

            SettingSlider {
                label: Lang.t("Crêtes")
                hint: Lang.t("Des houles douces, ou de la roche brisée.")
                value: root.planet.rough ?? 1
                shownAs: 100
                unit: " %"
                onMoved: value => Planets.tweak(root.planetId, { rough: value })
            }
        }

        // Soleil: where the light comes from
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === "soleil"
            spacing: 12

            SettingSlider {
                label: Lang.t("Soleil")
                hint: Lang.t("D'où vient la lumière, le long de l'horizon.")
                value: root.planet.sun ?? 0.25
                shownAs: 100
                unit: " %"
                onMoved: value => Planets.tweak(root.planetId, { sun: value })
            }

            SettingSwitch {
                label: Lang.t("Faces taillées")
                hint: Lang.t("Les pentes tournées vers le soleil, un ton plus clair.")
                on: root.planet.cut ?? false
                onToggled: Planets.tweak(root.planetId, { cut: !on })
            }
        }

        // Astres: what hangs in its sky
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === "astres"
            spacing: 12

            SettingChoice {
                label: Lang.t("Décor")
                hint: Lang.t("Ce qui se tient dans son ciel et sur son sol.")
                options: [{ id: "none", label: Lang.t("Aucun") }, { id: "Aster", label: Lang.t("Anneaux") }]
                current: Planets.sceneOf(root.planet) || "none"
                onPicked: id => Morph.apply(root.planetId, { scenery: id === "none" ? "" : id })
            }
        }

        // Allure: the shell's own style while you live here
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.tab === "allure"
            spacing: 12

            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: Lang.t("Choisir l'un d'eux fait suivre la planète à ce réglage : chaque monde porte alors le sien.")
                color: Qt.alpha(Theme.text, 0.6)
                font.family: Theme.font
                font.pixelSize: 12
            }

            SettingChoice {
                label: Lang.t("Barre")
                options: [{ id: "sky", label: Lang.t("Ciel nu") }, { id: "islands", label: Lang.t("Îlots") }, { id: "band", label: Lang.t("Bande") }]
                current: root.planet.style?.barStyle ?? "sky"
                onPicked: id => root.setStyle("barStyle", id)
            }

            SettingChoice {
                label: Lang.t("Pages")
                options: [{ id: "constellation", label: Lang.t("Constellations") }, { id: "numbers", label: Lang.t("Numéros") }]
                current: root.planet.style?.pageStyle ?? "constellation"
                onPicked: id => root.setStyle("pageStyle", id)
            }

            SettingChoice {
                label: Lang.t("Widgets")
                options: [{ id: "sky", label: Lang.t("Ciel") }, { id: "celestial", label: Lang.t("Cadran céleste") }]
                current: root.planet.style?.widgetStyle ?? "sky"
                onPicked: id => root.setStyle("widgetStyle", id)
            }

            SettingChoice {
                label: Lang.t("Verrouillage")
                options: [{ id: "hand", label: Lang.t("La main tendue") }, { id: "skyward", label: Lang.t("Sous les étoiles") }]
                current: root.planet.style?.lockScene ?? "hand"
                onPicked: id => root.setStyle("lockScene", id)
            }
        }

        // This stratum from another world, or back as it came
        SettingChoice {
            id: borrow

            readonly property var stratum: Morph.strata.find(s => s.id === root.tab)
            readonly property string from: root.planet.borrowed?.[root.tab] ?? ""
            readonly property bool changed: stratum.keys.some(key => (Config.planetTweaks[root.planetId] ?? {})[key] !== undefined)

            Layout.topMargin: 6
            label: Lang.t("Prendre à…")
            hint: from ? Lang.t("comme sur {0}", Planets.find(from).name) : Lang.t("Le même, pris à un autre de tes mondes.")
            options: root.others.concat(changed ? [{ id: "back", label: Lang.t("Revenir") }] : [])
            current: from
            onPicked: id => id === "back" ? Morph.revert(root.planetId, root.tab) : Morph.borrow(root.planetId, id, [root.tab])
        }

    }

    // The whole world at once
    SettingSection {
        text: Lang.t("Tout le monde")
    }

    SettingChoice {
        label: Lang.t("Tout prendre")
        hint: Lang.t("Une seule vague : l'aube porte les couleurs, le relief suit le même bord.")
        options: root.others
        current: ""
        onPicked: id => Morph.borrow(root.planetId, id)
    }

    SettingButton {
        visible: Config.planetTweaks[root.planetId] !== undefined
        label: Lang.t("Revenir à l'original")
        quiet: true
        onPicked: Morph.apply(root.planetId, null, true)
    }

    onTabChanged: switching.restart()

    SequentialAnimation {
        id: switching

        PropertyAction { target: content; property: "opacity"; value: 0 }
        PropertyAction { target: rise; property: "y"; value: 10 }
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: rise; property: "y"; to: 0; duration: 260; easing.type: Easing.OutCubic }
        }
    }
}
