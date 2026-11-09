import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.bar
import qs.modules.stage
import qs.services

// What the Réglages window holds: the sections down the side with a search above them,
// and the page or the search's results. Kept apart from the window so it can be drawn
// offscreen too.
Item {
    id: window

    property bool showing: true // the window is up

    property int section: 0 // the page asked for
    property int shown: 0 // and the one on screen, which follows once the old one has gone
    property string pending: "" // a row to light once its page is in
    readonly property var sections: Atlas.pages
    readonly property string query: search.text.trim()
    readonly property var results: query ? Atlas.search(query, section).slice(0, 40) : []

    // Somewhere to go: a setting's key, "@page", "?words", or "world@id" (":tab" after it
    // opens one of its strata) for a world's editor
    property string world: ""

    function go(address) {
        if (!address)
            return;
        if (address.startsWith("world@")) {
            world = address.slice(6);
            open(0, "");
            if (shown === 0)
                openWorld();
            return;
        }
        const place = Atlas.resolve(address);
        if (place.search !== undefined) {
            search.text = place.search;
            return;
        }
        open(place.page, place.entry?.label ?? "");
    }

    function open(page, row) {
        search.text = "";
        pending = row;
        section = page;
        if (shown === page)
            light();
    }

    // A world's editor, once the worlds' page is in
    function openWorld() {
        if (!world || !page.item)
            return;
        const [id, tab] = world.split(":");
        world = "";
        page.item.editing = id;
        scroller.contentY = 0;
        if (tab)
            Qt.callLater(() => {
                const editor = find(page.item, node => node.tabs !== undefined && node.planetId !== undefined);
                if (editor)
                    editor.tab = tab;
            });
    }

    function find(node, wanted) {
        for (const child of node.children ?? []) {
            if (wanted(child))
                return child;
            const found = find(child, wanted);
            if (found)
                return found;
        }
        return null;
    }

    // The row a search or a link was for: scrolled into view, its star lit a moment
    function light() {
        if (!pending || !page.item)
            return;
        const find = node => {
            for (const child of node.children ?? []) {
                if ((child.objectName === "setting" && child.label === pending) || (child.objectName === "section" && child.text === pending))
                    return child;
                const found = find(child);
                if (found)
                    return found;
            }
            return null;
        };
        const row = find(page.item);
        pending = "";
        if (!row)
            return;
        const y = row.mapToItem(page, 0, 0).y;
        scroller.contentY = Math.max(0, Math.min(scroller.contentHeight - scroller.height, y - 90));
        if (row.objectName === "setting") {
            row.found = true;
            unlight.row = row;
            unlight.restart();
        }
    }

    // The window it's in is showing: go wherever it was asked to open
    function arrive() {
        if (Menus.settingsTarget) {
            go(Menus.settingsTarget);
            Menus.settingsTarget = "";
        }
    }

    // Asked for somewhere while already open
    Connections {
        target: Menus

        function onSettingsTargetChanged() {
            if (window.showing && Menus.settingsTarget) {
                window.go(Menus.settingsTarget);
                Menus.settingsTarget = "";
            }
        }
    }

    Timer {
        id: unlight

        property var row: null

        interval: 1600
        onTriggered: {
            if (row)
                row.found = false;
        }
    }

    // Ctrl+F, or / anywhere, goes to the search
    Shortcut {
        sequences: [StandardKey.Find, "/"]
        onActivated: search.forceActiveFocus()
    }

    HandCard {
        anchors.fill: parent
        anchors.margins: -8
        seed: "settings"
        radius: 1
        ink: 0
        rise: 0.05
        tint: Theme.windowLit
        alive: window.showing
    }

    Item {
        id: side

        x: 30
        y: 36
        width: 190
        height: parent.height - 60

        readonly property real first: 104 // the first section's middle
        readonly property real step: 50

        Text {
            text: Lang.t("Réglages")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 26
            font.weight: Font.Light
        }

        // The search, on a line of ink that wakes when you type
        Item {
            y: 46
            width: side.width - 6
            height: 30

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                size: 15
                tint: Qt.alpha(Theme.text, search.activeFocus ? 0.8 : 0.5)
            }

            TextInput {
                id: search

                x: 24
                width: parent.width - x
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Qt.alpha(Theme.link, 0.4)
                font.family: Theme.font
                font.pixelSize: 14
                clip: true
                Keys.onReturnPressed: {
                    if (window.results.length)
                        window.open(window.results[0].page, window.results[0].label);
                }
                Keys.onEscapePressed: text = ""

                Text {
                    visible: !search.text
                    text: Lang.t("Chercher un réglage")
                    color: Qt.alpha(Theme.text, 0.4)
                    font: search.font
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: search.activeFocus || search.text ? parent.width : parent.width * 0.4
                height: 1
                color: Qt.alpha(Theme.link, search.activeFocus ? 0.75 : 0.35)

                Behavior on width {
                    NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
                }
            }
        }

        // The thread running through the sections
        Rectangle {
            x: 9
            y: side.first
            width: 1
            height: (window.sections.length - 1) * side.step
            color: Qt.alpha(Theme.link, 0.35)
        }

        Repeater {
            model: window.sections

            Item {
                id: entry

                required property var modelData
                required property int index

                readonly property bool active: index === window.section && !window.query

                y: side.first - height / 2 + index * side.step
                width: side.width
                height: 36

                Star {
                    x: 10 - size
                    y: parent.height / 2 - size
                    size: 4
                    lit: false
                    animated: false
                }

                Text {
                    x: 32
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.label
                    color: entry.active ? Theme.text : Qt.alpha(Theme.text, 0.65)
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.weight: entry.active ? Font.Medium : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: window.open(entry.index, "")
                }
            }
        }

        // The lit star travels the thread to the section you go to
        Star {
            x: 10 - size
            y: side.first + window.section * side.step - size
            size: 9
            lit: true
            animated: false
            opacity: window.query ? 0.35 : 1

            Behavior on y {
                NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.normal }
            }
        }
    }

    // The clipping edge sits a little outside the content, so the stars and ink lines
    // around the cards have room and don't get sliced off
    Flickable {
        id: scroller

        readonly property int room: 18

        x: side.x + side.width + 30 - room
        y: 36 - room
        width: parent.width - x - 40 + room
        height: parent.height - 60 + room * 2
        contentHeight: (window.query ? found.height : page.height) + 20 + room * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // A page leaves a little upward and fades, the next one rises into place
        Item {
            id: pageHolder

            width: parent.width
            height: page.height
            visible: !window.query

            Loader {
                id: page

                x: scroller.room
                y: scroller.room
                width: parent.width - scroller.room * 2
                source: window.sections[window.shown].page
                onLoaded: {
                lightLater.restart();
                window.openWorld();
            }
            }
        }

        // What a search found, best first, each with where it lives
        Column {
            id: found

            x: scroller.room
            y: scroller.room
            width: parent.width - scroller.room * 2
            visible: !!window.query
            spacing: 4

            Text {
                visible: window.results.length === 0
                text: Lang.t("Rien de ce nom ici. Essaie un autre mot.")
                color: Qt.alpha(Theme.text, 0.55)
                font.family: Theme.font
                font.pixelSize: 14
                topPadding: 8
            }

            Repeater {
                model: window.results

                Item {
                    id: result

                    required property var modelData
                    required property int index

                    width: found.width
                    height: lines.implicitHeight + 18

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        color: Theme.windowLit
                        opacity: pointer.containsMouse ? 0.09 : result.index === 0 ? 0.05 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.fast }
                        }
                    }

                    Star {
                        x: -11 - size
                        y: 9 + 10 - size
                        size: result.index === 0 || pointer.containsMouse ? 5 : 3
                        lit: result.index === 0 || pointer.containsMouse
                        animated: false
                    }

                    Column {
                        id: lines

                        x: 12
                        y: 9
                        width: parent.width - 24
                        spacing: 2

                        Text {
                            width: parent.width
                            text: result.modelData.label
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: result.modelData.pageLabel + (result.modelData.section ? " › " + result.modelData.section : "")
                            color: Qt.alpha(Theme.link, 0.75)
                            font.family: Theme.font
                            font.pixelSize: 12
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: result.modelData.hint
                            color: Qt.alpha(Theme.text, 0.5)
                            font.family: Theme.font
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: pointer

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.open(result.modelData.page, result.modelData.label)
                    }
                }
            }
        }
    }

    Timer {
        id: lightLater

        interval: 60
        onTriggered: window.light()
    }

    // Going to another page: the old one leaves upward, the new one rises in its place
    onSectionChanged: swap.restart()

    SequentialAnimation {
        id: swap

        ParallelAnimation {
            NumberAnimation { target: pageHolder; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InQuad }
            NumberAnimation { target: pageHolder; property: "y"; to: -10; duration: 110; easing.type: Easing.InQuad }
        }
        ScriptAction {
            script: {
                window.shown = window.section;
                scroller.contentY = 0;
                pageHolder.y = 12;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: pageHolder; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: pageHolder; property: "y"; to: 0; duration: 260; easing.type: Easing.OutCubic }
        }
    }
}
