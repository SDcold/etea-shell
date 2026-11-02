# ETEA Shell

**Exit The Earth Atmosphere.** A desktop shell for [Hyprland](https://hyprland.org), built on
[Quickshell](https://quickshell.outfoxxed.me), for people who'd rather live on a planet than in a
grid of rectangles.

Your workspaces are pages standing around a small planet, and switching pages turns it. New
windows are born from a star, closing ones fold back into one. Press `Super + Tab` and you rise
into orbit to see every page at once; press it again and you're among the planets, each one a
theme you can land on. The bar, the menus, the notifications and the lock screen all speak the
same language: hand-drawn ink lines, little four-pointed stars, and a sky that's always a bit
alive.

It started as "I want my desktop to feel like my drawings" and kind of got out of hand. 🌍✨

> ⚠️ This is a personal project that grew up in public. It runs every day on my laptop, but it's
> young: expect rough edges, the odd bug, and things that change their mind between commits.
> Issues and ideas are very welcome.

## What's inside

- **A planet of pages.** Workspaces in groups (8 by default), turned like a globe, with an
  orbit view to drag windows between them and a system view to pick your world.
- **Worlds, not themes.** Each planet brings its own sky, ground and colours. You can even make
  one from any picture.
- **A bar you arrange.** Islands, a band or bare sky, any module on any end, drag and drop in
  Settings. Pages as constellations or plain numbers.
- **Menus and panels** for sound (per-app volume, output and microphone), Wi-Fi and VPN,
  Bluetooth (with pairing), power, calendar and moon, music, keyboard languages, and a control
  centre with quick tiles and a notification journal grouped by app.
- **Desktop widgets** written straight on the sky or set in porthole cards: clock, system,
  music, weather, calendar, tasks, a photo frame, and karaoke lyrics that light up as the song
  goes. `Super + drag` moves them, `Super + wheel` resizes them, right click for options.
- **A launcher shaped like a sky map.** Apps by constellation, your favourites brightest. It also
  does maths (`sqrt(2)*pi`), commands (`>`), emoji (`:heart`, `:cœur`) and web searches (`?`).
- **Everyday tools:** clipboard history with image previews, region / window / full-screen
  capture, screen recording with or without sound, colour picker, night light, stay-awake, a
  polkit agent, battery alerts, OSDs.
- **A lock screen with a story.** A woman reaches for the stars as you type, her hand hiding each
  new one. It locks on idle and before sleep, and your fingerprint works too.
- **Shortcut cheatsheet** on `Super + /`, built from your own Hyprland binds.
- **French and English**, and adding a language is one JSON file.

## Requirements

- **Hyprland 0.56 or newer, with the Lua config.** ETEA talks to Hyprland through `hyprctl eval`.
- **Quickshell 0.2.1 or newer**, with its Pipewire, Mpris, UPower, Bluetooth, Networking, Pam,
  Polkit and Notifications services (the AUR `quickshell-git` package has them all).
- PipeWire with `pactl`, NetworkManager, BlueZ, UPower and power-profiles-daemon.
- Command-line helpers: `cava`, `cliphist`, `wl-clipboard`, `grim`, `wf-recorder`, `hyprpicker`,
  `hyprsunset`, `brightnessctl`, `jq`, `curl`, `libnotify`, `xdg-user-dirs`, and `kdialog` or
  `zenity` for file pickers.
- Optional: `hypridle` and `hyprlock` (idle locking, and a fallback lock), `fprintd` for
  fingerprints.

The Poppins font and the icons ship with the shell, nothing to install there.

On Arch, something like:

```sh
yay -S quickshell-git cava cliphist wl-clipboard grim wf-recorder hyprpicker hyprsunset \
    brightnessctl jq curl libnotify xdg-user-dirs zenity networkmanager bluez upower \
    power-profiles-daemon pipewire-pulse libpulse hypridle hyprlock fprintd
```

## Installation

1. **Get it**, anywhere you like:

   ```sh
   git clone https://github.com/SDcold/etea-shell.git ~/.config/etea-shell
   ```

2. **Start it with Hyprland.** In your Lua config:

   ```lua
   hl.on("hyprland.start", function()
       hl.exec_cmd("qs -p ~/.config/etea-shell")
       hl.exec_cmd("wl-paste --watch cliphist store") -- the clipboard history needs this
   end)
   ```

   If another shell or notification daemon (mako, dunst, another Quickshell config…) is
   running, stop it first: only one program can show notifications, and two bars would fight
   over the top of your screen.

3. **Lock on idle with ETEA** (optional). In `~/.config/hypr/hypridle.conf`:

   ```ini
   general {
       lock_cmd = ~/.config/etea-shell/scripts/lock.sh
       before_sleep_cmd = loginctl lock-session
   }
   ```

   The script locks with ETEA, or with hyprlock if you picked it in Settings, and falls back to
   hyprlock if ETEA isn't answering. Never to nothing.

4. **Log out and back in**, or just run `qs -p ~/.config/etea-shell` to try it right away.

ETEA takes over a handful of shortcuts while it runs (pages, launcher, lock…). Nothing is
written to your Hyprland config: reload Hyprland and they're yours again, until the shell takes
them back a second later.

## First steps

| Keys | What happens |
|---|---|
| `Super` | The launcher |
| `Super + 1 … 0` | Go to a page |
| `Super + wheel`, `Ctrl + Super + ← →`, 4-finger swipe | Turn the planet |
| `Super + Tab` | Orbit, then the planets |
| `Super + A` / `Super + N` | Left panel (calendar, tasks, focus timer) / control centre |
| `Super + V` | Clipboard |
| `Super + Shift + S` | Capture (Tab switches to video) |
| `Super + L` | Lock |
| `Super + ,` | Settings |
| `Super + /` | Every shortcut, including yours |

Right click the empty sky to add widgets. Everything else lives in Settings.

## Configuration

Settings write to `~/.config/etea/settings.json`, and editing that file by hand works too: the
shell picks changes up live. A few things can be driven from scripts over IPC:

```sh
qs ipc -p ~/.config/etea-shell call desk state          # where the widgets are
qs ipc -p ~/.config/etea-shell call wake toggle         # stay awake on/off
qs ipc -p ~/.config/etea-shell call recorder stop       # stop a recording
qs ipc -p ~/.config/etea-shell call lock preview        # try the lock screen safely
```

`qs ipc -p ~/.config/etea-shell show` lists everything that's available.

Weather comes from [Open-Meteo](https://open-meteo.com) (with a rough location from
[ipinfo.io](https://ipinfo.io) unless you type a city), lyrics from [LRCLIB](https://lrclib.net).
Both are only asked while their widget is on your desktop.

## Hacking on it

The whole shell is QML; hot reload is on, so saving a file updates the desktop under your eyes.

```sh
scripts/dev.sh start   # stop your usual shell and run ETEA from this folder
scripts/dev.sh logs    # follow what it says
scripts/dev.sh stop    # put your usual shell back
```

`dev.sh` was written for my own setup (it swaps out an end4 Quickshell config named `end4-pC`),
so read it before running it on yours. The visual rules live in `DESIGN_LANGUAGE.md`, the
lock screen art and how it's traced in `assets/lock/README.md`.

Want ETEA in your language? Copy `i18n/en.json`, translate each line, add it to
`Lang.languages` in `config/Lang.qml`, and send a PR. 💌

## Credits

- [Quickshell](https://quickshell.outfoxxed.me) by outfoxxed, which makes all of this possible.
- Icons: [Material Symbols](https://fonts.google.com/icons) (Apache 2.0).
- Font: [Poppins](https://fonts.google.com/specimen/Poppins) (SIL Open Font License).
- Emoji names: Unicode and CLDR data (Unicode License v3).
- Lyrics: [LRCLIB](https://lrclib.net). Weather: [Open-Meteo](https://open-meteo.com).
- Ideas borrowed with love from [end4's dots](https://github.com/end-4/dots-hyprland) and
  [Caelestia](https://github.com/caelestia-dots/shell).

The project doesn't have a license yet. Until it does, please ask before reusing the code or the
artwork.
