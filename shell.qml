import Quickshell
import qs.modules.background
import qs.modules.bar
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.stage

// Where it all starts: the world in the back, the stage over the windows, the bar on top.
ShellRoot {
    Background {}
    Stage {}
    PageShortcuts {}
    Illumination {}
    Bar {}
    Launcher {}
    Notifications {}
}
