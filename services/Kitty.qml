pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What ETEA knows about kitty: whether it's here, and whether its kitty.conf reads the
// colours ETEA writes. Until it does, there's nothing to tell kitty, so it's left in peace.
Singleton {
    id: root

    readonly property string configDir: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/kitty`
    readonly property string configPath: `${configDir}/kitty.conf`
    readonly property string includeLine: "include ~/.config/etea/kitty-colors.conf"

    property bool present: false

    signal added()

    // An include line of its own, whichever way the path is written, and not commented out
    readonly property bool included: conf.loaded && /^\s*include\s+\S*\/etea\/kitty-colors\.conf\s*$/m.test(conf.text())

    // The same line the installer adds, at the end of kitty.conf
    function include() {
        if (included || adding.running)
            return;
        adding.running = true;
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v kitty"]
        onExited: code => root.present = code === 0
    }

    FileView {
        id: conf

        path: root.configPath
        watchChanges: true
        printErrors: false
        blockWrites: true // written before kitty is told to read it
        onFileChanged: reload()
    }

    // kitty may never have been configured, so its folder comes first
    Process {
        id: adding

        command: ["mkdir", "-p", root.configDir]
        onExited: {
            const before = conf.loaded ? conf.text() : "";
            const gap = before === "" || before.endsWith("\n") ? "" : "\n";
            conf.setText(`${before}${gap}\n# The world's colours, written by ETEA\n${root.includeLine}\n`);
            conf.reload(); // a file that wasn't there yet isn't watched
            root.added();
        }
    }
}
