import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.config
import qs.services

// The lock screen. The first page is only the landscape; a key opens the starry sky,
// where every key typed lights a star and her hand moves to hide it. Enter checks the
// password. Nothing on screen ever depends on which key was pressed.
Scope {
    id: root

    property string typed: ""
    property int stars: 0 // how many stars are showing, which lags behind while they vanish
    property bool revealed: false
    property bool checking: false
    property bool vanishing: false
    property bool leaving: false
    property bool capsLock: false
    property real blockedUntil: 0
    property real now: Date.now()
    property string mainScreen: ""
    readonly property bool blocked: blockedUntil > now
    readonly property bool active: Menus.locked || Menus.lockPreview

    // Where the woman, her arm and the stars sit, from assets/lock/scene.json
    readonly property var scene: {
        try {
            return JSON.parse(sceneFile.text());
        } catch (error) {
            return null;
        }
    }

    signal succeeded()

    function begin() {
        mainScreen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
        typed = "";
        stars = 0;
        revealed = false;
        leaving = false;
        readCaps();
    }

    // The key that opens the sky counts too, so nothing typed is ever lost
    function type(text) {
        if (checking || blocked || vanishing)
            return;
        typed += text;
        stars = typed.length;
        revealed = true;
        idle.restart();
    }

    function erase() {
        if (checking || vanishing)
            return;
        typed = typed.slice(0, -1);
        stars = typed.length;
        idle.restart();
    }

    function submit() {
        if (!typed || checking || blocked)
            return;
        checking = true;
        idle.stop();
        pam.start();
    }

    // Back to the landscape, and whatever was typed is forgotten
    function back() {
        if (checking)
            return;
        typed = "";
        stars = 0;
        revealed = false;
    }

    function fail() {
        checking = false;
        typed = "";
        vanishing = true;
        clearStars.restart();
        idle.restart();
    }

    function finish() {
        leaving = true;
        letGo.restart();
    }

    function readCaps() {
        caps.running = true;
    }

    onActiveChanged: {
        if (active)
            begin();
    }

    FileView {
        id: sceneFile

        path: Quickshell.shellPath("assets/lock/scene.json")
        blockLoading: true
        // Tuning the scene shows up right away in the preview
        watchChanges: true
        onFileChanged: reload()
    }

    PamContext {
        id: pam

        config: "login"
        onPamMessage: {
            if (responseRequired) {
                respond(root.typed);
                return;
            }
            // pam_faillock says so when too many tries have locked the account
            if (/lock|verrouill/i.test(message)) {
                const minutes = message.match(/(\d+)\s*min/);
                root.blockedUntil = Date.now() + (minutes ? Number(minutes[1]) : 10) * 60000;
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.checking = false;
                root.finish();
            } else {
                root.fail();
            }
        }
        onError: root.fail()
    }

    // The stars fade out one after the other before the count drops
    Timer {
        id: clearStars

        interval: 650
        onTriggered: {
            root.stars = 0;
            root.vanishing = false;
        }
    }

    // A short fade, then the desktop
    Timer {
        id: letGo

        interval: 280
        onTriggered: {
            Menus.locked = false;
            Menus.lockPreview = false;
            root.typed = "";
            root.stars = 0;
            root.revealed = false;
            root.leaving = false;
        }
    }

    // Left alone, the sky closes again and takes the typing with it
    Timer {
        id: idle

        interval: 20000
        running: root.revealed && !root.checking
        onTriggered: root.back()
    }

    Timer {
        running: root.blocked
        repeat: true
        interval: 1000
        onTriggered: root.now = Date.now()
    }

    Process {
        id: caps

        command: ["/usr/bin/hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.capsLock = JSON.parse(text).keyboards.some(keyboard => keyboard.capsLock);
                } catch (error) {}
            }
        }
    }

    WlSessionLock {
        locked: Menus.locked

        WlSessionLockSurface {
            id: surface

            color: "black"

            LockScene {
                anchors.fill: parent
                lock: root
                main: surface.screen?.name === root.mainScreen
            }
        }
    }

    // The same scene in an ordinary window, to try it out without locking anything
    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === root.mainScreen) ?? Quickshell.screens[0]
        visible: Menus.lockPreview
        color: "black"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "etea:lock-preview"
        WlrLayershell.keyboardFocus: Menus.lockPreview ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        LockScene {
            anchors.fill: parent
            lock: root
            main: true
            preview: true
        }
    }

    GlobalShortcut {
        appid: "etea"
        name: "lock"
        onPressed: Menus.locked = true
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            Menus.locked = true;
        }

        function preview(): void {
            Menus.lockPreview = !Menus.lockPreview;
        }

        // For trying the preview out without a keyboard. They do nothing on the real lock.
        function press(): void {
            if (Menus.lockPreview)
                root.type("•");
        }

        function erase(): void {
            if (Menus.lockPreview)
                root.erase();
        }

        function shake(): void {
            if (Menus.lockPreview)
                root.fail();
        }

        function state(): string {
            return `locked ${Menus.locked}, preview ${Menus.lockPreview}, revealed ${root.revealed}, stars ${root.stars}, checking ${root.checking}, caps ${root.capsLock}, blocked ${root.blocked}`;
        }
    }
}
