import QtQuick
import QtQuick.Shapes
import qs.config

// The four-pointed star, the one you keep running into all over ETEA.
Item {
    id: root

    property real size: 8
    property bool lit: false
    property bool appear: true
    property bool animated: true // false for stars that are simply there, like on a frame
    property color fill: Theme.star // when lit
    property color glow: Theme.starGlow
    property bool halo: true

    width: size * 2
    height: size * 2
    scale: animated ? 0 : 1

    onAppearChanged: {
        if (!animated)
            return;
        birth.stop();
        if (appear)
            birth.start();
        else
            scale = 0;
    }

    Component.onCompleted: {
        if (appear && animated)
            birth.start();
    }

    // It's born a little too big, then settles back down
    SequentialAnimation {
        id: birth

        NumberAnimation {
            target: root
            property: "scale"
            to: 1.5
            duration: Theme.fast
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: Theme.normal
            easing.type: Easing.OutBack
        }
    }

    // The halo, which is what really sells the shine
    Shape {
        id: halo

        readonly property real radius: root.size * 2.4

        anchors.centerIn: parent
        width: radius * 2
        height: radius * 2
        visible: root.halo
        opacity: root.lit ? 1 : 0
        preferredRendererType: Shape.CurveRenderer

        Behavior on opacity {
            NumberAnimation { duration: Theme.normal }
        }

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: halo.radius
                centerY: halo.radius
                focalX: centerX
                focalY: centerY
                centerRadius: halo.radius

                GradientStop { position: 0; color: Qt.alpha(root.glow, 0.8) }
                GradientStop { position: 0.4; color: Qt.alpha(root.glow, 0.24) }
                GradientStop { position: 1; color: Qt.alpha(root.glow, 0) }
            }

            PathAngleArc {
                centerX: halo.radius
                centerY: halo.radius
                radiusX: halo.radius
                radiusY: halo.radius
                sweepAngle: 360
            }
        }
    }

    // The star itself, four points curving in towards the centre
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: root.lit ? 1 : 0.55

        Behavior on opacity {
            NumberAnimation { duration: Theme.normal }
        }

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.lit ? root.fill : Theme.starAsleep
            startX: root.size
            startY: 0

            PathQuad { x: root.size * 2; y: root.size; controlX: root.size * 1.15; controlY: root.size * 0.85 }
            PathQuad { x: root.size; y: root.size * 2; controlX: root.size * 1.15; controlY: root.size * 1.15 }
            PathQuad { x: 0; y: root.size; controlX: root.size * 0.85; controlY: root.size * 1.15 }
            PathQuad { x: root.size; y: 0; controlX: root.size * 0.85; controlY: root.size * 0.85 }
        }
    }
}
