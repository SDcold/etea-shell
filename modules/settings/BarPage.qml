import QtQuick
import QtQuick.Layouts
import qs.config

// Everything about the bar: where it sits, how it looks, what it holds and in which order.
ColumnLayout {
    id: root

    // A list of chosen ids becomes two zones, shown and hidden, and back
    function shownAndHidden(chosen, choices) {
        const ids = choices.map(choice => choice.id);
        return [
            { id: "shown", label: "Affichés", items: chosen.filter(id => ids.includes(id)) },
            { id: "hidden", label: "Masqués", items: ids.filter(id => !chosen.includes(id)) }
        ];
    }

    spacing: 18

    Text {
        text: "Barre"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingSection {
        text: "Apparence"
    }

    SettingChoice {
        label: "Position"
        options: [{ id: "top", label: "En haut" }, { id: "bottom", label: "En bas" }]
        current: Config.barPosition
        onPicked: id => Config.barPosition = id
    }

    SettingChoice {
        label: "Taille"
        options: [{ id: "compact", label: "Compacte" }, { id: "normal", label: "Normale" }, { id: "large", label: "Grande" }]
        current: Config.barSize
        onPicked: id => Config.barSize = id
    }

    SettingChoice {
        label: "Style"
        hint: "Le texte à même le ciel, chaque groupe sur son îlot, ou une seule bande."
        options: [{ id: "sky", label: "Ciel nu" }, { id: "islands", label: "Îlots" }, { id: "band", label: "Bande" }]
        current: Config.barStyle
        onPicked: id => Config.barStyle = id
    }

    SettingSwitch {
        label: "Coins actifs"
        hint: "Un clic dans un coin du côté de la barre ouvre le panneau de ce côté."
        on: Config.hotCorners
        onToggled: Config.hotCorners = !Config.hotCorners
    }

    SettingSection {
        text: "Disposition"
    }

    Text {
        Layout.fillWidth: true
        text: "Glisse les modules d'une zone à l'autre. Ceux qui sont rangés n'apparaissent pas."
        wrapMode: Text.Wrap
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 12
    }

    ChipBoard {
        columns: 3
        spanLast: true
        choices: Config.barModuleChoices
        zones: {
            const layout = Config.barLayout, used = [].concat(layout.left ?? [], layout.center ?? [], layout.right ?? []);
            return [
                { id: "left", label: "Gauche", items: layout.left ?? [] },
                { id: "center", label: "Centre", items: layout.center ?? [] },
                { id: "right", label: "Droite", items: layout.right ?? [] },
                { id: "unused", label: "Rangés", items: Config.barModuleChoices.map(choice => choice.id).filter(id => !used.includes(id)) }
            ];
        }
        onChanged: zones => Config.barLayout = { left: zones[0].items, center: zones[1].items, right: zones[2].items }
    }

    SettingSection {
        text: "Heure"
    }

    SettingChoice {
        label: "Format"
        options: [{ id: "24", label: "24 h" }, { id: "12", label: "12 h" }]
        current: Config.clockFormat
        onPicked: id => Config.clockFormat = id
    }

    SettingSwitch {
        label: "Secondes"
        on: Config.clockSeconds
        onToggled: Config.clockSeconds = !Config.clockSeconds
    }

    SettingChoice {
        label: "Date"
        options: [{ id: "long", label: "Longue" }, { id: "short", label: "Courte" }, { id: "off", label: "Masquée" }]
        current: Config.dateFormat
        onPicked: id => Config.dateFormat = id
    }

    SettingSection {
        text: "Pages et musique"
    }

    SettingSlider {
        label: "Pages par groupe"
        hint: "Au-delà, la barre bascule sur le groupe suivant au lieu de revenir au début."
        value: Config.pagesShown
        minimum: 4
        maximum: 10
        onMoved: value => Config.pagesShown = Math.round(value)
    }

    SettingChoice {
        label: "Pages"
        hint: "Une constellation par page, ou simplement son numéro, plus compact."
        options: [{ id: "constellation", label: "Constellations" }, { id: "numbers", label: "Numéros" }]
        current: Config.pageStyle
        onPicked: id => Config.pageStyle = id
    }

    SettingChoice {
        label: "Titre en cours"
        options: [{ id: "scroll", label: "Défilant" }, { id: "short", label: "Court" }, { id: "off", label: "Note seule" }]
        current: Config.mediaTitle
        onPicked: id => Config.mediaTitle = id
    }

    SettingSection {
        text: "Statut"
    }

    Text {
        Layout.fillWidth: true
        text: "Un clic affiche ou masque, glisser change l'ordre."
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 12
    }

    ChipBoard {
        clickMoves: true
        choices: Config.statusChoices
        zones: root.shownAndHidden(Config.status, Config.statusChoices)
        onChanged: zones => Config.status = zones[0].items
    }

    SettingSwitch {
        label: "Pourcentages"
        hint: "Les chiffres à côté du volume, de la batterie et des ressources."
        on: Config.barPercent
        onToggled: Config.barPercent = !Config.barPercent
    }

    SettingSwitch {
        label: "Plateau aux couleurs du shell"
        hint: "Les icônes des applis en arrière-plan, teintées comme le reste."
        on: Config.trayTint
        onToggled: Config.trayTint = !Config.trayTint
    }

    SettingSection {
        text: "Outils"
    }

    ChipBoard {
        clickMoves: true
        choices: Config.toolChoices
        zones: root.shownAndHidden(Config.barTools, Config.toolChoices)
        onChanged: zones => Config.barTools = zones[0].items
    }

    SettingSection {
        text: "Ressources"
    }

    ChipBoard {
        clickMoves: true
        choices: Config.resourceChoices
        zones: root.shownAndHidden(Config.barResources, Config.resourceChoices)
        onChanged: zones => Config.barResources = zones[0].items
    }
}
