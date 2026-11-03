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
    local answer
    answer="$(curl -s --max-time 15 -A "ETEA Shell (https://github.com/SDcold/etea-shell)" -w '\n%{http_code}' -G "https://lrclib.net/api/$1" "${@:2}")"
    code="${answer##*$'\n'}"
    body="${answer%$'\n'*}"
}

# Of what came back, the synced lyrics whose length is closest to the song's
pick() {
    jq -r --argjson length "$duration" '[.. | objects | select(.syncedLyrics? != null) | {gap: ((.duration - $length) | fabs), lyrics: .syncedLyrics} | select($length == 0 or .gap < 8)] | sort_by(.gap) | .[0].lyrics // empty' <<<"$body"
}

busy=0
look() {
    ask "$@"
    if [[ "$code" == 200 ]]; then
        lyrics="$(pick)"
    elif [[ "$code" != 404 && "$code" != 400 ]]; then
        busy=1
    fi
    [[ -n "$lyrics" ]]
}

# Spotify likes to dress titles up: "Song - Remastered 2011", "Song (feat. Someone)",
# "Song - From \"The Film\"". A video puts the artist in the title too. LRCLIB usually
# knows the plain one, under the first artist only.
plain="${title#"$artist - "}"
plain="$(sed -E 's/ - .*$//; s/ *[([][^])]*[])]//g; s/ +$//' <<<"$plain")"
[[ -n "$plain" ]] || plain="$title"
lead="$(sed -E 's/( feat\.? | ft\.? |, | & | x | X ).*$//I' <<<"$artist")"

lyrics=""
look get --data-urlencode "artist_name=$artist" --data-urlencode "track_name=$title" --data-urlencode "album_name=$album" --data-urlencode "duration=$duration" \
    || look search --data-urlencode "artist_name=$artist" --data-urlencode "track_name=$title" \
    || { [[ "$lead $plain" != "$artist $title" ]] && look search --data-urlencode "artist_name=$lead" --data-urlencode "track_name=$plain"; } \
    || look search --data-urlencode "q=$lead $plain"

# Nothing found because LRCLIB never answered isn't the same as nothing to find
if [[ -z "$lyrics" && "$busy" == 1 ]]; then
    exit 2
fi

printf '%s' "$lyrics" >"$file"
if [[ -n "$lyrics" ]]; then
    printf '%s\n' "$lyrics"
    exit 0
fi
exit 1
