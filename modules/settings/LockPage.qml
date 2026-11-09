import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.services

// The lock screen: who draws it, what greets you before you type, and whether a finger
// is enough. The starry sky comes after, always.
ColumnLayout {
    id: root

    spacing: 18

    Text {
        text: Lang.t("Verrouillage")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingChoice {
        key: "lockWith"
        label: Lang.t("Verrouiller avec")
        hint: Lang.t("Super + L, le menu de session, la mise en veille et la fermeture du capot.")
        options: [{ id: "etea", label: "ETEA" }, { id: "hyprlock", label: "hyprlock" }]
        current: Config.lockWith
        onPicked: id => Config.lockWith = id
    }

    SettingSwitch {
        key: "lockFingerprint"
        visible: Config.lockWith === "etea"
        label: Lang.t("Empreinte digitale")
        hint: Lang.t("Pose ton doigt sur le lecteur à tout moment, le mot de passe marche toujours.")
        on: Config.lockFingerprint
        onToggled: Config.lockFingerprint = !Config.lockFingerprint
    }

    SettingChoice {
        id: firstScreen

        key: "lockImage"
        visible: Config.lockWith === "etea"
        label: Lang.t("Premier écran")
        hint: Lang.t("Ce que tu vois avant de taper. Le ciel étoilé vient ensuite.")
        options: [{ id: "world", label: Lang.t("Ton monde") }, { id: "image", label: Lang.t("Une image") }]
        current: Config.lockImage ? "image" : "world"
        onPicked: id => {
            if (id === "world")
                Config.lockImage = "";
            else if (!Config.lockImage)
                Pictures.pick(Lang.t("Une image pour l'écran de verrouillage"), path => Config.lockImage = path, { role: "lock", item: firstScreen });
        }
    }

    // The picture, framed like a little window onto the lock
    Item {
        visible: Config.lockImage !== ""
        Layout.fillWidth: true
        Layout.preferredHeight: 190

        HandCard {
            anchors.fill: photo
            anchors.margins: -6
            seed: "lock-image"
            rise: 0.06
        }

        Image {
            id: photo

            width: 320
            height: 180
            anchors.verticalCenter: parent.verticalCenter
            source: Config.lockImage ? "file://" + Config.lockImage : ""
            sourceSize.width: 640
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: corners
            }
        }

        Rectangle {
            id: corners

            width: photo.width
            height: photo.height
            radius: 14
            visible: false
            layer.enabled: true
        }

        Column {
            anchors.left: photo.right
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            SettingButton {
                id: changeImage

                label: Lang.t("Changer d'image")
                onPicked: Pictures.pick(Lang.t("Une image pour l'écran de verrouillage"), path => Config.lockImage = path, { role: "lock", item: changeImage })
            }

            Text {
                width: 260
                text: Config.lockImage.split("/").pop()
                elide: Text.ElideMiddle
                color: Qt.alpha(Theme.text, 0.6)
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }

    SettingChoice {
        key: "lockScene"
        visible: Config.lockWith === "etea"
        label: Lang.t("Scène")
        hint: Lang.t("Ce qui se dessine pendant que tu tapes ton mot de passe.")
        options: [{ id: "hand", label: Lang.t("La main tendue") }, { id: "skyward", label: Lang.t("Sous les étoiles") }]
        planetOption: true
        current: Config.lockScene
        onPicked: id => Config.lockScene = id
    }

    SettingRow {
        label: Lang.t("Essayer")
        hint: Lang.t("Ouvre l'écran sans rien verrouiller. Échap pour en sortir.")

        SettingButton {
            label: Lang.t("Aperçu")
            onPicked: Menus.lockPreview = true
        }
    }
}
