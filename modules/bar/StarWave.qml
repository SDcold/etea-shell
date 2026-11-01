import QtQuick
import qs.config
import qs.services

// The music as a constellation: stars rising and falling, joined by the same fine thread.
Canvas {
    id: root

    property color tint: Theme.windowLit
    property bool listening: true

    implicitHeight: 44
    renderStrategy: Canvas.Immediate

    onListeningChanged: listening ? Beat.join() : Beat.leave()
    Component.onCompleted: {
        if (listening)
            Beat.join();
    }
    Component.onDestruction: {
        if (listening)
            Beat.leave();
    }

    Connections {
        target: Beat

        function onLevelsChanged() {
            root.requestPaint();
        }
    }

    onPaint: {
        const g = getContext("2d");
        g.reset();
        const levels = Beat.levels, count = levels.length;
        if (count < 2)
            return;
        const point = i => [i / (count - 1) * width, height - 3 - levels[i] * (height - 6)];

        g.strokeStyle = String(tint);
        g.globalAlpha = 0.6;
        g.lineWidth = 1;
        g.beginPath();
        for (let i = 0; i < count; i++) {
            const [x, y] = point(i);
            i ? g.lineTo(x, y) : g.moveTo(x, y);
        }
        g.stroke();

        g.fillStyle = "#ffffff";
        for (let i = 0; i < count; i++) {
            const [x, y] = point(i), s = 1.2 + levels[i] * 3.4;
            g.globalAlpha = 0.5 + levels[i] * 0.5;
            g.beginPath();
            g.moveTo(x, y - s);
            g.quadraticCurveTo(x, y, x + s, y);
            g.quadraticCurveTo(x, y, x, y + s);
            g.quadraticCurveTo(x, y, x - s, y);
            g.quadraticCurveTo(x, y, x, y - s);
            g.fill();
        }
    }
}
