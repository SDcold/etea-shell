import QtQuick
import qs.config
import qs.modules.bar
import qs.services

// The top of the climb: every world you could live on, hanging in space. Drag them past,
// or scroll, and the one in front is tried on. Landing on it makes it home.
Item {
    id: root

    readonly property real level: Planet.systemLevel
    readonly property var chosen: Planets.all[Planet.systemChoice]
    // Arriving, the camera is still rising: the worlds start out close and spread apart,
    // the neighbours come in from beyond the edges and everything settles to its size
    readonly property real spacing: width * 0.3 * (1 + 1.4 * (1 - level))
    // The planet in front takes over from the stage's own, so it has to be exactly as big:
    // the stage camera's radius at this level, over a PlanetView's (620 of its 1600 units)
    readonly property real frontScale: 190 * (1 - 0.22 * level) * (width / 1600) / (620 * 440 / 1600)

    // How far a planet is from the front, going the short way round
    function place(index) {
        const count = Planets.all.length;
        const distance = ((index - Planet.systemScroll) % count + count) % count;
        return distance >= count / 2 ? distance - count : distance;
    }

    opacity: level
    visible: level > 0.01

    Repeater {
        model: Planets.all

        Item {
            id: world

            required property var modelData
            required property int index

            readonly property real position: root.place(index)
            readonly property real closeness: Math.max(0, 1 - Math.abs(position))

            width: 440
            height: 440
            x: root.width / 2 - width / 2 + position * root.spacing
            y: root.height * 0.44 - height / 2
            z: 1 + closeness
            scale: (0.42 + 0.58 * closeness) * root.frontScale
            opacity: 1 - Math.max(0, Math.abs(position) - 1) * 0.65

            PlanetView {
                anchors.fill: parent
                planet: world.modelData
                spinning: root.visible
                // Your own world carries on turning from where the stage left it
                startAngle: world.modelData.id === Theme.planet.id ? Planet.resting + Planet.travel - Planet.handTurn : 0
            }
        }
    }

    // Grab the sky and the planets follow your hand. A plain click picks the planet under it.
    MouseArea {
        id: hands

        property real pressedX: 0
        property real lastX: 0
        property real lastTime: 0
        property real speed: 0
        property real wheelTravel: 0
        property bool dragging: false

        // Which planet is under the pointer, as its place in the row
        function planetAt(x, y) {
            for (const position of [0, -1, 1]) {
                const reach = position ? 92 : 190;
                if (Math.hypot(x - root.width / 2 - position * root.spacing, y - root.height * 0.44) < reach)
                    return position;
            }
            return null;
        }

        anchors.fill: parent
        z: 10
        enabled: Planet.inSystem
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onPressed: mouse => {
            pressedX = mouse.x;
            lastX = mouse.x;
            lastTime = Date.now();
            speed = 0;
            dragging = false;
        }

        onPositionChanged: mouse => {
            if (!dragging && Math.abs(mouse.x - pressedX) < 8)
                return;
            dragging = true;
            const now = Date.now(), change = (lastX - mouse.x) / root.spacing;
            Planet.dragSystem(change);
            speed = Math.max(-6, Math.min(6, change / Math.max(1, now - lastTime) * 1000));
            lastX = mouse.x;
            lastTime = now;
        }

        onReleased: mouse => {
            if (dragging) {
                dragging = false;
                // Holding still before letting go shouldn't throw the row
                Planet.releaseSystem(Date.now() - lastTime > 120 ? 0 : speed);
                return;
            }
            const position = planetAt(mouse.x, mouse.y);
            if (position === 0)
                Planet.land(root.chosen.id);
            else if (position !== null)
                Planet.chooseStep(position);
        }

        onWheel: wheel => {
            wheelTravel += wheel.angleDelta.y || wheel.angleDelta.x;
            if (Math.abs(wheelTravel) >= 120) {
                Planet.chooseStep(wheelTravel > 0 ? -1 : 1);
                wheelTravel = 0;
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.74
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.chosen.name
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 34
            font.weight: Font.Light
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.chosen.line
            color: Qt.alpha(Theme.text, 0.7)
            font.family: Theme.font
            font.pixelSize: 15
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 12
            text: root.chosen.id === Config.theme ? Lang.t("Tu vis ici") : Lang.t("Entrée pour t'y poser")
            color: root.chosen.light
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
