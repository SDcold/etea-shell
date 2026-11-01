import QtQuick
import qs.config

// The widgets living in the sky. Which ones and where is up to Config.widgets.
Item {
    id: root

    Repeater {
        model: Config.widgets

        Loader {
            required property var modelData

            x: modelData.x * root.width - width / 2
            y: modelData.y * root.height - height / 2
            // Wide widgets want to know how much screen they have
            onLoaded: {
                if ("span" in item)
                    item.span = Qt.binding(() => root.width);
            }
            source: ({
                    visualizer: "VisualizerWidget.qml",
                    clock: "ClockWidget.qml",
                    system: "SystemWidget.qml",
                    media: "MediaWidget.qml"
                })[modelData.type] ?? ""
        }
    }
}
