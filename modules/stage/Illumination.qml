import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// The window you're working in lights up, the others step back into the shade.
// Hyprland does the drawing, we just hand it the values from Theme.
Scope {
    id: root

    // Hyprland wants rgba(rrggbbaa), Qt gives us something else
    function hyprColor(color, alpha) {
        const hex = value => Math.round(value * 255).toString(16).padStart(2, "0");
        return `rgba(${hex(color.r)}${hex(color.g)}${hex(color.b)}${hex(alpha)})`;
    }

    readonly property string settings: `
        hl.config({
            general = {
                border_size = ${Theme.traceWidth},
                gaps_in = ${Theme.windowGapInner},
                gaps_out = ${Theme.windowGapOuter},
                col = {
                    active_border = "${hyprColor(Theme.windowLit, Theme.traceLine)}",
                    inactive_border = "${hyprColor(Theme.windowLit, Theme.windowRestBorder)}"
                }
            },
            decoration = {
                dim_inactive = true,
                dim_strength = ${Theme.windowDim},
                shadow = {
                    enabled = true,
                    range = ${Theme.windowGlowSize},
                    render_power = ${Theme.windowGlowPower},
                    offset = { 0, 0 },
                    color = "${hyprColor(Theme.windowLit, Theme.windowGlow)}",
                    color_inactive = "${hyprColor(Theme.windowRestShadow, Theme.windowRestShadowAlpha)}"
                }
            }
        })
        -- The stock rules switch shadows off on tiled windows, and the glow is a shadow
        hl.window_rule({ match = { float = 0 }, no_shadow = false })
        for _, window in ipairs(hl.get_windows()) do
            hl.dispatch(hl.dsp.window.set_prop({ prop = "no_shadow", value = "false", window = "address:" .. window.address }))
        end
        -- A slow, even curve: the usual ones do most of the change in the first few frames
        hl.curve("eteaFocus", { type = "bezier", points = { { 0.42, 0 }, { 0.58, 1 } } })
        hl.animation({ leaf = "border", enabled = true, speed = ${Theme.windowFocusSpeed}, bezier = "eteaFocus" })
        hl.animation({ leaf = "fadeSwitch", enabled = true, speed = ${Theme.windowFocusSpeed}, bezier = "eteaFocus" })
        hl.animation({ leaf = "fadeDim", enabled = true, speed = ${Theme.windowFocusSpeed}, bezier = "eteaFocus" })
        hl.animation({ leaf = "fadeShadow", enabled = true, speed = ${Theme.windowFocusSpeed}, bezier = "eteaFocus" })
    `

    Process {
        id: apply

        command: ["/usr/bin/hyprctl", "eval", root.settings]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "ok")
                    console.warn("ETEA illumination:", text.trim());
            }
        }
    }

    // A Hyprland reload wipes everything we set, so put it right back
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded")
                apply.running = true;
        }
    }

    Component.onCompleted: apply.running = true
}
