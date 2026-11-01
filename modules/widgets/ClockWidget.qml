import QtQuick
import Quickshell
import qs.config
import qs.modules.bar
import qs.services

// The big clock in the sky, with a star going round it once a minute.
Item {
    id: root

    property real angle: 0

    implicitWidth: 520
    implicitHeight: 230

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // Starts from the real second, then keeps gliding
    NumberAnimation on angle {
        id: orbit

        from: (new Date().getSeconds() / 60) * Math.PI * 2 - Math.PI / 2
        to: from + Math.PI * 2
        duration: 60000
        loops: Animation.Infinite
        running: Planet.pageEmpty
    }

    Canvas {
        anchors.fill: parent
        renderStrategy: Canvas.Immediate
        onPaint: {
            const g = getContext("2d");
            g.reset();
            g.strokeStyle = String(Theme.windowLit);
            g.globalAlpha = 0.35;
            g.lineWidth = 1;
            g.beginPath();
            g.ellipse(6, 6, width - 12, height - 12);
            g.stroke();
        }
    }

    Star {
        x: parent.width / 2 + (parent.width / 2 - 6) * Math.cos(root.angle) - size
        y: parent.height / 2 + (parent.height / 2 - 6) * Math.sin(root.angle) - size
        size: 9
        lit: true
        animated: false
    }

    Column {
        anchors.centerIn: parent
        spacing: -8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 118
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale(Config.locale).toString(clock.date, "dddd d MMMM")
            color: Theme.textSoft
            font.family: Theme.font
            font.pixelSize: 24
        }
    }
}
