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
        label: Lang.t("Rythme")
        hint: Lang.t("Quotidien reste vif. Cérémonie prend le temps de chaque geste.")
        options: [{ id: "daily", label: Lang.t("Quotidien") }, { id: "ceremony", label: Lang.t("Cérémonie") }]
        current: Config.pace
        onPicked: id => Config.pace = id
    }

    SettingChoice {
        label: Lang.t("Changement de page")
        hint: Lang.t("La planète qui tourne, ou le glissement horizontal de Hyprland pour comparer.")
        options: [{ id: "planet", label: Lang.t("Planète") }, { id: "slide", label: Lang.t("Glissement") }]
        current: Config.pageTransition
        onPicked: id => Config.pageTransition = id
    }

    SettingSwitch {
        visible: Config.pageTransition === "planet"
        label: Lang.t("Fenêtres vivantes")
        hint: Lang.t("Les vidéos et animations continuent pendant que la page tourne. Coupe-le sur une machine modeste.")
        on: Config.livePages
        onToggled: Config.livePages = !Config.livePages
    }
}
