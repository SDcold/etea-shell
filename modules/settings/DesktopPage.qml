import QtQuick
import QtQuick.Layouts
import qs.config

// The sky, the ground and what lives on an empty page.
ColumnLayout {
    id: root

    function shown(type) {
        return Config.widgets.find(widget => widget.type === type)?.shown !== false;
    }

    function toggle(type) {
        Config.widgets = Config.widgets.map(widget => widget.type === type ? Object.assign({}, widget, { shown: widget.shown === false }) : widget);
    }

    spacing: 18

    Text {
        text: "Bureau"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingChoice {
        label: "Musique sur le terrain"
        hint: "Visible sur les pages vides."
        options: [{ id: "lines", label: "Lignes" }, { id: "bars", label: "Barres" }, { id: "off", label: "Rien" }]
        current: Config.groundMusic
        onPicked: id => Config.groundMusic = id
    }

    SettingSlider {
        label: "Hauteur de la musique"
        value: Config.groundLift
        minimum: 40
        maximum: 200
        onMoved: value => Config.groundLift = Math.round(value)
    }

    SettingSlider {
        label: "Hauteur du terrain"
        value: Config.terrainHeight
        minimum: 0.04
        maximum: 0.24
        shownAs: 100
        unit: " %"
        onMoved: value => Config.terrainHeight = value
    }

    SettingSlider {
        label: "Relief"
        hint: "De doux à très accidenté."
        value: Config.terrainRelief
        maximum: 2.5
        decimals: 1
        onMoved: value => Config.terrainRelief = value
    }

    SettingChoice {
        label: "Style des widgets"
        hint: "Ciel écrit à même le ciel. Cadran céleste range tout dans des hublots."
        options: [{ id: "sky", label: "Ciel" }, { id: "celestial", label: "Cadran céleste" }]
        current: Config.widgetStyle
        onPicked: id => Config.widgetStyle = id
    }

    SettingSwitch {
        label: "Horloge"
        on: root.shown("clock")
        onToggled: root.toggle("clock")
    }

    SettingSwitch {
        label: "Instruments du système"
        on: root.shown("system")
        onToggled: root.toggle("system")
    }

    SettingSwitch {
        label: "Lecteur de musique"
        on: root.shown("media")
        onToggled: root.toggle("media")
    }
}
