import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

// One end of the bar, or its middle: the modules Config.barLayout puts there, in order.
Row {
    id: root

    required property var modules
    required property string monitorName
    property real windowY: 0
    property real span: 0 // the bar's width, to know where the touchdown light is

    spacing: Theme.barSpacing
    height: Theme.barHeight

    Repeater {
        model: root.modules

        Loader {
            id: slot

            required property string modelData
            // Landing on a new world, the light lifts each module as it runs past
            readonly property real touched: Planet.touchdownAt(root.x + x + width / 2 - root.span / 2, root.span)

            anchors.verticalCenter: parent.verticalCenter
            visible: item !== null && (item.wanted ?? true)
            transform: Translate {
                y: -3 * slot.touched
            }
            // The ids end in Part so none of them hides one of the Loader's own properties, like status
            sourceComponent: ({ pages: pagesPart, clock: clockPart, media: mediaPart, tray: trayPart, status: statusPart, tools: toolsPart, resources: resourcesPart })[modelData] ?? null

            // Text sits right on the sky, a soft glow lifts it off the background. Stars glow on their own.
            layer.enabled: modelData !== "pages"
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                shadowEnabled: true
                shadowColor: Theme.textGlow
                shadowOpacity: 0.55 + 0.45 * slot.touched
                shadowBlur: 1
                blurMax: 32
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
        }
    }

    Component {
        id: pagesPart

        Pages {
            monitorName: root.monitorName
            windowY: root.windowY
        }
    }

    Component {
        id: clockPart

        Clock {}
    }

    Component {
        id: mediaPart

        Media {}
    }

    Component {
        id: trayPart

        Tray {}
    }

    Component {
        id: statusPart

        Status {}
    }

    Component {
        id: toolsPart

        Tools {}
    }

    Component {
        id: resourcesPart

        Resources {}
    }
}
