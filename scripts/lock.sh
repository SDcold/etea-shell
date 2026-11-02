#!/usr/bin/env bash
# What hypridle runs to lock, on idle and before sleep: ETEA's lock screen, or hyprlock if
# Settings ask for it. If ETEA isn't answering, hyprlock locks anyway, never nothing.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
with="$(jq -r '.lockWith // "etea"' "$HOME/.config/etea/settings.json" 2>/dev/null || echo etea)"

if [[ "$with" != "hyprlock" ]] && qs ipc -p "$root" call lock lock 2>/dev/null; then
    exit 0
fi
pidof hyprlock || hyprlock
