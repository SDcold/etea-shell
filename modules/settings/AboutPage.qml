import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.bar
import qs.services

// Which ETEA this is, how to bring it up to date in one press, and where it lives.
ColumnLayout {
    id: root

    readonly property string when: Updater.date ? Qt.locale(Config.locale).toString(new Date(`${Updater.date}T12:00:00`), "d MMMM yyyy") : ""

    // What the update row says, and what its button does
    readonly property var status: ({
        idle: { text: Lang.t("Pas encore vérifié"), hint: "", action: Lang.t("Vérifier") },
        checking: { text: Lang.t("On regarde s'il y a du nouveau…"), hint: "", action: "" },
        current: { text: Lang.t("Tu as la dernière version"), hint: Lang.t("Rien de neuf pour l'instant."), action: Lang.t("Vérifier") },
        available: { text: Updater.behind === 1 ? Lang.t("Une nouveauté t'attend") : Lang.t("{0} nouveautés t'attendent", Updater.behind), hint: Lang.t("Le shell se recharge tout seul une fois à jour."), action: Lang.t("Mettre à jour") },
        updating: { text: Lang.t("Mise à jour…"), hint: "", action: "" },
        updated: { text: Lang.t("À jour"), hint: Lang.t("Le shell se recharge avec la nouvelle version."), action: "" },
        offline: { text: Lang.t("GitHub ne répond pas"), hint: Lang.t("Vérifie ta connexion et réessaie."), action: Lang.t("Réessayer") },
        unmanaged: { text: Lang.t("Mise à jour manuelle"), hint: Lang.t("ETEA n'a pas été installé avec git clone, ou ne suit aucune branche : réinstalle-le depuis GitHub pour les mises à jour en un clic."), action: "" },
        edited: { text: Lang.t("Des fichiers ont été modifiés à la main"), hint: Lang.t("Pour ne rien écraser, la mise à jour attend : garde tes changements avec git stash, puis réessaie."), action: Lang.t("Réessayer") },
        diverged: { text: Lang.t("Ta copie a pris un autre chemin"), hint: Lang.t("Elle contient des changements que GitHub n'a pas : mets-la à jour avec git pull."), action: Lang.t("Vérifier") }
    })[Updater.state]

    spacing: 18

    Component.onCompleted: {
        Updater.refresh();
        if (Updater.state !== "unmanaged")
            Updater.check();
    }

    Text {
        text: Lang.t("À propos")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 22

        // The PNG keeps the glow, Qt's SVG renderer leaves it out
        Image {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            source: Quickshell.shellPath("assets/logo.png")
            sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "ETEA Shell"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 24
                font.weight: Font.Light
            }

            Text {
                text: "Exit The Earth Atmosphere"
                color: Qt.alpha(Theme.text, 0.6)
                font.family: Theme.font
                font.pixelSize: 12
                font.letterSpacing: 1.2
            }
        }
    }

    SettingSection {
        text: Lang.t("Version")
    }

    SettingRow {
        label: Updater.commit ? Lang.t("Version {0}", Updater.commit) : Lang.t("Version inconnue")
        hint: [root.when, Updater.branch ? Lang.t("branche {0}", Updater.branch) : ""].filter(part => part).join(" · ")
    }

    SettingRow {
        label: root.status.text
        hint: root.status.hint

        SettingButton {
            visible: root.status.action !== ""
            label: root.status.action
            quiet: Updater.state !== "available"
            onPicked: Updater.state === "available" ? Updater.update() : Updater.check()
        }
    }

    // What's coming, in the project's own words
    ColumnLayout {
        visible: Updater.state === "available"
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: Updater.state === "available" ? Updater.changes : []

            RowLayout {
                required property string modelData

                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 12

                Star {
                    Layout.alignment: Qt.AlignVCenter
                    size: 3
                    lit: false
                    animated: false
                }

                Text {
                    Layout.fillWidth: true
                    text: parent.modelData
                    wrapMode: Text.Wrap
                    color: Qt.alpha(Theme.text, 0.75)
                    font.family: Theme.font
                    font.pixelSize: 13
                }
            }
        }

        Text {
            visible: Updater.behind > Updater.changes.length
            Layout.leftMargin: 4
            text: Lang.t("…et {0} de plus.", Updater.behind - Updater.changes.length)
            color: Qt.alpha(Theme.text, 0.5)
            font.family: Theme.font
            font.pixelSize: 12
        }
    }

    SettingSection {
        text: Lang.t("Accueil")
    }

    SettingSwitch {
        key: "welcome"
        label: Lang.t("Au démarrage")
        hint: Lang.t("Les six étoiles pour tout régler, à chaque fois que le shell démarre.")
        on: Config.welcome
        onToggled: Config.welcome = !Config.welcome
    }

    SettingRow {
        label: Lang.t("Revoir l'accueil")

        SettingButton {
            label: Lang.t("Ouvrir")
            quiet: true
            onPicked: Menus.welcomeOpen = true
        }
    }

    SettingSection {
        text: Lang.t("Le projet")
    }

    SettingRow {
        label: Lang.t("Code source")
        hint: "github.com/SDcold/etea-shell"

        SettingButton {
            label: Lang.t("Ouvrir")
            quiet: true
            onPicked: Qt.openUrlExternally("https://github.com/SDcold/etea-shell")
        }
    }

    SettingRow {
        label: Lang.t("Un souci, une idée ?")
        hint: Lang.t("Raconte-le sur GitHub, ça aide vraiment.")

        SettingButton {
            label: Lang.t("Écrire")
            quiet: true
            onPicked: Qt.openUrlExternally("https://github.com/SDcold/etea-shell/issues")
        }
    }

    SettingRow {
        label: Lang.t("Licence")
        hint: Lang.t("GPL-3.0 : libre de l'utiliser, de l'étudier, de le modifier et de le partager, tant que ce que tu partages reste libre aussi.")
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 6
        text: Lang.t("Fait main avec Quickshell, pour Hyprland. Merci à tous ceux qui l'essaient.")
        wrapMode: Text.Wrap
        color: Qt.alpha(Theme.text, 0.5)
        font.family: Theme.font
        font.pixelSize: 12
    }
}
