#!/usr/bin/env bash
# Swaps between your usual shell and ETEA while you work on it.
#   scripts/dev.sh start   stops end4 and runs ETEA, with live reload
#   scripts/dev.sh stop    stops ETEA and brings end4 back
#   scripts/dev.sh logs    follows what ETEA has to say
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_NAME="end4-pC"
IDLE="$HOME/.config/hypr/hypridle.conf"
BACKUP="$IDLE.etea-backup"

# Hypridle only reads its config when it starts
restart_idle() {
    pkill -x hypridle || true
    sleep 0.3
    setsid -f hypridle >/dev/null 2>&1
}

# Finds ETEA by what it's running rather than by name: after a crash, Quickshell
# restarts itself as plain "quickshell" and a name search would walk right past it
etea_pids() {
    qs list --all --json 2>/dev/null | ROOT="$ROOT" python3 -c '
import json, os, sys
root = os.environ["ROOT"] + "/shell.qml"
try:
    instances = json.load(sys.stdin)
except ValueError:
    instances = []  # qs prints plain text when nothing is running
for instance in instances:
    if instance["config_path"] == root:
        print(instance["pid"])
'
}

# Two bars would each reserve their own space, so make sure every instance is gone
stop_etea() {
    local pids
    pids="$(etea_pids)"
    [[ -z "$pids" ]] && return 0
    kill $pids 2>/dev/null || true
    for _ in {1..20}; do
        [[ -z "$(etea_pids)" ]] && return 0
        sleep 0.1
    done
    kill -9 $(etea_pids) 2>/dev/null || true
}

# ETEA takes over the page shortcuts for this session and turns off Hyprland's
# own page animation. Nothing is written to your config, a reload undoes it all.
take_pages() {
    /usr/bin/hyprctl eval '
        hl.animation({ leaf = "workspaces", enabled = false })
        local keys = { 10, 11, 12, 13, 14, 15 }
        local pad = { 87, 88, 89, 83, 84, 85 }
        for i = 1, 6 do
            hl.unbind("SUPER + " .. i)
            hl.unbind("SUPER + code:" .. keys[i])
            hl.unbind("SUPER + code:" .. pad[i])
            hl.bind("SUPER + code:" .. keys[i], hl.dsp.global("etea:page" .. i))
            hl.bind("SUPER + code:" .. pad[i], hl.dsp.global("etea:page" .. i))
        end
        hl.unbind("CTRL + SUPER + Right")
        hl.unbind("CTRL + SUPER + Left")
        hl.bind("CTRL + SUPER + Right", hl.dsp.global("etea:pageNext"))
        hl.bind("CTRL + SUPER + Left", hl.dsp.global("etea:pagePrevious"))
    ' | grep -v '^ok$' || true

    # The four finger swipe would switch pages without us, so it goes through ETEA too.
    # Hyprland complains when removing a gesture that isn't there, which is fine here.
    for direction in horizontal left right; do
        /usr/bin/hyprctl eval "hl.gesture({ fingers = 4, direction = \"$direction\", action = \"unset\" })" >/dev/null 2>&1 || true
    done
    /usr/bin/hyprctl eval '
        hl.gesture({ fingers = 4, direction = "left", action = function()
            hl.dispatch(hl.dsp.global("etea:pageNext"))
        end })
        hl.gesture({ fingers = 4, direction = "right", action = function()
            hl.dispatch(hl.dsp.global("etea:pagePrevious"))
        end })
    ' | grep -v '^ok$' || true
}

case "${1:-}" in
start)
    # Hypridle sees qs running and assumes the shell handles locking, so point it at hyprlock
    if [[ ! -f "$BACKUP" ]]; then
        cp "$IDLE" "$BACKUP"
        sed -i -e 's|^\$lock_cmd = hyprctl dispatch|# &|' -e 's|^# \$lock_cmd = pidof hyprlock|$lock_cmd = pidof hyprlock|' "$IDLE"
        restart_idle
    fi
    qs kill -c "$SHELL_NAME" 2>/dev/null || true
    stop_etea
    qs -p "$ROOT" -d
    take_pages
    ;;
stop)
    stop_etea
    if [[ -f "$BACKUP" ]]; then
        mv "$BACKUP" "$IDLE"
        restart_idle
    fi
    /usr/bin/hyprctl reload config-only >/dev/null
    qs -c "$SHELL_NAME" -d
    ;;
logs)
    qs log -p "$ROOT" -f
    ;;
*)
    echo "Usage : $0 {start|stop|logs}" >&2
    exit 1
    ;;
esac
