import QtQuick
import QtQuick.Layouts
import qs.config

// What shows on the right side of the bar.
ColumnLayout {
    spacing: 18

    Text {
        text: "Barre"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    Repeater {
        model: Config.statusChoices

        SettingSwitch {
            required property var modelData

            label: modelData.label
            on: Config.status.includes(modelData.id)
            onToggled: {
                const wanted = on ? Config.status.filter(id => id !== modelData.id) : Config.status.concat([modelData.id]);
                Config.status = Config.statusChoices.map(choice => choice.id).filter(id => wanted.includes(id));
            }
        }
    }
}
