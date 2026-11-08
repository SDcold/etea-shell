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
            { id: "shown", label: Lang.t("Affichés"), items: chosen.filter(id => ids.includes(id)) },
            { id: "hidden", label: Lang.t("Masqués"), items: ids.filter(id => !chosen.includes(id)) }
        ];
    }

    // Picking what a module shows while the module is put away would change nothing you
    // can see, so the module comes back to the bar, at the start of the right end
    function bringBack(module, items) {
        const layout = Config.barLayout;
        const used = [].concat(layout.left ?? [], layout.center ?? [], layout.right ?? []);
        if (items.length > 0 && !used.includes(module))
            Config.barLayout = { left: layout.left ?? [], center: layout.center ?? [], right: [module].concat(layout.right ?? []) };
    }

    spacing: 18

    Text {
        text: Lang.t("Barre")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingSection {
        text: Lang.t("Apparence")
    }

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
        hint: Lang.t("Le texte à même le ciel, chaque groupe sur son îlot, ou une seule bande.")
        options: [{ id: "sky", label: Lang.t("Ciel nu") }, { id: "islands", label: Lang.t("Îlots") }, { id: "band", label: Lang.t("Bande") }]
        planetOption: true
        current: Config.barStyle
        onPicked: id => Config.barStyle = id
    }

    SettingSwitch {
        label: Lang.t("Coins actifs")
        hint: Lang.t("Un clic dans un coin du côté de la barre ouvre le panneau de ce côté.")
        on: Config.hotCorners
        onToggled: Config.hotCorners = !Config.hotCorners
    }

    SettingChoice {
        label: Lang.t("Masquer la barre")
        hint: Lang.t("Cachée, elle revient quand la souris touche le bord de l'écran. Ses coins s'allument d'abord pour montrer où viser.")
        options: [{ id: "never", label: Lang.t("Jamais") }, { id: "always", label: Lang.t("Toujours") }, { id: "fullscreen", label: Lang.t("En plein écran") }]
        current: Config.barHide
        onPicked: id => Config.barHide = id
    }

    SettingSection {
        text: Lang.t("Disposition")
    }

    Text {
        Layout.fillWidth: true
        text: Lang.t("Glisse les modules d'une zone à l'autre. Ceux qui sont rangés n'apparaissent pas.")
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
                { id: "left", label: Lang.t("Gauche"), items: layout.left ?? [] },
                { id: "center", label: Lang.t("Centre"), items: layout.center ?? [] },
                { id: "right", label: Lang.t("Droite"), items: layout.right ?? [] },
                { id: "unused", label: Lang.t("Rangés"), items: Config.barModuleChoices.map(choice => choice.id).filter(id => !used.includes(id)) }
            ];
        }
        onChanged: zones => Config.barLayout = { left: zones[0].items, center: zones[1].items, right: zones[2].items }
    }

    SettingSection {
        text: Lang.t("Heure")
    }

    SettingChoice {
        label: Lang.t("Format")
        options: [{ id: "24", label: "24 h" }, { id: "12", label: "12 h" }]
        current: Config.clockFormat
        onPicked: id => Config.clockFormat = id
    }

    SettingSwitch {
        label: Lang.t("Secondes")
        on: Config.clockSeconds
        onToggled: Config.clockSeconds = !Config.clockSeconds
    }

    SettingChoice {
        label: Lang.t("Date")
        options: [{ id: "long", label: Lang.t("Longue") }, { id: "short", label: Lang.t("Courte") }, { id: "off", label: Lang.t("Masquée") }]
        current: Config.dateFormat
        onPicked: id => Config.dateFormat = id
    }

    SettingSection {
        text: Lang.t("Pages et musique")
    }

    SettingSlider {
        label: Lang.t("Pages par groupe")
        hint: Lang.t("Au-delà, la barre bascule sur le groupe suivant au lieu de revenir au début.")
        value: Config.pagesShown
        minimum: 4
        maximum: 10
        onMoved: value => Config.pagesShown = Math.round(value)
    }

    SettingChoice {
        label: Lang.t("Pages")
        hint: Lang.t("Une constellation par page, ou simplement son numéro, plus compact.")
        options: [{ id: "constellation", label: Lang.t("Constellations") }, { id: "numbers", label: Lang.t("Numéros") }]
        planetOption: true
        current: Config.pageStyle
        onPicked: id => Config.pageStyle = id
    }

    SettingChoice {
        label: Lang.t("Titre en cours")
        options: [{ id: "scroll", label: Lang.t("Défilant") }, { id: "short", label: Lang.t("Court") }, { id: "off", label: Lang.t("Note seule") }]
        current: Config.mediaTitle
        onPicked: id => Config.mediaTitle = id
    }

    SettingSection {
        text: Lang.t("Statut")
    }

    Text {
        Layout.fillWidth: true
        text: Lang.t("Un clic affiche ou masque, glisser change l'ordre.")
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 12
    }

    ChipBoard {
        clickMoves: true
        choices: Config.statusChoices
        zones: root.shownAndHidden(Config.status, Config.statusChoices)
        onChanged: zones => {
            Config.status = zones[0].items;
            root.bringBack("status", zones[0].items);
        }
    }

    SettingSwitch {
        label: Lang.t("Pourcentages")
        hint: Lang.t("Les chiffres à côté du volume, de la batterie et des ressources.")
        on: Config.barPercent
        onToggled: Config.barPercent = !Config.barPercent
    }

    SettingSwitch {
        label: Lang.t("Plateau aux couleurs du shell")
        hint: Lang.t("Les icônes des applis en arrière-plan, teintées comme le reste.")
        on: Config.trayTint
        onToggled: Config.trayTint = !Config.trayTint
    }

    SettingSection {
        text: Lang.t("Outils")
    }

    ChipBoard {
        clickMoves: true
        choices: Config.toolChoices
        zones: root.shownAndHidden(Config.barTools, Config.toolChoices)
        onChanged: zones => {
            Config.barTools = zones[0].items;
            root.bringBack("tools", zones[0].items);
        }
    }

    SettingSection {
        text: Lang.t("Ressources")
    }

    ChipBoard {
        clickMoves: true
        choices: Config.resourceChoices
        zones: root.shownAndHidden(Config.barResources, Config.resourceChoices)
        onChanged: zones => {
            Config.barResources = zones[0].items;
            root.bringBack("resources", zones[0].items);
        }
    }
}
