#!/usr/bin/env bash
# Synced lyrics for a song, from LRCLIB (lrclib.net, free, no account). Kept in a cache once
# found, and a song without any is remembered for a week before asking again.
#   lyrics.sh "artist" "title" "album" duration_in_seconds
# Prints the LRC text. Exits 0 when found, 1 when this song has none, 2 when LRCLIB
# couldn't be asked (busy or offline), so the caller knows to try again later.
artist="$1" title="$2" album="$3" duration="${4:-0}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/etea/lyrics"
mkdir -p "$cache"
file="$cache/$(printf '%s - %s' "$artist" "$title" | tr '/' '_').lrc"

# A video or a stream without an artist isn't a song LRCLIB could know
[[ -n "$artist" && -n "$title" ]] || exit 1

if [[ -s "$file" ]]; then
    cat "$file"
    exit 0
fi
if [[ -f "$file" && -n "$(find "$file" -mtime -7)" ]]; then
    exit 1
fi

ask() {
    curl -s --max-time 15 -A "ETEA Shell (https://github.com/SDcold/etea-shell)" -w '\n%{http_code}' -G "https://lrclib.net/api/$1" "${@:2}"
}

answer="$(ask get --data-urlencode "artist_name=$artist" --data-urlencode "track_name=$title" --data-urlencode "album_name=$album" --data-urlencode "duration=$duration")"
code="${answer##*$'\n'}"
body="${answer%$'\n'*}"
if [[ "$code" == 200 ]]; then
    lyrics="$(jq -r '.syncedLyrics // empty' <<<"$body")"
elif [[ "$code" == 404 ]]; then
    # Not under that exact name: search, and keep the one that lasts as long as the song
    answer="$(ask search --data-urlencode "artist_name=$artist" --data-urlencode "track_name=$title")"
    code="${answer##*$'\n'}"
    body="${answer%$'\n'*}"
    [[ "$code" == 200 ]] || { [[ "$code" == 400 ]] && exit 1; exit 2; }
    lyrics="$(jq -r --argjson length "$duration" '[.[] | select(.syncedLyrics != null) | select($length == 0 or ((.duration - $length) | fabs) < 4)][0].syncedLyrics // empty' <<<"$body")"
elif [[ "$code" == 400 ]]; then
    exit 1
else
    exit 2
fi

printf '%s' "$lyrics" >"$file"
if [[ -n "$lyrics" ]]; then
    printf '%s\n' "$lyrics"
    exit 0
fi
exit 1
