import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.config
import qs.modules.bar.menus

// How the focused window catches the light, and which apps let the sky show through.
ColumnLayout {
    id: root

    // Open apps that aren't see-through yet, the easiest ones to add
    readonly property var openClasses: [...new Set(Hyprland.toplevels.values.map(window => window.lastIpcObject?.class ?? "").filter(name => name && name !== "org.quickshell" && !Config.glassApps.some(app => app.class === name)))]

    function setGlass(name, changes) {
        Config.glassApps = Config.glassApps.map(app => app.class === name ? Object.assign({ class: name }, changes) : app);
    }

    spacing: 18

    Text {
        text: Lang.t("Fenêtres")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingSlider {
        label: Lang.t("Force de la lueur")
        value: Config.windowGlow
        shownAs: 100
        unit: " %"
        onMoved: value => Config.windowGlow = value
    }

    SettingSlider {
        label: Lang.t("Taille de la lueur")
        value: Config.windowGlowSize
        minimum: 6
        maximum: 80
        unit: " px"
        onMoved: value => Config.windowGlowSize = Math.round(value)
    }

    SettingSlider {
        label: Lang.t("Ombre des fenêtres inactives")
        value: Config.windowDim
        maximum: 0.6
        shownAs: 100
        unit: " %"
        onMoved: value => Config.windowDim = value
    }

    SettingSlider {
        label: Lang.t("Épaisseur du cadre")
        value: Config.traceWidth
        minimum: 1
        maximum: 5
        unit: " px"
        onMoved: value => Config.traceWidth = Math.round(value)
    }

    SettingSlider {
        label: Lang.t("Espace entre les étoiles")
        hint: Lang.t("Plus c'est grand, moins il y a d'étoiles sur le cadre.")
        value: Config.traceSpacing
        minimum: 120
        maximum: 800
        unit: " px"
        onMoved: value => Config.traceSpacing = Math.round(value)
    }

    SettingSlider {
        label: Lang.t("Marge autour des fenêtres")
        value: Config.windowGapOuter
        minimum: 0
        maximum: 40
        unit: " px"
        onMoved: value => Config.windowGapOuter = Math.round(value)
    }

    SettingSection {
        text: Lang.t("Verre")
    }

    Text {
        Layout.fillWidth: true
        text: Lang.t("Ces applications laissent voir le ciel, flouté, à travers elles. Tout à droite, l'application garde sa propre transparence.")
        wrapMode: Text.WordWrap
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 12
    }

    Repeater {
        model: Config.glassApps

        SettingRow {
            id: glass

            required property var modelData
            // 0 or nothing means the app fades itself, shown as fully opaque here
            readonly property real level: modelData.opacity || 1

            label: modelData.class
            hint: glass.level >= 1 ? Lang.t("Sa propre transparence") : `${Math.round(glass.level * 100)} %`

            Row {
                spacing: 12

                MenuSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180
                    tint: Theme.windowLit
                    value: glass.level - 0.5
                    maximum: 0.5
                    onMoved: value => root.setGlass(glass.modelData.class, value >= 0.49 ? {} : { opacity: Math.round((0.5 + value) * 100) / 100 })
                }

                SettingButton {
                    anchors.verticalCenter: parent.verticalCenter
                    label: Lang.t("Retirer")
                    quiet: true
                    onPicked: Config.glassApps = Config.glassApps.filter(app => app.class !== glass.modelData.class)
                }
            }
        }
    }

    SettingRow {
        visible: root.openClasses.length > 0
        label: Lang.t("Ajouter une application ouverte")

        Flow {
            width: 360
            spacing: 8

            Repeater {
                model: root.openClasses

                SettingButton {
                    required property string modelData

                    label: modelData
                    quiet: true
                    onPicked: Config.glassApps = Config.glassApps.concat([{ class: modelData, opacity: 0.85 }])
                }
            }
        }
    }
}
