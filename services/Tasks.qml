pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Your to-do list, kept in ~/.config/etea/tasks.json.
Singleton {
    id: root

    property alias items: saved.items

    function add(text) {
        if (text.trim())
            items = items.concat([{ text: text.trim(), done: false }]);
    }

    function toggle(index) {
        items = items.map((task, i) => i === index ? { text: task.text, done: !task.done } : task);
    }

    function remove(index) {
        items = items.filter((task, i) => i !== index);
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.config/etea/tasks.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: saved

            property var items: []
        }
    }
}
