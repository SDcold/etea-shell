#!/usr/bin/env bash
# Sets ETEA up, asking before each step.
#   ./install.sh              install, or update the autostart after moving the folder
#   ./install.sh --dry-run    show everything it would do, change nothing
#   ./install.sh --uninstall  take ETEA out of the Hyprland config
set -uo pipefail

shell_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
hypr_config="$hypr_dir/hyprland.lua"
idle_config="$hypr_dir/hypridle.conf"
mark_start="-- >>> ETEA Shell >>>"
mark_end="-- <<< ETEA Shell <<<"

dry=0
mode=install
for arg in "$@"; do
    case "$arg" in
        --dry-run) dry=1 ;;
        --uninstall) mode=uninstall ;;
        -h | --help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
    esac
done

# A little colour, when the terminal has some
if [[ -t 1 ]] && command -v tput >/dev/null && (($(tput colors 2>/dev/null || echo 0) >= 8)); then
    ink=$'\e[0m' dim=$'\e[2m' bold=$'\e[1m' glow=$'\e[38;5;183m' sea=$'\e[38;5;116m' warm=$'\e[38;5;216m' bad=$'\e[38;5;210m'
else
    ink="" dim="" bold="" glow="" sea="" warm="" bad=""
fi

say() { printf '%s\n' "$*"; }
step() { printf '\n%s✦ %s%s\n' "$glow$bold" "$*" "$ink"; }
good() { printf '  %s✓%s %s\n' "$sea" "$ink" "$*"; }
note() { printf '  %s·%s %s\n' "$dim" "$ink" "$*"; }
warn() { printf '  %s!%s %s\n' "$warm" "$ink" "$*"; }
fail() { printf '  %s✗%s %s\n' "$bad" "$ink" "$*"; }

# yes/no, with the answer Enter gives in capitals
ask() {
    local question="$1" default="${2:-y}" hint answer
    [[ "$default" == y ]] && hint="Y/n" || hint="y/N"
    printf '  %s?%s %s %s[%s]%s ' "$glow" "$ink" "$question" "$dim" "$hint" "$ink"
    read -r answer || answer=""
    answer="${answer:-$default}"
    [[ "${answer,,}" == y* || "${answer,,}" == o* ]]
}

# Every change goes through here, so --dry-run can show it instead
run() {
    if ((dry)); then
        printf '  %s(dry run)%s %s\n' "$dim" "$ink" "$*"
        return 0
    fi
    "$@"
}

# Writes stdin to a file, or shows what would be written
write_file() {
    local file="$1" content
    content="$(cat)"
    if ((dry)); then
        printf '  %s(dry run) would write %s:%s\n' "$dim" "$file" "$ink"
        printf '%s\n' "$content" | sed "s/^/      $dim/;s/$/$ink/"
        return 0
    fi
    printf '%s\n' "$content" >"$file"
}

backup() {
    local file="$1" copy
    [[ -f "$file" ]] || return 0
    copy="$file.etea-backup-$(date +%Y%m%d-%H%M%S)"
    # Never over an earlier backup, even one taken the same second
    local n=1 base="$copy"
    while [[ -e "$copy" ]]; do
        copy="$base-$((++n))"
    done
    run cp -p "$file" "$copy" && note "Backed up $(basename "$file") to $(basename "$copy")"
}

# The config without our block, if it has one, and without the blank lines it leaves at the end
without_block() {
    awk -v start="$mark_start" -v end="$mark_end" '
        $0 == start { skipping = 1; next }
        $0 == end { skipping = 0; next }
        skipping { next }
        /^[[:space:]]*$/ { blanks = blanks $0 "\n"; next }
        { printf "%s%s\n", blanks, $0; blanks = "" }' "$1"
}

has_block() {
    [[ -f "$hypr_config" ]] && grep -qxF -e "$mark_start" "$hypr_config"
}

banner() {
    say ""
    say "  $glow      ✦$ink"
    say "  $glow   ·  │  ·$ink        ${bold}ETEA Shell$ink"
    say "  $glow  ✦───●───✦$ink     ${dim}Exit The Earth Atmosphere$ink"
    say "  $glow   ·  │  ·$ink"
    say "  $glow      ✦$ink        ${dim}from $shell_dir$ink"
    ((dry)) && say "" && warn "Dry run: nothing will be changed."
}

