import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.services

// The keyboard's way in, wired up by scripts/dev.sh. These can't live inside the
// Planet singleton: it gets torn down after Wayland is gone and that crashes the shell.
Scope {
    Instantiator {
        model: Config.pages

        GlobalShortcut {
            required property int index

            appid: "etea"
            name: "page" + (index + 1)
            onPressed: Planet.request(index + 1)
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
    }

    IpcHandler {
        target: "planet"

        function orbit(): void {
            Planet.toggleOrbit();
        }

        function down(): void {
            Planet.goDown();
        }

        function land(page: int): void {
            Planet.leaveOrbit(page);
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
}
