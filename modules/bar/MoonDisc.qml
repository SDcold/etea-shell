import QtQuick
import qs.config

// Tonight's moon, drawn from the real date.
Canvas {
    id: root

    property date at: new Date() // widgets that stay up for days keep this current

    // How far through its cycle the moon is, from 0 at new moon round to 1
    readonly property real phase: {
        const reference = Date.UTC(2000, 0, 6, 18, 14);
        const days = (at.getTime() - reference) / 86400000;
        return (days / 29.530588 % 1 + 1) % 1;
    }
    readonly property string phaseName: [Lang.t("Nouvelle lune"), Lang.t("Premier croissant"), Lang.t("Premier quartier"), Lang.t("Gibbeuse croissante"), Lang.t("Pleine lune"), Lang.t("Gibbeuse décroissante"), Lang.t("Dernier quartier"), Lang.t("Dernier croissant")][Math.round(phase * 8) % 8]

    property color dark: "#2a2c44"
    property color light: "#f4ead8"

    implicitWidth: 30
    implicitHeight: 30
    renderStrategy: Canvas.Immediate

    onWidthChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onPaint: {
        const g = getContext("2d"), r = width / 2 - 2, cx = width / 2, cy = height / 2;
        const lit = Math.cos(phase * Math.PI * 2);
        g.reset();
        g.fillStyle = String(dark);
        g.beginPath();
        g.arc(cx, cy, r, 0, Math.PI * 2);
        g.fill();
        g.fillStyle = String(light);
        g.beginPath();
        const waxing = phase < 0.5;
        g.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, !waxing);
        g.ellipse(cx - Math.abs(lit) * r, cy - r, Math.abs(lit) * r * 2, r * 2);
        g.fill();
    }
}
