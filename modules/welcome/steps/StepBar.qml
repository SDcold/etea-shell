import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

ColumnLayout {
    spacing: 14

    SettingChoice {
        label: Lang.t("Position")
        options: [{ id: "top", label: Lang.t("En haut") }, { id: "bottom", label: Lang.t("En bas") }]
        current: Config.barPosition
        onPicked: id => Config.barPosition = id
    }

    SettingChoice {
        label: Lang.t("Taille")
        options: [{ id: "compact", label: Lang.t("Compacte") }, { id: "normal", label: Lang.t("Normale") }, { id: "large", label: Lang.t("Grande") }]
        current: Config.barSize
        onPicked: id => Config.barSize = id
    }

    SettingChoice {
        label: Lang.t("Style")
        options: [{ id: "sky", label: Lang.t("Ciel nu") }, { id: "islands", label: Lang.t("Îlots") }, { id: "band", label: Lang.t("Bande") }]
        planetOption: true
        current: Config.barStyle
        onPicked: id => Config.barStyle = id
    }

    SettingChoice {
        label: Lang.t("Masquer la barre")
        options: [{ id: "never", label: Lang.t("Jamais") }, { id: "always", label: Lang.t("Toujours") }, { id: "fullscreen", label: Lang.t("En plein écran") }]
        current: Config.barHide
        onPicked: id => Config.barHide = id
    }
}
