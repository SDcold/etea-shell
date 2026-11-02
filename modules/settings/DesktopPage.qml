import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// The sky, the ground and what lives on an empty page.
ColumnLayout {
    id: root

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

    // Every kind of widget, out in the sky or not. Where they stand is set on the desktop itself.
    Repeater {
        model: Desk.catalog

        SettingSwitch {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.label
            on: Desk.shown.includes(modelData.type)
            onToggled: on ? Desk.remove(modelData.type) : Desk.add(modelData.type)
        }
    }

    Text {
        Layout.fillWidth: true
        text: Lang.t("Sur le bureau : Super + glisser pour déplacer un widget, Super + molette pour sa taille, clic droit pour ses options.")
        wrapMode: Text.WordWrap
        color: Qt.alpha(Theme.text, 0.55)
        font.family: Theme.font
        font.pixelSize: 12
    }
}
