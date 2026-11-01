import QtQuick
import qs.config

// The widgets living in the sky. Which ones and where is up to Config.widgets.
Item {
    id: root

    Repeater {
        model: Config.widgets.filter(widget => widget.shown !== false)

        Loader {
            required property var modelData

            // The giant clock always stands in the middle of the sky, wherever the dial was
            readonly property bool giant: modelData.type === "clock" && Config.clockStyle === "giant"

            x: (giant ? 0.5 : modelData.x) * root.width - width / 2
            y: (giant ? 0.5 : modelData.y) * root.height - height / 2
            source: ({
                    clock: Config.clockStyle === "giant" ? "GiantClock.qml" : "ClockWidget.qml",
                    system: "SystemWidget.qml",
                    media: "MediaWidget.qml"
                })[modelData.type] ?? ""
        }
    }
}
