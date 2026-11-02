import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.services

// The two side panels: the logbook on the left, the control centre on the right.
Scope {
    SidePanel {
        side: "left"
        open: Menus.leftOpen
        tint: Theme.windowLit
        content: Logbook {}
        onCloseRequested: Menus.closePanel("left")
    }

    SidePanel {
        side: "right"
        open: Menus.rightOpen
        tint: Theme.windowLit
        content: ControlCentre {}
        onCloseRequested: Menus.closePanel("right")
    }

    GlobalShortcut {
        appid: "etea"
        name: "panelLeft"
        onPressed: Menus.togglePanel("left")
    }

    GlobalShortcut {
        appid: "etea"
        name: "panelRight"
        onPressed: Menus.togglePanel("right")
    }

    IpcHandler {
        target: "panels"

        function left(): void {
            Menus.togglePanel("left");
        }

        function right(): void {
            Menus.togglePanel("right");
        }
    }
}