uninstall() {
    banner
    step "Taking ETEA out of Hyprland"
    if ! has_block; then
        good "Your Hyprland config doesn't start ETEA, nothing to remove."
    elif ask "Remove the ETEA block from $(basename "$hypr_config")?" y; then
        backup "$hypr_config"
        without_block "$hypr_config" | write_file "$hypr_config"
        good "Removed. ETEA won't start with Hyprland any more."
    fi
    if pgrep -f "qs -p $shell_dir" >/dev/null && ask "Stop the running ETEA now?" y; then
        run pkill -f "qs -p $shell_dir"
        good "Stopped. Reload Hyprland to get your own shortcuts back."
    fi
    if [[ -f "$kitty_conf" ]] && grep -qxF -e "$kitty_line" "$kitty_conf" && ask "Stop kitty from wearing the world's colours?" y; then
        backup "$kitty_conf"
        grep -vxF -e "$kitty_line" -e "# The world's colours, written by ETEA" "$kitty_conf" | write_file "$kitty_conf"
        good "kitty keeps its own colours again."
    fi
    note "Your settings stay in ~/.config/etea; delete that folder to forget them too."
    say ""
}

# Hyprland 0.56 or newer, and a config in Lua
check_hyprland() {
    step "Hyprland"
    local version=""
    if command -v hyprctl >/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        version="$(hyprctl version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    elif command -v Hyprland >/dev/null; then
        version="$(Hyprland --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    fi
    version="${version#v}"
    if [[ -z "$version" ]]; then
        fail "Hyprland isn't installed. ETEA is a shell for Hyprland: install it first."
        return 1
    fi
    local major minor
    IFS=. read -r major minor _ <<<"$version"
    if ((major == 0 && minor < 56)); then
        fail "Hyprland $version found, ETEA needs 0.56 or newer (it talks to Hyprland in Lua)."
        return 1
    fi
    good "Hyprland $version"
    if [[ -f "$hypr_config" ]]; then
        good "Lua config: $hypr_config"
    else
        warn "No $hypr_config. ETEA needs Hyprland's Lua config to start with it;"
        warn "you can still go on and start ETEA by hand."
    fi
}

# command → package, for the families we know
packages_for() {
    local family="$1"
    case "$family" in
        arch)
            cat <<'EOF'
qs quickshell-git
cava cava
cliphist cliphist
wl-copy wl-clipboard
grim grim
slurp slurp
wf-recorder wf-recorder
hyprpicker hyprpicker
hyprsunset hyprsunset
brightnessctl brightnessctl
jq jq
curl curl
notify-send libnotify
xdg-user-dir xdg-user-dirs
zenity zenity
nmcli networkmanager
bluetoothctl bluez-utils
upower upower
powerprofilesctl power-profiles-daemon
pactl libpulse
EOF
            ;;
        fedora)
            cat <<'EOF'
qs quickshell
cava cava
cliphist cliphist
wl-copy wl-clipboard
grim grim
slurp slurp
wf-recorder wf-recorder
hyprpicker hyprpicker
hyprsunset hyprsunset
brightnessctl brightnessctl
jq jq
curl curl
notify-send libnotify
xdg-user-dir xdg-user-dirs
zenity zenity
nmcli NetworkManager
bluetoothctl bluez
upower upower
powerprofilesctl power-profiles-daemon
pactl pulseaudio-utils
EOF
            ;;
    esac
}

family=""
detect_family() {
    if command -v pacman >/dev/null; then
        family=arch
    elif command -v dnf >/dev/null; then
        family=fedora
    fi
}

