import QtQuick
import QtQuick.Layouts
import qs.config

// How much time the shell takes for its big movements.
ColumnLayout {
    spacing: 18

    Text {
        text: "Mouvement"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 20
    }

    SettingChoice {
        label: "Rythme"
        hint: "Quotidien reste vif. Cérémonie prend le temps de chaque geste."
        options: [{ id: "daily", label: "Quotidien" }, { id: "ceremony", label: "Cérémonie" }]
        current: Config.pace
        onPicked: id => Config.pace = id
    }
}
