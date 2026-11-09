import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// kitty wears the world's colours: its night is the cards' night, its ink the sky's, and
// its sixteen colours lean toward the world's hue so they belong with it. They're written
// to ~/.config/etea/kitty-colors.conf, which kitty.conf includes, and every open kitty is
// told to read it again. Switched off, the file is left empty and kitty keeps its own.
Scope {
    id: root

    readonly property string path: `${Quickshell.env("HOME")}/.config/etea/kitty-colors.conf`

    // The world's hue, from its light, or its sky when the light is nearly grey
    readonly property real hue: {
        const light = Forge.oklchOf(Qt.color(Theme.planet.light));
        return light.c >= 0.02 ? light.h : Forge.oklchOf(Qt.color(Theme.planet.skyTop)).h;
    }

    function tone(lightness, chroma, at) {
        return String(Forge.oklch(lightness, chroma, at ?? hue)).slice(0, 7);
    }

    // A colour's usual hue, turned up to 15° toward the world's
    function lean(base) {
        const turn = ((hue - base + 540) % 360) - 180;
        return base + Math.max(-15, Math.min(15, turn * 0.5));
    }

    readonly property string colours: {
        if (!Config.terminalColors)
            return "# ETEA leaves kitty's colours alone (Settings › Windows › Terminal)\n";
        // red, green, yellow, blue, magenta, cyan, in OKLCH
        const hues = [25, 145, 88, 255, 340, 200];
        const lines = [
            `background ${String(Theme.cardDeep).slice(0, 7)}`,
            `foreground ${tone(0.92, 0.018)}`,
            `cursor ${String(Theme.windowLit).slice(0, 7)}`,
            `cursor_text_color background`,
            `selection_background ${tone(0.4, 0.07)}`,
            `selection_foreground ${tone(0.96, 0.01)}`,
            `url_color ${tone(0.82, 0.09)}`,
            `color0 ${tone(0.3, 0.03)}`,
            `color8 ${tone(0.56, 0.03)}`,
            `color7 ${tone(0.84, 0.02)}`,
            `color15 ${tone(0.97, 0.012)}`
        ];
        hues.forEach((base, i) => {
            const yellow = base === 88;
            lines.push(`color${i + 1} ${tone(yellow ? 0.8 : 0.7, 0.12, lean(base))}`);
            lines.push(`color${i + 9} ${tone(yellow ? 0.88 : 0.8, 0.1, lean(base))}`);
        });
        // The greys at the end, which prompts like starship use for their pills
        const roles = {
            [tone(0.82, 0.08)]: [243, 248, 250, 251, 255],
            [tone(0.34, 0.05)]: [234, 236, 237, 252, 254],
            [tone(0.26, 0.05)]: [232, 238, 240],
            [tone(0.86, 0.04)]: [233, 235, 253],
            [tone(0.7, 0.12, lean(25))]: [239, 244, 249],
            [tone(0.4, 0.03)]: [245]
        };
        for (const colour in roles)
            roles[colour].forEach(index => lines.push(`color${index} ${colour}`));
        return `# Written by ETEA from the world you're on; changes here don't last\n${lines.join("\n")}\n`;
    }

    // Worlds slide by when you choose one, so it waits for them to settle
    onColoursChanged: settle.restart()
    Component.onCompleted: settle.restart()

    Timer {
        id: settle

        interval: 500
        onTriggered: {
            if (file.loaded && file.text() === root.colours)
                return;
            file.setText(root.colours);
            reread.running = true;
        }
    }

    FileView {
        id: file

        path: root.path
        printErrors: false
        blockWrites: true // written before kitty is told to read it
    }

    // kitty reads its config again on SIGUSR1
    Process {
        id: reread

        command: ["pkill", "-USR1", "-x", "kitty"]
    }
}
