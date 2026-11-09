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

    SettingSlider {
        key: "orbitSpeed"
        label: Lang.t("Vitesse de l'orbite")
        hint: Lang.t("La vitesse de la montée en orbite (balayage à quatre doigts vers le haut, Super + Tab).")
        value: Config.orbitSpeed
        minimum: 0.5
        maximum: 3
        shownAs: 100
        unit: " %"
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