install_packages() {
    step "What ETEA needs"
    detect_family
    local wanted=() missing=() line command package
    if [[ -z "$family" ]]; then
        while read -r command package; do
            command -v "$command" >/dev/null || missing+=("$command")
        done < <(packages_for arch)
        if ((${#missing[@]} == 0)); then
            good "Everything is there."
        else
            warn "Your distribution isn't one this script knows. Please install whatever provides:"
            warn "${missing[*]}"
        fi
        return 0
    fi
    while read -r command package; do
        # Either file picker will do
        [[ "$command" == zenity ]] && command -v kdialog >/dev/null && continue
        if command -v "$command" >/dev/null; then
            continue
        fi
        missing+=("$command")
        wanted+=("$package")
    done < <(packages_for "$family")

    if ((${#wanted[@]} == 0)); then
        good "Everything is there."
        return 0
    fi
    warn "Missing: ${missing[*]}"
    if [[ "$family" == fedora ]]; then
        warn "Fedora isn't fully tested yet. Hyprland 0.56 and Quickshell may need a COPR (see the README)."
    fi

    local installer=()
    if [[ "$family" == arch ]]; then
        if command -v paru >/dev/null; then
            installer=(paru -S --needed)
        elif command -v yay >/dev/null; then
            installer=(yay -S --needed)
        elif [[ " ${wanted[*]} " == *" quickshell-git "* ]]; then
            warn "Quickshell comes from the AUR, and no AUR helper (paru or yay) was found."
            warn "Install quickshell-git yourself, then run this again."
            local repo=()
            for package in "${wanted[@]}"; do
                [[ "$package" != quickshell-git ]] && repo+=("$package")
            done
            wanted=("${repo[@]}")
            ((${#wanted[@]})) || return 0
            installer=(sudo pacman -S --needed)
        else
            installer=(sudo pacman -S --needed)
        fi
    else
        installer=(sudo dnf install)
    fi

    say ""
    note "${installer[*]} ${wanted[*]}"
    if ask "Install them now?" y; then
        if ! run "${installer[@]}" "${wanted[@]}"; then
            fail "The install didn't finish. You can run the line above yourself and come back."
        fi
    else
        note "Skipped. ETEA will run, but whatever uses those will be missing."
    fi
}

# Bars and notification daemons that would fight ETEA for the screen
check_rivals() {
    step "Other shells"
    local found=() name
    for name in waybar mako dunst swaync ags hyprpanel eww nwg-panel fnott; do
        pgrep -x "$name" >/dev/null && found+=("$name")
    done
    while read -r line; do
        [[ "$line" == *"$shell_dir"* ]] && continue
        found+=("another Quickshell config")
        break
    done < <(pgrep -a -f '(^|/)(qs|quickshell)( |$)' 2>/dev/null)
    if ((${#found[@]} == 0)); then
        good "Nothing else is drawing a bar or showing notifications."
        return 0
    fi
    warn "Running now: ${found[*]}"
    warn "Only one program can show notifications, and two bars fight over the top of the screen."
    warn "Take them out of your Hyprland autostart; ETEA replaces all of them."
}

# Our block: start ETEA, and keep the clipboard history fed
autostart() {
    step "Start with Hyprland"
    if [[ ! -f "$hypr_config" ]]; then
        note "No Lua config to write to. Start ETEA by hand with:"
        note "qs -p \"$shell_dir\""
        [[ "${start_idle:-0}" == 1 ]] && note "and start hypridle alongside it."
        return 0
    fi
    if has_block; then
        note "ETEA is already in your config; it will be rewritten for this folder."
    fi
    local clipboard=1 idle=0
    # Fed already, by the config, a user service or a watcher started some other way
    if { without_block "$hypr_config"; grep -rhs --include='*.lua' --exclude="$(basename "$hypr_config")" "" "$hypr_dir"; } | grep -q "cliphist store" \
        || systemctl --user is-active --quiet cliphist 2>/dev/null; then
        clipboard=0
        note "Your clipboard history is already being fed."
    fi
    ask "Add ETEA to $(basename "$hypr_config") so it starts with Hyprland?" y || return 0
    if [[ "${start_idle:-0}" == 1 ]]; then
        idle=1
    fi

    local block
    block="$mark_start
-- Added by ETEA's install.sh. Run it with --uninstall to take this out.
hl.on(\"hyprland.start\", function()
    hl.exec_cmd([[qs -p \"$shell_dir\"]])"
    ((clipboard)) && block+="
    hl.exec_cmd(\"wl-paste --watch cliphist store\")"
    ((idle)) && block+="
    hl.exec_cmd(\"hypridle\")"
    block+="
end)
$mark_end"

    backup "$hypr_config"
    { without_block "$hypr_config"; printf '\n%s\n' "$block"; } | write_file "$hypr_config"
    good "ETEA will start with Hyprland."
}

# Lock on idle and before sleep, through ETEA's lock script
idle_lock() {
    step "Lock on idle"
    if ! command -v hypridle >/dev/null; then
        note "hypridle isn't installed, so ETEA only locks when you ask (Super + L)."
        note "Install hypridle and run this again to lock on idle and before sleep."
        return 0
    fi
    if [[ -f "$idle_config" ]]; then
        if grep -q "$shell_dir/scripts/lock.sh" "$idle_config"; then
            good "hypridle already locks with ETEA."
        else
            note "You already have a hypridle.conf, so it's left alone. To lock with ETEA, set:"
            note "lock_cmd = \"$shell_dir/scripts/lock.sh\""
            note "before_sleep_cmd = loginctl lock-session"
        fi
        return 0
    fi
    ask "Lock after 5 minutes away and before sleep, with ETEA's lock screen?" y || return 0
    write_file "$idle_config" <<EOF
# Written by ETEA's install.sh
general {
    lock_cmd = "$shell_dir/scripts/lock.sh"
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 360
    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
    on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
}
EOF
    # hypridle has to run too: it joins our block when that gets written
    pgrep -x hypridle >/dev/null || start_idle=1
    good "Locks after 5 minutes, screen off after 6."
}

# kitty in the world's colours: one include line at the end of kitty.conf
kitty_conf="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
kitty_line="include ~/.config/etea/kitty-colors.conf"

terminal_colours() {
    command -v kitty >/dev/null || return 0
    step "kitty"
    if [[ -f "$kitty_conf" ]] && grep -qxF -e "$kitty_line" "$kitty_conf"; then
        good "kitty already wears the world's colours."
        return 0
    fi
    ask "Let kitty wear the world's colours? It adds one line to kitty.conf." y || return 0
    run mkdir -p "$(dirname "$kitty_conf")"
    backup "$kitty_conf"
    { [[ -f "$kitty_conf" ]] && cat "$kitty_conf"; printf '\n# The world'"'"'s colours, written by ETEA\n%s\n' "$kitty_line"; } | write_file "$kitty_conf"
    good "kitty follows the world. Turn it off in Settings › Windows."
}

fingerprint() {
    command -v fprintd-list >/dev/null || return 0
    step "Fingerprint"
    if fprintd-list "$USER" 2>/dev/null | grep -qE '^ +- #'; then
        good "A finger is already enrolled. Turn it on in Settings › Lock screen."
        return 0
    fi
    if ! fprintd-list "$USER" 2>/dev/null | grep -qE "found [1-9]"; then
        note "No fingerprint reader found."
        return 0
    fi
    if ask "Enrol a finger now, to unlock with it?" n; then
        run fprintd-enroll "$USER" && good "Enrolled. Turn it on in Settings › Lock screen."
    fi
}

start_now() {
    step "Lift off"
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        note "Not inside Hyprland right now. ETEA will start next time you log in."
        return 0
    fi
    if pgrep -f "qs -p $shell_dir" >/dev/null; then
        good "ETEA is already running."
        return 0
    fi
    if ask "Start ETEA now?" y; then
        if ((dry)); then
            run setsid -f qs -p "$shell_dir"
        else
            setsid -f qs -p "$shell_dir" >/dev/null 2>&1
        fi
        good "Started."
    fi
}

goodbye() {
    say ""
    say "  ${bold}You're in orbit.$ink A few keys to start with:"
    say "  ${sea}Super$ink           the launcher"
    say "  ${sea}Super + Tab$ink     orbit, then the planets"
    say "  ${sea}Super + ,$ink       settings"
    say "  ${sea}Super + /$ink       every shortcut"
    say "  ${dim}Right click the empty sky to add widgets.$ink"
    say ""
}

if [[ "$mode" == uninstall ]]; then
    uninstall
    exit 0
fi

banner
check_hyprland || exit 1
install_packages
check_rivals
start_idle=0
idle_lock
terminal_colours
autostart
fingerprint
start_now
goodbye
