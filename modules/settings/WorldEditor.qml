import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.config
import qs.modules.background
import qs.modules.bar
import qs.services

// Everything a world is made of, to change after the fact. Changes are kept apart from the
// world itself, so going back to how it came is one click away. The world you live on
// changes around you as you go.
ColumnLayout {
    id: root

    required property string planetId
    readonly property var planet: Planets.find(planetId)
    property int picked: 0 // which colour the three sliders are changing

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

    function colorOf(key) {
        return /^t[0-3]$/.test(key) ? planet.terrain[Number(key[1])] : planet[key];
    }

    function setColor(key, color) {
        if (/^t[0-3]$/.test(key)) {
            const terrain = planet.terrain.slice();
            terrain[Number(key[1])] = String(color);
            Planets.tweak(planetId, { terrain: terrain });
        } else {
            Planets.tweak(planetId, { [key]: String(color) });
        }
    }

    function setStyle(setting, value) {
        Planets.tweak(planetId, { style: Object.assign({}, planet.style ?? {}, { [setting]: value }) });
    }

    spacing: 14

    // The world as it is right now, small
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: width * 0.42

        World {
            anchors.fill: parent
            planet: root.planet
            arrival: 0
            listening: false
            takesWallpaper: false
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

    SettingSection {
        text: Lang.t("Couleurs")
    }

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

    SettingSection {
        text: Lang.t("Sol et ciel")
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
        label: Lang.t("Crêtes")
        hint: Lang.t("Des houles douces, ou de la roche brisée.")
        value: root.planet.rough ?? 1
        shownAs: 100
        unit: " %"
        onMoved: value => Planets.tweak(root.planetId, { rough: value })
    }

    SettingChoice {
        label: Lang.t("Décor")
        hint: Lang.t("Ce qui se tient dans son ciel et sur son sol.")
        options: [{ id: "none", label: Lang.t("Aucun") }, { id: "Aster", label: Lang.t("Anneaux") }]
        current: Planets.sceneOf(root.planet) || "none"
        onPicked: id => Planets.tweak(root.planetId, { scenery: id === "none" ? "" : id })
    }

    SettingRow {
        label: Lang.t("Image du ciel")
        hint: root.planet.sky ? root.planet.sky.split("/").pop() : Lang.t("Le ciel est peint.")

        Row {
            spacing: 8

            SettingButton {
                label: root.planet.sky ? Lang.t("Changer") : Lang.t("Choisir une image")
                onPicked: Forge.chooseSky(root.planetId)
            }

            SettingButton {
                visible: (root.planet.sky ?? "") !== ""
                label: Lang.t("Retirer")
                quiet: true
                onPicked: Forge.dropSky(root.planetId)
            }
        }
    }

    SettingSwitch {
        label: Lang.t("Collines")
        hint: Lang.t("Sans elles, le ciel est seul à l'écran.")
        on: root.planet.ground ?? true
        onToggled: Planets.tweak(root.planetId, { ground: !on })
    }

    SettingSection {
        text: Lang.t("Son style")
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: Lang.t("Porté partout où un réglage suit la planète.")
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

    SettingButton {
        visible: Config.planetTweaks[root.planetId] !== undefined
        label: Lang.t("Revenir à l'original")
        quiet: true
        onPicked: Planets.untweak(root.planetId)
    }
}
