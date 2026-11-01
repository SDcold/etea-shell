import QtQuick
import QtQuick.Layouts
import qs.config

// How the focused window catches the light.
ColumnLayout {
    spacing: 18

    Text {
        text: "Fenêtres"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingSlider {
        label: "Force de la lueur"
        value: Config.windowGlow
        shownAs: 100
        unit: " %"
        onMoved: value => Config.windowGlow = value
    }

    SettingSlider {
        label: "Taille de la lueur"
        value: Config.windowGlowSize
        minimum: 6
        maximum: 80
        unit: " px"
        onMoved: value => Config.windowGlowSize = Math.round(value)
    }

    SettingSlider {
        label: "Ombre des fenêtres inactives"
        value: Config.windowDim
        maximum: 0.6
        shownAs: 100
        unit: " %"
        onMoved: value => Config.windowDim = value
    }

    SettingSlider {
        label: "Épaisseur du cadre"
        value: Config.traceWidth
        minimum: 1
        maximum: 5
        unit: " px"
        onMoved: value => Config.traceWidth = Math.round(value)
    }

    SettingSlider {
        label: "Espace entre les étoiles"
        hint: "Plus c'est grand, moins il y a d'étoiles sur le cadre."
        value: Config.traceSpacing
        minimum: 120
        maximum: 800
        unit: " px"
        onMoved: value => Config.traceSpacing = Math.round(value)
    }

    SettingSlider {
        label: "Marge autour des fenêtres"
        value: Config.windowGapOuter
        minimum: 0
        maximum: 40
        unit: " px"
        onMoved: value => Config.windowGapOuter = Math.round(value)
    }
}
