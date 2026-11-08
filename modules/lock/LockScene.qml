import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config
import qs.modules.background
import qs.modules.bar
import qs.modules.stage
import qs.services

// What one screen of the lock shows. Only the main screen, the one you type on, shows the
// scene's figure; the others keep the landscape and the scene's sky.
//
// The second page draws one of the scenes in scenes/, picked in Settings. A scene is an
// Item given `host`, this LockScene, and reads from it: host.lock (stars typed, revealed,
// checking, vanishing, capsLock...), host.main, host.reveal, host.pulse and host.jitter().
// It gives back `night`, the colour the first page darkens to, and `unlockAt`, the point
// the lock folds into when it opens. It only ever learns how many letters were typed.
Item {
    id: root

    required property var lock
    property bool main: false
    property bool preview: false

    signal claimed() // a key reached this screen, so it becomes the one you type on

    readonly property real unit: height
    // Where the lock folds into when it opens, the scene says where its newest star is
    readonly property point unlockAt: stage.item?.unlockAt ?? Qt.point(width / 2, height / 2)

    // The sky opens fast; the scene follows. Going back, the scene leaves first.
    property real reveal: main && lock.revealed ? 1 : 0

    Behavior on reveal {
        SequentialAnimation {
            PauseAnimation { duration: root.lock.revealed ? 0 : 520 }
            NumberAnimation { duration: 300; easing.type: root.lock.revealed ? Easing.OutCubic : Easing.InCubic }
        }
    }

    // The same tiny wobble for star number n every time, whatever key made it
    function jitter(n, salt) {
        const x = Math.sin(n * 12.9898 + salt * 78.233) * 43758.5453;
        return x - Math.floor(x) - 0.5;
    }

    // First page: the landscape, or your own picture
    World {
        anchors.fill: parent
        visible: Config.lockImage === ""
        showWidgets: false
    }

    Image {
        anchors.fill: parent
        visible: Config.lockImage !== ""
        source: Config.lockImage ? "file://" + Config.lockImage : ""
        fillMode: Image.PreserveAspectCrop
    }

    // The longer the screen stays locked, the further the evening goes: over twenty
    // minutes the sky deepens towards the night of the second page and stars come out
    Item {
        id: dusk

        readonly property real fall: Math.max(0, Math.min(1, (Time.now.getTime() - root.lock.lockedAt) / 1200000))
        readonly property color night: stage.item?.night ?? "#0b1026"
        property real shown: fall

        anchors.fill: parent
        opacity: shown * 0.85
        visible: opacity > 0

        Behavior on shown {
            NumberAnimation { duration: 60000 }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: dusk.night }
                GradientStop { position: 0.6; color: Qt.alpha(dusk.night, 0.55) }
                GradientStop { position: 1; color: Qt.alpha(dusk.night, 0.3) }
            }
        }

        // Drawn once, a few hundred pinpricks, brighter towards the top
        Canvas {
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onPaint: {
                const g = getContext("2d");
                g.reset();
                g.fillStyle = "#ffffff";
                for (let i = 0; i < 260; i++) {
                    const x = (root.jitter(i, 11) + 0.5) * width, y = Math.pow(root.jitter(i, 12) + 0.5, 1.6) * height * 0.75;
                    g.globalAlpha = (0.25 + (root.jitter(i, 13) + 0.5) * 0.6) * (1 - y / height);
                    g.fillRect(x, y, 1.5, 1.5);
                }
            }
        }
    }

    // What you'd glance at before unlocking: the time as a constellation high in the sky,
    // the day and what's playing under it, the battery, the signals and the reader in the
    // corner. It all steps back as soon as you type.
    Item {
        id: glance

        readonly property real size: root.unit
        readonly property var battery: UPower.displayDevice

        anchors.fill: parent
        visible: root.main && opacity > 0
        opacity: 1 - root.reveal

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.13
            spacing: glance.size * 0.012

            StarClock {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Config.time(Time.now, { suffix: false })
                digitHeight: glance.size * 0.17
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: glance.size * 0.03
                // In twelve-hour time the morning or evening goes with the day
                text: Qt.locale(Config.locale).toString(Time.now, Lang.t("dddd d MMMM")) + (Config.clockFormat === "12" ? Qt.formatTime(Time.now, "  ·  AP") : "")
                color: Theme.skyInk
                font.family: Theme.font
                font.pixelSize: glance.size * 0.024
                font.letterSpacing: glance.size * 0.001
            }

            Text {
                visible: Music.player !== null
                anchors.horizontalCenter: parent.horizontalCenter
                text: `♪  ${Music.player?.trackTitle ?? ""}${Music.player?.trackArtist ? " · " + Music.player.trackArtist : ""}`
                color: Qt.alpha(Theme.skyInk, 0.75)
                font.family: Theme.font
                font.pixelSize: glance.size * 0.016
            }
        }

        // Every signal that comes in while you're away lights a star of its own, around
        // the time rather than over it
        Repeater {
            model: Math.min(24, Math.max(0, Notifs.count - root.lock.signalsAtLock))

            Star {
                required property int index
                readonly property real across: 0.08 + (root.jitter(index, 21) + 0.5) * 0.84
                readonly property real down: 0.06 + (root.jitter(index, 22) + 0.5) * 0.46

                x: across * root.width - size
                y: (across > 0.26 && across < 0.74 && down > 0.1 && down < 0.42 ? down + 0.34 : down) * root.height - size
                size: glance.size * (0.009 + (root.jitter(index, 23) + 0.5) * 0.005)
                lit: true
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: root.width * 0.044
            y: root.height * 0.08
            spacing: glance.size * 0.024

            // The reader is listening; a finger it doesn't know turns it red for a moment
            Icon {
                id: reader

                property bool missed: false

                visible: root.lock.listening
                anchors.verticalCenter: parent.verticalCenter
                name: "fingerprint"
                size: Math.round(glance.size * 0.026)
                tint: missed ? "#f0947c" : Theme.skyInk

                Connections {
                    target: root.lock

                    function onFingerMissesChanged() {
                        reader.missed = true;
                        unmiss.restart();
                    }
                }

                Timer {
                    id: unmiss

                    interval: 900
                    onTriggered: reader.missed = false
                }
            }

            Row {
                visible: Notifs.count > 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: glance.size * 0.006

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "bell"
                    size: Math.round(glance.size * 0.022)
                    tint: Theme.skyInk
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.count
                    color: Theme.skyInk
                    font.family: Theme.font
                    font.pixelSize: glance.size * 0.018
                }
            }

            Row {
                visible: glance.battery?.isLaptopBattery ?? false
                anchors.verticalCenter: parent.verticalCenter
                spacing: glance.size * 0.006

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: !UPower.onBattery ? "battery-charging" : (glance.battery?.percentage ?? 1) < 0.15 ? "battery-low" : "battery-full"
                    size: Math.round(glance.size * 0.022)
                    tint: Theme.skyInk
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Math.round((glance.battery?.percentage ?? 0) * 100)} %`
                    color: Theme.skyInk
                    font.family: Theme.font
                    font.pixelSize: glance.size * 0.018
                }
            }
        }
    }

    // Second page: the starry sky, opened through a four-pointed star
    Item {
        id: sky

        anchors.fill: parent
        visible: root.reveal > 0
        layer.enabled: root.reveal < 1
        layer.effect: StarMask {
            reach: fullReach * root.reveal
            shine: (1 - root.reveal) * 0.9
        }

        // The art itself, one scene among several. Only scenes listed here can load, and one
        // that fails leaves the plain sky: a drawing must never break the lock.
        Loader {
            id: stage

            readonly property string file: ({ hand: "HandScene.qml", skyward: "SkywardScene.qml" })[Theme.lockScene] ?? "PlainScene.qml"

            function load(name) {
                setSource(Qt.resolvedUrl(`scenes/${name}`), { host: root });
            }

            anchors.fill: parent
            onFileChanged: load(file)
            Component.onCompleted: load(file)
            onStatusChanged: {
                if (status === Loader.Error && !source.toString().endsWith("PlainScene.qml"))
                    load("PlainScene.qml");
            }
        }

        // Too many tries: the sky darkens and counts down
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.lock.blocked ? 0.55 : 0

            Behavior on opacity {
                NumberAnimation { duration: 600 }
            }

            Text {
                visible: root.main && root.lock.blocked
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.3
                text: {
                    const left = Math.max(0, Math.ceil((root.lock.blockedUntil - root.lock.now) / 1000));
                    return Lang.t("Trop d'essais. Réessaie dans {0}.", `${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`);
                }
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 22
                font.weight: Font.Light
            }
        }

        // What you can do without unlocking: sleep on one side, restart or shut down on the other
        Repeater {
            model: root.main ? [
                { icon: "sleep", left: true, command: ["systemctl", "suspend"] },
                { icon: "restart", left: false, command: ["systemctl", "reboot"], confirm: true },
                { icon: "power", left: false, command: ["systemctl", "poweroff"], confirm: true }
            ] : []

            Item {
                id: action

                required property var modelData
                required property int index
                property bool armed: false

                width: 48
                height: 48
                x: modelData.left ? 40 : root.width - 40 - width - (2 - index) * 60
                y: root.height - 40 - height
                opacity: root.reveal * (pointer.containsMouse || armed ? 1 : 0.6)

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: Qt.alpha(action.armed ? "#f0705f" : Theme.windowLit, action.armed ? 0.35 : pointer.containsMouse ? 0.18 : 0)
                }

                Icon {
                    anchors.centerIn: parent
                    name: action.modelData.icon
                    size: 24
                }

                Timer {
                    id: disarm

                    interval: 3000
                    onTriggered: action.armed = false
                }

                // Restarting or shutting down asks twice. The preview never does either.
                MouseArea {
                    id: pointer

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: {
                        if (action.modelData.confirm && !action.armed) {
                            action.armed = true;
                            disarm.restart();
                            return;
                        }
                        action.armed = false;
                        if (!root.preview)
                            launcher.exec(action.modelData.command);
                    }
                }
            }
        }
    }

    // A slow glow while the password is being checked
    property real pulse: 0

    SequentialAnimation on pulse {
        running: root.lock.checking
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 420; easing.type: Easing.InOutSine }
    }

    Process {
        id: launcher
    }

    // The keyboard. Escape leaves the preview, and on the real lock goes back to the landscape.
    // Every screen listens: after sleep, Hyprland can hand the keys to another one.
    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            event.accepted = true;
            if (!root.main)
                root.claimed();
            if (event.key === Qt.Key_CapsLock)
                capsCheck.restart();
            if (!root.lock.revealed && event.key !== Qt.Key_Escape)
                root.lock.wake();
            else if (event.key === Qt.Key_Escape)
                root.preview ? Menus.lockPreview = false : root.lock.back();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.lock.submit();
            else if (event.key === Qt.Key_Backspace)
                root.lock.erase();
            else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32)
                root.lock.type(event.text);
        }
        Component.onCompleted: forceActiveFocus()
    }

    // Caps Lock only changes after the key has gone through
    Timer {
        id: capsCheck

        interval: 60
        onTriggered: root.lock.readCaps()
    }
}
