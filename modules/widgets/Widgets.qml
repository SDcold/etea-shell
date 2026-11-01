import QtQuick
import qs.config

// The widgets living in the sky. Which ones and where is up to Config.widgets.
Item {
    id: root

    // In the sky style the widgets are one composition, so they each have their place
    readonly property bool skyStyle: Config.widgetStyle === "sky"
    // Each place is x, y, then which point of the widget sits there: 0 is its start, 1 its end
    readonly property var skyPlaces: ({ clock: [0.5, 0.5, 0.5, 0.5], system: [0.044, 0.085, 0, 0], media: [0.956, 0.085, 1, 0] })
    readonly property var files: skyStyle ? { clock: "GiantClock.qml", system: "SkySystem.qml", media: "SkyMedia.qml" } : { clock: "ClockWidget.qml", system: "SystemWidget.qml", media: "MediaWidget.qml" }

    Repeater {
        model: Config.widgets.filter(widget => widget.shown !== false)

        Loader {
            required property var modelData

            readonly property var place: root.skyStyle ? root.skyPlaces[modelData.type] : [modelData.x, modelData.y, 0.5, 0.5]

            x: place[0] * root.width - width * place[2]
            y: place[1] * root.height - height * place[3]
            source: root.files[modelData.type] ?? ""

            // Sky widgets are sized from the screen, so they look the same on any display
            onLoaded: {
                if ("sky" in item)
                    item.sky = Qt.binding(() => root.height);
            }
        }
    }
}
