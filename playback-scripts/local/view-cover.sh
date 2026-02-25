#!/usr/bin/env bash

# view-cover-data: muestra portada pequeña + metadata de la canción actual

MUSIC_DIR=""
CACHE="/tmp/mpd_cover.jpg"

BEIGE='\033[38;2;199;170;119m'
GREEN='\033[38;2;152;187;108m'
BROWN='\033[38;2;134;120;104m'
GRAY='\033[38;2;140;140;140m'
RESET='\033[0m'

show() {
    local file artist album date genre duration format bitrate title

    file=$(mpc current --format "$MUSIC_DIR/%file%")

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        clear
        echo -e "${BROWN}No hay nada reproduciendo.${RESET}"
        return
    fi

    artist=$(mpc current --format "%artist%")
    title=$(mpc current --format "%title%")
    album=$(mpc current --format "%album%")
    date=$(mpc current --format "%date%")
    genre=$(mpc current --format "%genre%")
    duration=$(mpc current --format "%time%")

    # extraer portada
    ffmpeg -y -i "$file" -an -vf scale=150:-1 -update 1 "$CACHE" >/dev/null 2>&1

    # bitrate y formato via ffprobe
    bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    if [[ "$bitrate" =~ ^[0-9]+$ ]]; then
        bitrate="$((bitrate / 1000)) kbps"
    else
        # fallback: leer bitrate del container
        bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
        if [[ "$bitrate" =~ ^[0-9]+$ ]]; then
            bitrate="$((bitrate / 1000)) kbps"
        else
            bitrate="N/A"
        fi
    fi
    format="${file##*.}"
    format="${format^^}"

    clear

    # portada inline pequeña
        if [ -s "$CACHE" ]; then
            cover=$(chafa --format symbols --size="16x8" "$CACHE" 2>/dev/null)
        else
            cover=""
        fi

        clear
        echo ""

        # metadata como líneas
        meta=(
            "${GREEN}${artist}${RESET} - ${BEIGE}${title}${RESET}"
            ""
            "${GRAY}album  ${RESET}${album}"
            "${GRAY}year   ${RESET}${date}"
            "${GRAY}genre  ${RESET}${genre}"
            "${GRAY}time   ${RESET}${duration}"
            "${GRAY}format ${RESET}${format} — ${bitrate}"
        )

        # imprimir portada y metadata lado a lado
        mapfile -t cover_lines <<< "$cover"
        for i in "${!cover_lines[@]}"; do
            printf "  %s   %b\n" "${cover_lines[$i]}" "${meta[$i]:-}"
        done

        # metadata restante si hay más líneas que la portada
        for ((i=${#cover_lines[@]}; i<${#meta[@]}; i++)); do
            printf "  %*s   %b\n" 16 "" "${meta[$i]}"
        done
}

trap 'clear; exit 0' INT TERM

show

while mpc idlewait player 2>/dev/null; do
    state=$(mpc status --format "%state%")
    if [ "$state" != "stop" ]; then
        show
    fi
done
