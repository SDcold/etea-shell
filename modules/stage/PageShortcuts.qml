import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.services

// The keyboard's way in, wired up by scripts/dev.sh. These can't live inside the
// Planet singleton: it gets torn down after Wayland is gone and that crashes the shell.
Scope {
    // Super + a number goes to that page of the group you're in, like on end4
    Instantiator {
        model: 10

        GlobalShortcut {
            required property int index

            appid: "etea"
            name: "page" + (index + 1)
            onPressed: {
                if (index < Config.pages)
                    Planet.request(Planet.groupStart + index);
            }
        }
    }

    GlobalShortcut {
        appid: "etea"
        name: "orbit"
        onPressed: Planet.toggleOrbit()
    }

    GlobalShortcut {
        appid: "etea"
        name: "orbitDown"
        onPressed: Planet.goDown()
    }

    GlobalShortcut {
        appid: "etea"
        name: "settings"
        onPressed: Menus.settingsOpen = !Menus.settingsOpen
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            Menus.settingsOpen = !Menus.settingsOpen;
        }

        function grab(page: string, path: string): void {
            Menus.pageWanted(page, path);
        }

        // Opens Réglages on a setting (its key), a page (@barre) or a search (?flou)
        function open(address: string): void {
            Menus.openSettings(address);
        }

        // What a search for these words would find, best first
        function find(text: string): string {
            return Atlas.search(text, -1).slice(0, 8).map(entry => `${entry.label} (${entry.pageLabel}${entry.section ? " › " + entry.section : ""}${entry.key ? ", " + entry.key : ""})`).join("\n");
        }

        // Which settings are yours, set away from how they come
        function changed(): string {
            return Object.keys(Config.defaults).filter(key => Config.changed(key)).join(", ") + ` (${Object.keys(Config.defaults).length} known)`;
        }
    }

    IpcHandler {
        target: "planet"

        function orbit(): void {
            Planet.toggleOrbit();
        }

        function down(): void {
            Planet.goDown();
        }

        // Where the planet is up to, handy when something looks wrong
        function state(): string {
            return `phase ${Planet.phase}, page ${Planet.current}, group from ${Planet.groupStart}, resting ${Planet.resting.toFixed(2)}, altitude ${Planet.altitude}`;
        }

        function land(page: int): void {
            Planet.leaveOrbit(page);
        }

        // Plays the touchdown on the world you're on, to see it again
        function arrive(): void {
            Planet.arrive();
        }
    }

    IpcHandler {
        target: "morph"

        // Plays your world's colours changing to another world's, there and back, keeping nothing
        function rehearse(other: string): void {
            const source = Planets.find(other), changes = {};
            for (const key of Morph.tints)
                changes[key] = source[key];
            Morph.rehearse(Theme.planet.id, changes);
        }

        function grab(path: string): void {
            Skies.backgroundWanted(path);
        }

        // Plays taking every stratum from another world, there and back, keeping nothing
        function borrow(other: string): void {
            Morph.borrow(Theme.planet.id, other, null, true);
        }

        // Plays what hangs in the sky changing, there and back, keeping nothing
        function restage(scene: string): void {
            Morph.rehearse(Theme.planet.id, { scenery: scene });
        }

        // Plays the ground taking other forms, there and back, keeping nothing
        function reshape(far: string, near: string): void {
            Morph.rehearse(Theme.planet.id, { form: { far: far, near: near }, ground: true });
        }

        function state(): string {
            return `busy ${Morph.busy}, ${Morph.dusk ? "dusk" : "dawn"} ${Morph.tint.toFixed(2)}, crossed ${Morph.crossed}, light ${Theme.link}`;
        }
    }

    IpcHandler {
        target: "skies"

        // Climbs to the belt for your own sky, without changing anything yet
        function open(): void {
            Skies.ask({ role: "sky", title: Lang.t("Un fond d'écran"), answer: null, from: null, planetId: Theme.planet.id });
        }

        function leave(): void {
            Skies.leave();
        }

        // A number of moons along, as the arrow keys do
        function turn(moons: int): void {
            Skies.step(moons);
        }

        // To an item of the folder by its place, 1 being the first, as a flight does
        function jump(place: int): void {
            Skies.flyTo(place - 1);
        }

        // Looks at the sky at the top full size, or back up to its moon
        function look(on: bool): void {
            Skies.look(on);
        }

        // Lands the sky at the top all the way down without wearing it
        function rehearse(): void {
            Skies.rehearsal = true;
            Skies.choose();
        }

        function grab(path: string): void {
            Skies.grabWanted(path);
        }

        // Holds the climb at a height, from 0 to the edge, to grab it there
        function hold(altitude: real): void {
            if (Planet.inSkies)
                Planet.holdAt(altitude);
        }

        function state(): string {
            return `open ${Skies.open}, role ${Skies.role || "none"}, items ${Skies.items.length}, zenith ${Skies.zenith + 1} ${Skies.nameOf(Skies.items[Skies.zenith])}, scroll ${Skies.scroll.toFixed(3)}, shift ${Skies.shift}, palettes ${Object.keys(Palettes.known).length}, phase ${Planet.phase}, altitude ${Planet.altitude.toFixed(3)}, ceiling ${Planet.ceiling}`;
        }
    }

    GlobalShortcut {
        appid: "etea"
        name: "pageNext"
        onPressed: Planet.requestNext(1)
    }

    GlobalShortcut {
        appid: "etea"
        name: "pagePrevious"
        onPressed: Planet.requestNext(-1)
    }

    // Super + wheel: over a widget it changes its size, anywhere else (or once they're frozen) it turns the page
    GlobalShortcut {
        appid: "etea"
        name: "wheelUp"
        onPressed: Desk.hovered && !Desk.frozen ? Desk.grow(Desk.hovered, 1) : Planet.requestNext(1)
    }

    GlobalShortcut {
        appid: "etea"
        name: "wheelDown"
        onPressed: Desk.hovered && !Desk.frozen ? Desk.grow(Desk.hovered, -1) : Planet.requestNext(-1)
    }
}
