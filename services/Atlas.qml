pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Every setting the Réglages window holds, read from its pages as they are: each page is
// built once out of sight and its rows noted, with their section and the words people use
// for them. Search reads this, and so do links that open a setting directly.
Singleton {
    id: root

    // The pages, in the window's order, each with an id that links use in any language
    readonly property var pages: [
        { id: "monde", label: Lang.t("Monde"), page: "WorldPage.qml" },
        { id: "bureau", label: Lang.t("Bureau"), page: "DesktopPage.qml" },
        { id: "barre", label: Lang.t("Barre"), page: "BarPage.qml" },
        { id: "fenetres", label: Lang.t("Fenêtres"), page: "WindowsPage.qml" },
        { id: "mouvement", label: Lang.t("Mouvement"), page: "MotionPage.qml" },
        { id: "systeme", label: Lang.t("Système"), page: "SystemPage.qml" },
        { id: "verrouillage", label: Lang.t("Verrouillage"), page: "LockPage.qml" },
        { id: "langue", label: Lang.t("Langue"), page: "LanguagePage.qml" },
        { id: "apropos", label: Lang.t("À propos"), page: "AboutPage.qml" }
    ]

    // The other words a setting goes by, in both languages
    readonly property var words: ({
        theme: ["thème", "theme", "planète", "planet"],
        barStyle: ["panel", "dock", "barre"],
        barHide: ["cacher", "masquer", "autohide", "hide"],
        barPosition: ["haut", "bas", "top", "bottom"],
        barPercent: ["batterie", "battery", "pourcentage", "volume"],
        hotCorners: ["coins actifs", "hot corners"],
        clockFormat: ["heure", "am", "pm", "horloge", "clock", "12h", "24h"],
        clockSeconds: ["secondes", "seconds", "horloge"],
        dateFormat: ["date", "jour"],
        pageStyle: ["workspaces", "bureaux virtuels", "espaces de travail"],
        pace: ["vitesse", "animations", "lent", "rapide", "speed"],
        orbitSpeed: ["orbite", "orbit", "montée", "vitesse", "speed", "super tab"],
        livePages: ["vidéo", "lecture", "live"],
        pageTransition: ["rotation", "glissement", "slide", "workspace animation"],
        groundMusic: ["visualiseur", "visualizer", "cava", "spectre", "musique", "music"],
        groundLift: ["musique", "danse"],
        terrainHeight: ["terrain", "collines", "sol", "ground", "hills"],
        terrainRelief: ["montagnes", "collines", "relief", "mountains"],
        grain: ["bruit", "texture", "noise", "grain"],
        widgetStyle: ["widget", "cadran"],
        windowGlow: ["halo", "lueur", "glow", "ombre"],
        windowDim: ["assombrir", "dim", "inactives"],
        traceWidth: ["bordure", "border", "épaisseur"],
        traceSpacing: ["bordure", "border", "étoiles", "stars"],
        windowGapOuter: ["marge", "gaps", "espace"],
        windowGapInner: ["marge", "gaps", "espace"],
        glassApps: ["flou", "blur", "transparence", "transparent", "verre", "opacité"],
        nightWarmth: ["veilleuse", "night light", "filtre bleu", "lumière bleue", "kelvin"],
        notifSeconds: ["notification", "durée"],
        language: ["langue", "language", "english", "français", "traduction"],
        keyboardLayouts: ["clavier", "keyboard", "azerty", "qwerty", "disposition"],
        lockWith: ["verrou", "lock", "écran de verrouillage", "hyprlock"],
        lockFingerprint: ["doigt", "fingerprint", "empreinte"],
        lockImage: ["verrou", "lock", "image", "fond"],
        lockScene: ["verrou", "lock", "scène"],
        focusMinutes: ["pomodoro", "concentration", "focus", "minuteur"],
        restMinutes: ["pomodoro", "pause", "minuteur"],
        welcome: ["accueil", "welcome", "démarrage"]
    })

    property var entries: [] // { page, pageLabel, section, label, hint, key, words, plain }
    property bool built: false

    // Accents and case don't count, nor apostrophes, hyphens, or a plural s or x
    function fold(text) {
        return String(text ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/œ/g, "oe").replace(/['’\-_]/g, " ");
    }

    function stem(word) {
        return word.length > 3 && /[sx]$/.test(word) ? word.slice(0, -1) : word;
    }

    function wordsOf(text) {
        return fold(text).split(/[^a-z0-9%]+/).filter(word => word).map(stem);
    }

    // Each page built out of sight, its rows noted in the order they come
    function build() {
        if (built)
            return;
        const list = [];
        pages.forEach((page, index) => {
            const component = Qt.createComponent(Qt.resolvedUrl(`../modules/settings/${page.page}`));
            if (component.status !== Component.Ready) {
                console.warn("ETEA: can't read the settings page", page.page, component.errorString());
                return;
            }
            const item = component.createObject(null, { width: 760 });
            if (!item)
                return;
            let section = "";
            const walk = node => {
                for (const child of node.children ?? []) {
                    const isSection = child.objectName === "section";
                    if (isSection)
                        section = child.text;
                    if (isSection && child.text || child.objectName === "setting" && child.label) {
                        const label = isSection ? child.text : child.label;
                        const synonyms = (root.words[child.key] ?? []).concat(child.words ?? []);
                        list.push({
                            page: index,
                            pageLabel: page.label,
                            section: isSection ? "" : section,
                            label: label,
                            hint: child.hint ?? "",
                            key: child.key ?? "",
                            heading: isSection,
                            words: synonyms,
                            plain: {
                                label: root.wordsOf(label),
                                hint: root.wordsOf(child.hint),
                                synonyms: synonyms.map(word => root.fold(word)).concat(child.key ? [root.fold(child.key)] : []),
                                path: root.wordsOf(`${page.label} ${isSection ? "" : section}`)
                            }
                        });
                    }
                    walk(child);
                }
            };
            walk(item);
            item.destroy();
        });
        // A row drawn twice with the same label, as a world editor's colours are, counts once
        const seen = {};
        entries = list.filter(entry => {
            const id = `${entry.page}|${entry.label}`;
            if (seen[id])
                return false;
            seen[id] = true;
            return true;
        });
        built = true;
    }

    // Damerau-Levenshtein distance, stopping early past what we'd accept
    function distance(a, b, most) {
        if (Math.abs(a.length - b.length) > most)
            return most + 1;
        const d = [];
        for (let i = 0; i <= a.length; i++) {
            d.push([i]);
            for (let j = 1; j <= b.length; j++)
                d[i].push(i === 0 ? j : 0);
        }
        for (let i = 1; i <= a.length; i++) {
            for (let j = 1; j <= b.length; j++) {
                const cost = a[i - 1] === b[j - 1] ? 0 : 1;
                d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost);
                if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1])
                    d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1);
            }
        }
        return d[a.length][b.length];
    }

    // How well one typed word fits an entry, 0 when it doesn't
    function scoreWord(word, entry, typos) {
        const p = entry.plain, label = p.label.join(" ");
        if (label.startsWith(word))
            return 40;
        if (p.label.some(w => w.startsWith(word)))
            return 30;
        if (word.length >= 2 && p.label.length >= word.length && p.label.map(w => w[0]).join("").startsWith(word))
            return 26;
        if (p.synonyms.some(s => s.startsWith(word) || s.split(" ").some(w => w.startsWith(word))))
            return 22;
        if (label.includes(word))
            return 20;
        if (typos && word.length >= 4) {
            const most = word.length >= 8 ? 2 : 1;
            const near = w => root.distance(word, w, most) <= most || root.distance(word, w.slice(0, word.length), most) <= most;
            if (p.label.some(near) || p.synonyms.some(synonym => synonym.split(" ").some(near)))
                return 14;
        }
        if (p.hint.some(w => w.startsWith(word)))
            return 10;
        if (p.path.some(w => w.startsWith(word)))
            return 8;
        return 0;
    }

    // Every typed word has to fit. Words in their order earn a little; ties go to the page
    // you're on, then to the window's own order, never to how often a setting is used.
    function search(text, here) {
        build();
        const typed = wordsOf(text);
        if (!typed.length)
            return [];
        const pass = typos => entries.map((entry, order) => {
            let score = 0;
            for (const word of typed) {
                const s = scoreWord(word, entry, typos);
                if (!s)
                    return null;
                score += s;
            }
            if (typed.length > 1 && fold(entry.label).includes(typed.join(" ")))
                score += 5;
            return { entry: entry, score: score, order: order };
        }).filter(result => result);
        let results = pass(false);
        if (results.length < 7)
            results = pass(true);
        results.sort((a, b) => b.score - a.score || (b.entry.page === here) - (a.entry.page === here) || a.order - b.order);
        return results.map(result => result.entry);
    }

    // Where a link points: a setting's key, "@page" for a page, or "?words" for a search
    function resolve(address) {
        build();
        if (address.startsWith("@")) {
            const name = fold(address.slice(1));
            const index = pages.findIndex(page => page.id === name.replace(/\s/g, "") || fold(page.label).startsWith(name) || fold(page.page).startsWith(name));
            return index >= 0 ? { page: index } : { search: address.slice(1) };
        }
        if (address.startsWith("?"))
            return { search: address.slice(1) };
        const entry = entries.find(entry => entry.key === address) ?? entries.find(entry => fold(entry.label) === fold(address));
        return entry ? { page: entry.page, entry: entry } : { search: address };
    }
}
