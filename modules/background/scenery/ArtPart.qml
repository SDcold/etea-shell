import QtQuick
import QtQuick.Shapes

// One piece of a world's scenery: flat shapes, each in a tone of the planet's palette,
// so a world you recolour keeps its scenery in tune.
Item {
    id: root

    required property var part
    required property var planet
    property real unit: 1

    // A tone is [a], [a, b, t] or [a, b, t, alpha]: a mixed towards b by t
    function named(name) {
        if (name.startsWith("#"))
            return name;
        if (name === "white")
            return "#ffffff";
        if (name === "night")
            return "#070812";
        if (/^t[0-3]$/.test(name))
            return planet.terrain[Number(name[1])];
        return planet[name];
    }

    function tone(spec) {
        const a = Qt.color(named(spec[0])), b = spec.length > 1 ? Qt.color(named(spec[1])) : a;
        const t = spec[2] ?? 0;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, spec[3] ?? 1);
    }

    width: part.w * unit
    height: part.h * unit

    Repeater {
        model: root.part.layers

        Shape {
            required property var modelData

            width: root.part.w
            height: root.part.h
            scale: root.unit
            transformOrigin: Item.TopLeft
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillColor: root.tone(modelData.tone)
                fillRule: modelData.evenOdd ? ShapePath.OddEvenFill : ShapePath.WindingFill

                PathSvg {
                    path: modelData.d
                }
            }
        }
    }
}
