import QtQuick
import QtQuick.Layouts
import qs.config

// How much time the shell takes for its big movements.
ColumnLayout {
    spacing: 18

    Text {
        text: Lang.t("Mouvement")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingChoice {
        key: "pace"
        label: Lang.t("Rythme")
        hint: Lang.t("Quotidien reste vif. Cérémonie prend le temps de chaque geste.")
        options: [{ id: "daily", label: Lang.t("Quotidien") }, { id: "ceremony", label: Lang.t("Cérémonie") }]
        current: Config.pace
        onPicked: id => Config.pace = id
    }

    SettingChoice {
        key: "orbitBackdrop"
        label: Lang.t("Fond de l'orbite")
        hint: Lang.t("En orbite et parmi les mondes : le ciel du monde, flouté et assombri derrière les étoiles, ou le noir de l'espace.")
        options: [{ id: "sky", label: Lang.t("Le ciel flouté") }, { id: "space", label: Lang.t("L'espace noir") }]
        current: Config.orbitBackdrop
        onPicked: id => Config.orbitBackdrop = id
    }

    SettingSlider {
        key: "orbitBlur"
        visible: Config.orbitBackdrop !== "space"
        label: Lang.t("Flou du ciel en orbite")
        value: Config.orbitBlur
        minimum: 0
        maximum: 1
        shownAs: 100
        unit: " %"
        onMoved: value => Config.orbitBlur = Math.round(value * 100) / 100
    }

    SettingSlider {
        key: "orbitSpeed"
        label: Lang.t("Vitesse de l'orbite")
        hint: Lang.t("La vitesse des allers-retours en orbite et vers les planètes (balayage à quatre doigts, Super + Tab).")
        value: Config.orbitSpeed
        minimum: 0.5
        maximum: 3
        shownAs: 100
        unit: " %"
        notch: 1 // as it comes
        onMoved: value => Config.orbitSpeed = Math.round(value * 20) / 20
    }

    SettingChoice {
        key: "pageTransition"
        label: Lang.t("Changement de page")
        hint: Lang.t("La planète qui tourne, ou le glissement horizontal de Hyprland pour comparer.")
        options: [{ id: "planet", label: Lang.t("Planète") }, { id: "slide", label: Lang.t("Glissement") }]
        current: Config.pageTransition
        onPicked: id => Config.pageTransition = id
    }

    SettingSwitch {
        key: "livePages"
        visible: Config.pageTransition === "planet"
        label: Lang.t("Fenêtres vivantes")
        hint: Lang.t("Les vidéos et animations continuent pendant que la page tourne. Coupe-le sur une machine modeste.")
        on: Config.livePages
        onToggled: Config.livePages = !Config.livePages
    }
}
