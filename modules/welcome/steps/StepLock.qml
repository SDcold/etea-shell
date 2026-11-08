import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

ColumnLayout {
    spacing: 14

    SettingChoice {
        label: Lang.t("Scène")
        options: [{ id: "hand", label: Lang.t("La main tendue") }, { id: "skyward", label: Lang.t("Sous les étoiles") }]
        planetOption: true
        current: Config.lockScene
        onPicked: id => Config.lockScene = id
    }

    SettingSwitch {
        label: Lang.t("Empreinte digitale")
        hint: Lang.t("Pose ton doigt sur le lecteur à tout moment, le mot de passe marche toujours.")
        on: Config.lockFingerprint
        onToggled: Config.lockFingerprint = !Config.lockFingerprint
    }
}
