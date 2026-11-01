import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

// A page is a tiny constellation: one star for each open window.
// The one you're on lights up.
Item {
    id: root

    required property int pageId
    property bool active: false

    // Each page keeps its shape, so you end up recognising it
    readonly property var layout: {
        const shapes = [[[0.14, 0.62], [0.36, 0.3], [0.58, 0.68], [0.82, 0.34], [0.5, 0.92], [0.06, 0.2]], [[0.12, 0.3], [0.34, 0.7], [0.6, 0.28], [0.86, 0.64], [0.4, 0.08], [0.1, 0.84]], [[0.18, 0.74], [0.3, 0.28], [0.62, 0.52], [0.84, 0.2], [0.8, 0.82], [0.48, 0.9]]];
        return shapes[(pageId - 1) % shapes.length];
    }
    readonly property int windows: Math.min(layout.length, Hyprland.toplevels.values.filter(t => t.workspace?.id === pageId).length)
    readonly property bool lit: active || mouse.containsMouse

    // Keeps stars low enough that their halo never runs off the top of the screen
    function starY(position) {
        return (0.3 + 0.62 * position) * height;
    }

    implicitWidth: Theme.pageWidth
    implicitHeight: Theme.barHeight
    anchors.verticalCenter: parent.verticalCenter

    onWindowsChanged: links.requestPaint()
    onLitChanged: links.requestPaint()

    // The thread between the stars, same as on the login screen
    Canvas {
        id: links

        anchors.fill: parent
        renderStrategy: Canvas.Immediate
        onPaint: {
            const g = getContext("2d");
            g.reset();
            if (root.windows < 2)
                return;
            g.strokeStyle = String(Theme.link);
            g.globalAlpha = root.lit ? 0.8 : 0.32;
            g.lineWidth = 1;
            g.beginPath();
            for (let i = 0; i < root.windows; i++) {
                const [px, py] = root.layout[i];
                i ? g.lineTo(px * width, root.starY(py)) : g.moveTo(px * width, root.starY(py));
            }
            g.stroke();
        }
    }

    // Even an empty page keeps one tiny star, so it doesn't vanish
    Star {
        visible: root.windows === 0
        anchors.centerIn: parent
        size: root.lit ? 6 : 3
        lit: root.lit

        Behavior on size {
            NumberAnimation { duration: Theme.fast }
        }
    }

    // And here come the stars, one per window
    Repeater {
        model: root.windows

        Star {
            required property int index

            size: root.lit ? 9 : 6
            lit: root.lit
            x: root.layout[index][0] * root.width - size
            y: root.starY(root.layout[index][1]) - size

            Behavior on size {
                NumberAnimation { duration: Theme.fast }
            }
        }
    }

    // One click and you're on this page
    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Planet.request(root.pageId)
    }
}
