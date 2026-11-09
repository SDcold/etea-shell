import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// The machine's small comforts: how warm the night light is, how long signals stay.
ColumnLayout {
    spacing: 18

    Text {
        text: Lang.t("Système")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingSection {
        text: Lang.t("Veilleuse")
    }

    SettingSwitch {
        label: Lang.t("Veilleuse")
        hint: NightLight.available ? "" : Lang.t("Il faut hyprsunset pour ça.")
        on: NightLight.on
        onToggled: NightLight.toggle()
    }

    SettingSlider {
        key: "nightWarmth"
        label: Lang.t("Chaleur")
        hint: Lang.t("Plus c'est bas, plus l'écran est orangé.")
        value: Config.nightWarmth
        minimum: 2500
        maximum: 5500
        unit: " K"
        onMoved: value => Config.nightWarmth = Math.round(value / 100) * 100
    }

    SettingSection {
        text: Lang.t("Notifications")
    }

    SettingSwitch {
        label: Lang.t("Silence")
        hint: Lang.t("Les signaux vont droit au journal, sans s'afficher.")
        on: Notifs.quiet
        onToggled: Notifs.quiet = !Notifs.quiet
    }

    SettingSlider {
        key: "notifSeconds"
        label: Lang.t("Durée d'affichage")
        hint: Lang.t("Quand l'application ne précise rien.")
        value: Config.notifSeconds
        minimum: 2
        maximum: 20
        unit: " s"
        onMoved: value => Config.notifSeconds = Math.round(value)
    }

    SettingSection {
        text: Lang.t("Écran éveillé")
    }

    SettingSwitch {
        label: Lang.t("Éveillé")
        hint: Lang.t("Ni veille, ni verrouillage, tant que c'est allumé.")
        on: Wake.on
        onToggled: Wake.on = !Wake.on
    }
}
