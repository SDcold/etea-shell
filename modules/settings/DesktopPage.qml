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
        text: Lang.t("Bureau")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingChoice {
        label: Lang.t("Musique sur le terrain")
        hint: Lang.t("Visible sur les pages vides.")
        options: [{ id: "lines", label: Lang.t("Lignes") }, { id: "bars", label: Lang.t("Barres") }, { id: "off", label: Lang.t("Rien") }]
        current: Config.groundMusic
        onPicked: id => Config.groundMusic = id
    }

    SettingSlider {
        label: Lang.t("Hauteur de la musique")
        value: Config.groundLift
        minimum: 40
        maximum: 200
        onMoved: value => Config.groundLift = Math.round(value)
    }

    SettingSlider {
        label: Lang.t("Hauteur du terrain")
        value: Config.terrainHeight
        minimum: 0.04
        maximum: 0.24
        shownAs: 100
        unit: " %"
        onMoved: value => Config.terrainHeight = value
    }

    SettingSlider {
        label: Lang.t("Relief")
        hint: Lang.t("De doux à très accidenté.")
        value: Config.terrainRelief
        maximum: 2.5
        decimals: 1
        onMoved: value => Config.terrainRelief = value
    }

    SettingChoice {
        label: Lang.t("Style des widgets")
        hint: Lang.t("Ciel écrit à même le ciel. Cadran céleste range tout dans des hublots.")
        options: [{ id: "sky", label: Lang.t("Ciel") }, { id: "celestial", label: Lang.t("Cadran céleste") }]
        current: Config.widgetStyle
        onPicked: id => Config.widgetStyle = id
    }

    SettingSwitch {
        label: Lang.t("Horloge")
        on: root.shown("clock")
        onToggled: root.toggle("clock")
    }

    SettingSwitch {
        label: Lang.t("Instruments du système")
        on: root.shown("system")
        onToggled: root.toggle("system")
    }

    SettingSwitch {
        label: Lang.t("Lecteur de musique")
        on: root.shown("media")
        onToggled: root.toggle("media")
    }
}
