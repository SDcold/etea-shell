import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.background
import qs.modules.bar
import qs.modules.stage
import qs.services

// What one screen of the lock shows. Only the main screen listens to the keyboard and
// shows the woman; the others keep the landscape.
Item {
    id: root

    required property var lock
    property bool main: false
    property bool preview: false

    readonly property var scene: lock.scene
    readonly property real unit: height
    readonly property point shoulder: scene ? Qt.point(width / 2 + scene.shoulder[0] * unit, scene.shoulder[1] * unit) : Qt.point(0, 0)
    readonly property real reach: scene ? (scene.arm.hand - scene.arm.pivot[0]) * scene.arm.width * unit : 1

    // The sky opens fast; she rises slow, fast, slow. Going back, she sinks first.
    property real reveal: main && lock.revealed ? 1 : 0
    property real lift: main && lock.revealed ? 1 : 0

    Behavior on reveal {
        SequentialAnimation {
            PauseAnimation { duration: root.lock.revealed ? 0 : 520 }
            NumberAnimation { duration: 300; easing.type: root.lock.revealed ? Easing.OutCubic : Easing.InCubic }
        }
    }

    Behavior on lift {
        NumberAnimation { duration: root.lock.revealed ? 1100 : 700; easing.type: Easing.InOutCubic }
    }

    // The same tiny wobble for star number n every time, whatever key made it
    function jitter(n, salt) {
        const x = Math.sin(n * 12.9898 + salt * 78.233) * 43758.5453;
        return x - Math.floor(x) - 0.5;
    }

    // Stars line up on an arc around her shoulder, a new row further in once one is full
    function starAt(n) {
        if (!scene)
            return { x: 0, y: 0, angle: 0, radius: reach };
        const [from, to] = scene.arc, step = scene.step, direction = to < from ? -1 : 1;
        const perRow = Math.floor(Math.abs(to - from) / step) + 1;
        const row = Math.floor(n / perRow), place = n % perRow;
        const angle = from + direction * place * step + jitter(n, 1) * step * 0.4;
        const radius = reach - row * scene.rowGap * unit + jitter(n, 2) * 0.014 * unit;
        const r = angle * Math.PI / 180;
        return { x: shoulder.x + Math.cos(r) * radius, y: shoulder.y + Math.sin(r) * radius, angle: angle, radius: radius };
    }

    opacity: lock.leaving ? 0 : 1

    Behavior on opacity {
        NumberAnimation { duration: 260 }
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

        // A night sky of its own, set in scene.json, whatever world you live on
        ShaderEffect {
            anchors.fill: parent

            property color colorTop: root.scene?.sky?.top ?? Theme.skyTop
            property color colorMid: root.scene?.sky?.middle ?? Theme.skyMid
            property color colorLow: root.scene?.sky?.low ?? Theme.skyLow
            property vector2d resolution: Qt.vector2d(width, height)
            property real grain: Theme.grain
            property real space: root.scene?.sky?.stars ?? 0.86

            fragmentShader: Qt.resolvedUrl("../../shaders/sky.frag.qsb")
        }

        // A thin thread from each star to the next, in the order they came
        Canvas {
            id: links

            anchors.fill: parent
            opacity: root.lock.vanishing ? 0 : 1
            renderStrategy: Canvas.Immediate
            onPaint: {
                const g = getContext("2d");
                g.reset();
                if (root.lock.stars < 2)
                    return;
                g.strokeStyle = String(Theme.link);
                g.globalAlpha = 0.45;
                g.lineWidth = 1;
                g.beginPath();
                for (let n = 0; n < root.lock.stars; n++) {
                    const star = root.starAt(n);
                    n ? g.lineTo(star.x, star.y) : g.moveTo(star.x, star.y);
                }
                g.stroke();
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Connections {
                target: root.lock

                function onStarsChanged() {
                    links.requestPaint();
                }
            }
        }

        Repeater {
            model: root.main ? root.lock.stars : 0

            Star {
                id: star

                required property int index
                readonly property var spot: root.starAt(index)
                readonly property bool newest: index === root.lock.stars - 1

                x: spot.x - size
                y: spot.y - size
                size: (newest ? 10 : 7) * (root.lock.capsLock ? 1.4 : 1)
                lit: true
                opacity: root.lock.vanishing ? 0 : root.lock.checking ? 0.55 + 0.45 * root.pulse : newest ? 1 : root.lock.capsLock ? 0.95 : 0.7
                scale: root.lock.vanishing ? 0.3 : 1

                Behavior on size {
                    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: root.lock.vanishing ? 220 + star.index * 30 : 200 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 220 + star.index * 30; easing.type: Easing.InCubic }
                }
            }
        }

        // The newest star burns warm behind her hand and shines out between the fingers
        Canvas {
            id: glint

            readonly property var spot: root.lock.stars > 0 ? root.starAt(root.lock.stars - 1) : null
            readonly property color tint: root.scene?.glow?.color ?? "#ffcf8a"

            width: (root.scene?.glow?.size ?? 0.2) * root.unit
            height: width
            x: (spot?.x ?? 0) - width / 2
            y: (spot?.y ?? 0) - height / 2
            visible: root.main && spot !== null
            opacity: root.lock.vanishing ? 0 : root.lock.checking ? 0.6 + 0.4 * root.pulse : 1
            scale: root.lock.capsLock ? 1.3 : 1
            renderStrategy: Canvas.Immediate
            // A hidden canvas drops paint requests, so ask again whenever it shows up
            onWidthChanged: requestPaint()
            onTintChanged: requestPaint()
            onVisibleChanged: requestPaint()
            onAvailableChanged: requestPaint()
            // Canvas wants CSS colours, so transparency goes through rgba()
            function rgba(color, alpha) {
                return `rgba(${Math.round(color.r * 255)}, ${Math.round(color.g * 255)}, ${Math.round(color.b * 255)}, ${alpha})`;
            }

            onPaint: {
                const g = getContext("2d"), c = width / 2;
                g.reset();
                const halo = g.createRadialGradient(c, c, 0, c, c, c * 0.62);
                halo.addColorStop(0, "rgba(255, 250, 240, 1)");
                halo.addColorStop(0.14, rgba(tint, 0.95));
                halo.addColorStop(0.45, rgba(tint, 0.4));
                halo.addColorStop(1, rgba(tint, 0));
                g.fillStyle = halo;
                g.fillRect(0, 0, width, height);
                // Long thin rays, the way a bright star looks through a lens
                for (const [w, h] of [[c * 0.8, 1.6], [1.6, c]]) {
                    const ray = g.createRadialGradient(c, c, 0, c, c, Math.max(w, h));
                    ray.addColorStop(0, "rgba(255, 243, 220, 0.95)");
                    ray.addColorStop(1, rgba(tint, 0));
                    g.fillStyle = ray;
                    g.fillRect(c - w, c - h, w * 2, h * 2);
                }
            }

            Behavior on x {
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            Behavior on scale {
                NumberAnimation { duration: 260 }
            }
        }

        Image {
            readonly property var info: root.scene?.clouds ?? null

            visible: info !== null
            height: (info?.height ?? 0) * root.unit
            width: height * (implicitHeight > 0 ? implicitWidth / implicitHeight : 2)
            x: root.width / 2 + (info?.x ?? 0) * root.unit - width / 2
            y: (info?.bottom ?? 1) * root.unit - height
            opacity: info?.opacity ?? 1
            source: info ? Quickshell.shellPath(`assets/lock/${info.file}`) : ""
            sourceSize.height: height
        }

        // Her, rising from the bottom of the screen. The hand is sharp, the body soft and close.
        Item {
            id: her

            anchors.fill: parent
            visible: root.main && root.scene !== null
            transform: Translate { y: (1 - root.lift) * root.height * 0.8 }

            Image {
                id: arm

                readonly property var info: root.scene?.arm ?? { width: 0.5, pivot: [0, 0.5] }
                readonly property real pivotX: width * info.pivot[0]
                readonly property real pivotY: height * info.pivot[1]
                readonly property var target: root.lock.stars > 0 ? root.starAt(root.lock.stars - 1) : null
                property real angle: target ? target.angle : root.scene?.rest ?? 70
                property real stretch: target ? target.radius / root.reach : 1

                width: info.width * root.unit
                height: width * (implicitWidth > 0 ? implicitHeight / implicitWidth : 0.2)
                x: root.shoulder.x - pivotX
                y: root.shoulder.y - pivotY
                source: root.scene ? Quickshell.shellPath(`assets/lock/${info.file}`) : ""
                sourceSize.width: width * 2
                smooth: true
                transform: [
                    Scale {
                        origin.x: arm.pivotX
                        origin.y: arm.pivotY
                        xScale: arm.stretch
                    },
                    Rotation {
                        origin.x: arm.pivotX
                        origin.y: arm.pivotY
                        angle: arm.angle
                    }
                ]

                Behavior on angle {
                    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                }
                Behavior on stretch {
                    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                }
            }

            Image {
                id: body

                readonly property var info: root.scene?.body ?? { x: 0, bottom: 1, height: 0.6, blur: 0.5 }

                height: info.height * root.unit
                width: height * (implicitHeight > 0 ? implicitWidth / implicitHeight : 1)
                x: root.width / 2 + info.x * root.unit - width / 2
                y: info.bottom * root.unit - height
                source: root.scene ? Quickshell.shellPath(`assets/lock/${info.file}`) : ""
                sourceSize.height: height
                visible: false
            }

            MultiEffect {
                anchors.fill: body
                source: body
                blurEnabled: true
                blur: body.info.blur ?? 0.5
                blurMax: 48
                autoPaddingEnabled: true
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
    Item {
        anchors.fill: parent
        focus: root.main
        Keys.onPressed: event => {
            event.accepted = true;
            if (event.key === Qt.Key_Escape)
                root.preview ? Menus.lockPreview = false : root.lock.back();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.lock.submit();
            else if (event.key === Qt.Key_Backspace)
                root.lock.erase();
            else if (event.key === Qt.Key_CapsLock)
                capsCheck.restart();
            else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32)
                root.lock.type(event.text);
        }
        Component.onCompleted: {
            if (root.main)
                forceActiveFocus();
        }
    }

    // Caps Lock only changes after the key has gone through
    Timer {
        id: capsCheck

        interval: 60
        onTriggered: root.lock.readCaps()
    }
}
