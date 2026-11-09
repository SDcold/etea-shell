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

    // The music on the ground, on empty pages: its style, its size, how it moves
    SettingSection {
        text: Lang.t("Musique sur le sol")
        words: ["visualiseur", "visualizer", "cava", "spectre", "musique", "music", "égaliseur"]
    }

    SettingChoice {
        key: "groundMusic"
        label: Lang.t("Style")
        hint: Lang.t("Visible sur les pages vides, pendant qu'un lecteur joue.")
        options: [{ id: "lines", label: Lang.t("Lignes") }, { id: "bars", label: Lang.t("Barres") }, { id: "stars", label: Lang.t("Étoiles") }, { id: "off", label: Lang.t("Rien") }]
        current: Config.groundMusic
        onPicked: id => Config.groundMusic = id
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Config.groundMusic !== "off"
        spacing: 18

        SettingSlider {
            key: "groundLift"
            label: Lang.t("Hauteur")
            value: Config.groundLift
            minimum: 40
            maximum: 200
            onMoved: value => Config.groundLift = Math.round(value)
        }

        SettingSlider {
            key: "musicDensity"
            visible: Config.groundMusic !== "lines"
            label: Lang.t("Densité")
            hint: Lang.t("Combien de colonnes en travers de l'écran.")
            value: Config.musicDensity
            minimum: 16
            maximum: 120
            onMoved: value => Config.musicDensity = Math.round(value)
        }

        SettingSlider {
            key: "musicGain"
            label: Lang.t("Sensibilité")
            hint: Lang.t("Ce qu'elle fait d'un son faible.")
            value: Config.musicGain
            minimum: 0.4
            maximum: 2.5
            shownAs: 100
            unit: " %"
            onMoved: value => Config.musicGain = value
        }

        SettingSlider {
            key: "musicRise"
            label: Lang.t("Réaction")
            hint: Lang.t("À quelle vitesse elle répond au rythme.")
            value: Config.musicRise
            minimum: 0.1
            maximum: 0.9
            shownAs: 100
            unit: " %"
            onMoved: value => Config.musicRise = value
        }

        SettingSlider {
            key: "musicFall"
            label: Lang.t("Retombée")
            hint: Lang.t("À quelle vitesse elle redescend après un coup.")
            value: Config.musicFall
            minimum: 0.04
            maximum: 0.6
            shownAs: 100
            unit: " %"
            onMoved: value => Config.musicFall = value
        }

        SettingChoice {
            key: "musicColor"
            label: Lang.t("Couleur")
            options: [{ id: "accent", label: Lang.t("Touche de couleur") }, { id: "light", label: Lang.t("Lumière du ciel") }, { id: "ink", label: Lang.t("Encre des widgets") }, { id: "world", label: Lang.t("Lumière du monde") }]
            current: Config.musicColor
            onPicked: id => Config.musicColor = id
        }
    }

    // The ground itself
    SettingSection {
        text: Lang.t("Le sol")
    }

    SettingSwitch {
        key: "hillsOnPictures"
        label: Lang.t("Collines sur les images")
        hint: Lang.t("Un fond d'écran à toi laisse l'image seule. Avec ceci, les collines du monde restent devant.")
        words: ["collines", "hills", "terrain", "fond d'écran", "wallpaper"]
        on: Config.hillsOnPictures
        onToggled: Forge.setHillsOnPictures(!on)
    }

    SettingSlider {
        key: "terrainHeight"
        label: Lang.t("Hauteur du terrain")
        value: Config.terrainHeight
        minimum: 0.04
        maximum: 0.24
        shownAs: 100
        unit: " %"
        onMoved: value => Config.terrainHeight = value
    }

    SettingSlider {
        key: "terrainRelief"
        label: Lang.t("Relief")
        hint: Lang.t("De doux à très accidenté.")
        value: Config.terrainRelief
        maximum: 2.5
        decimals: 1
        onMoved: value => Config.terrainRelief = value
    }

    SettingSlider {
        key: "grain"
        label: Lang.t("Grain")
        hint: Lang.t("La texture du ciel, du terrain et de la barre. À 0 %, tout devient lisse.")
        value: Config.grain
        maximum: 2
        shownAs: 100
        unit: " %"
        onMoved: value => Config.grain = Math.round(value * 20) / 20
    }

    SettingChoice {
        key: "widgetStyle"
        label: Lang.t("Style des widgets")
        hint: Lang.t("Ciel écrit à même le ciel. Cadran céleste range tout dans des hublots.")
        options: [{ id: "sky", label: Lang.t("Ciel") }, { id: "celestial", label: Lang.t("Cadran céleste") }]
        planetOption: true
        current: Config.widgetStyle
        onPicked: id => Config.widgetStyle = id
    }

    SettingChoice {
        key: "widgetInk"
        label: Lang.t("Encre des widgets")
        hint: Lang.t("Automatique lit le ciel : claire sur un ciel sombre, sombre sur une image claire, dans la teinte du monde.")
        words: ["couleur", "color", "texte", "lisible", "contraste"]
        options: [{ id: "auto", label: Lang.t("Automatique") }, { id: "light", label: Lang.t("Claire") }, { id: "dark", label: Lang.t("Sombre") }, { id: "world", label: Lang.t("Lumière du monde") }]
        current: Config.widgetInk
        onPicked: id => Config.widgetInk = id
    }

    SettingChoice {
        key: "widgetAccent"
        label: Lang.t("Touche de couleur")
        hint: Lang.t("Ce que les widgets mettent en lumière : le jour, la chanson, les paroles chantées, la météo. Automatique prend la couleur la plus marquante de l'image.")
        words: ["accent", "couleur", "color", "rouge", "teinte"]
        options: [{ id: "auto", label: Lang.t("Automatique") }, { id: "world", label: Lang.t("Lumière du monde") }, { id: "none", label: Lang.t("Aucune") }]
        current: Config.widgetAccent
        onPicked: id => Config.widgetAccent = id
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
