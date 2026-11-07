import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.services

// A password for a new network. It goes to nmcli over stdin rather than as an
// argument, so it never shows up in the list of running processes. Without a network,
// it's a hidden one: its name comes first, and an open one goes without a password.
ColumnLayout {
    id: root

    property string network: ""
    readonly property bool hidden: network === ""
    readonly property string joining: hidden ? name.text.trim() : network

    signal finished()

    property bool failed: false

    function connect() {
        if (!joining || (!hidden && !field.text) || join.running)
            return;
        failed = false;
        join.command = ["nmcli", "--ask", "device", "wifi", "connect", joining].concat(hidden ? ["hidden", "yes"] : []);
        join.running = true;
    }

    spacing: 6

    Component.onCompleted: hidden ? name.forceActiveFocus() : field.forceActiveFocus()

    Process {
        id: join

        stdinEnabled: true
        onStarted: {
            write(field.text + "\n");
            stdinEnabled = false;
        }
        onExited: code => {
            stdinEnabled = true;
            if (code === 0)
                root.finished();
            else
                root.failed = true;
        }
    }

    Text {
        text: root.failed ? (root.hidden ? Lang.t("Connexion impossible.") : Lang.t("Mot de passe refusé.")) : join.running ? Lang.t("Connexion à {0}…", root.joining) : root.hidden ? Lang.t("Nom et mot de passe du réseau caché") : Lang.t("Mot de passe pour {0}", root.network)
        color: root.failed ? "#f0947c" : Qt.alpha(Theme.text, 0.75)
        font.family: Theme.font
        font.pixelSize: 12
    }

    Rectangle {
        visible: root.hidden
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 11
        color: Qt.alpha(Menus.tint, 0.12)
        border.width: 1
        border.color: Qt.alpha(Menus.tint, name.activeFocus ? 0.7 : 0.3)

        TextInput {
            id: name

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 14
            onAccepted: field.forceActiveFocus()
            Keys.onEscapePressed: root.finished()
            KeyNavigation.tab: field

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !name.text
                text: Lang.t("Nom du réseau")
                color: Qt.alpha(Theme.text, 0.4)
                font: name.font
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 11
        color: Qt.alpha(Menus.tint, 0.12)
        border.width: 1
        border.color: Qt.alpha(Menus.tint, field.activeFocus ? 0.7 : 0.3)

        TextInput {
            id: field

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            passwordCharacter: "✦"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 14
            onAccepted: root.connect()
            Keys.onEscapePressed: root.finished()

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hidden && !field.text
                text: Lang.t("Mot de passe, s'il y en a un")
                color: Qt.alpha(Theme.text, 0.4)
                font: field.font
            }
        }
    }
}
