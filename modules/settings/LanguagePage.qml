import QtQuick
import QtQuick.Layouts
import qs.config

// Which language the shell speaks.
ColumnLayout {
    spacing: 18

    Text {
        text: Lang.t("Langue")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingChoice {
        label: Lang.t("Langue du shell")
        hint: Lang.t("Automatique suit la langue de ton système.")
        options: [{ id: "auto", label: Lang.t("Automatique") }].concat(Lang.languages)
        current: Config.language
        onPicked: id => Config.language = id
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 6
        text: Lang.t("Ta langue n'y est pas ? Copie i18n/en.json, traduis chaque phrase et ajoute-la à Lang.languages : ETEA la parlera.")
        wrapMode: Text.Wrap
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 12
    }
}
