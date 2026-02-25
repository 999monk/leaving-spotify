#!/usr/bin/env bash

MUSIC_DIR=""
CACHE="/tmp/mpd_cover.jpg"

# colors
BEIGE='\033[38;2;199;170;119m'
GREEN='\033[38;2;152;187;108m'
BROWN='\033[38;2;134;120;104m'
GRAY='\033[38;2;140;140;140m'
RESET='\033[0m'

usage() {
    echo ""
    echo -e "Keys: ${BROWN}space=pause | p/n=next | -+=vol | q=quit${RESET}"
    echo ""
    echo -e "${BEIGE}Uso:${RESET}"
    echo -e "  $0 --artist <nombre>"
    echo -e "  $0 --album <nombre>"
    echo -e "  $0 --song <nombre>"
    echo -e "  $0 --genre <nombre>"
    echo -e "  $0 --shuffle"
    echo ""
    echo -e "${BEIGE}Flags:${RESET}"
    echo -e "  --minimal / -m    muestra solo artista - titulo [album]"
    echo ""
    echo -e "${BEIGE}Ejemplos:${RESET}"
    echo -e "  $0 --artist \"steely dan\""
    echo -e "  $0 --album \"royal scam\" --minimal"
    echo -e "  $0 --shuffle"
    echo ""
    echo -e "                           ${BROWN}script by monk999${RESET}"
    exit 1
}

now_playing_minimal() {
    local artist title album
    artist=$(mpc current --format "%artist%")
    title=$(mpc current --format "%title%")
    album=$(mpc current --format "%album%")
    echo -e "\033[97m♫\033[0m ${GREEN}${artist}${RESET} \033[97m-\033[0m ${BEIGE}${title}${RESET} ${BROWN}[${album}]${RESET}"
}

now_playing_full() {
    local file artist title album date genre duration format bitrate

    file=$(mpc current --format "$MUSIC_DIR/%file%")

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        now_playing_minimal
        return
    fi

    artist=$(mpc current --format "%artist%")
    title=$(mpc current --format "%title%")
    album=$(mpc current --format "%album%")
    date=$(mpc current --format "%date%")
    genre=$(mpc current --format "%genre%")
    duration=$(mpc current --format "%time%")

    ffmpeg -y -i "$file" -an -vf scale=150:-1 -update 1 "$CACHE" >/dev/null 2>&1

    bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    if [[ "$bitrate" =~ ^[0-9]+$ ]]; then
        bitrate="$((bitrate / 1000)) kbps"
    else
        bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
        if [[ "$bitrate" =~ ^[0-9]+$ ]]; then
            bitrate="$((bitrate / 1000)) kbps"
        else
            bitrate="N/A"
        fi
    fi
    format="${file##*.}"
    format="${format^^}"

    if [ -s "$CACHE" ]; then
        cover=$(chafa --format symbols --size="16x8" "$CACHE" 2>/dev/null)
    else
        cover=""
    fi

    echo ""

    meta=(
        "${GREEN}${artist}${RESET} - ${BEIGE}${title}${RESET}"
        ""
        "${GRAY}album  ${RESET}${album}"
        "${GRAY}year   ${RESET}${date}"
        "${GRAY}genre  ${RESET}${genre}"
        "${GRAY}time   ${RESET}${duration}"
        "${GRAY}format ${RESET}${format} — ${bitrate}"
    )

    mapfile -t cover_lines <<< "$cover"
    for i in "${!cover_lines[@]}"; do
        printf "  %s   %b\n" "${cover_lines[$i]}" "${meta[$i]:-}"
    done

    for ((i=${#cover_lines[@]}; i<${#meta[@]}; i++)); do
        printf "  %*s   %b\n" 16 "" "${meta[$i]}"
    done

    echo ""
}

now_playing() {
    if [ "$MINIMAL" -eq 1 ]; then
        now_playing_minimal
    else
        now_playing_full
    fi
}

OLD_STTY=""

cleanup() {
    tput cnorm
    [ -n "$OLD_STTY" ] && stty "$OLD_STTY"
    mpc stop >/dev/null 2>&1
    echo ""
    echo -e "${BROWN}WP GL <3${RESET}"
    exit 0
}

interactive_loop() {
    OLD_STTY=$(stty -g)
    trap cleanup INT TERM

    stty -echo -icanon min 1 time 0
    tput civis

    now_playing

    LAST_TRACK=$(mpc current)
    SUPPRESS=0

    while true; do
        if read -r -s -t 0.2 -n 1 key; then
            if [ "$key" = "" ] || [ "$key" = " " ]; then
                mpc toggle >/dev/null 2>&1
                SUPPRESS=1
                state=$(mpc status --format "%state%")
                if [ "$state" = "pause" ]; then
                    echo -e "${BROWN}[paused]${RESET}"
                fi
            else
                case "$key" in
                    'n')
                        mpc next >/dev/null 2>&1
                        sleep 0.1
                        now_playing
                        LAST_TRACK=$(mpc current)
                        ;;
                    'p')
                        mpc prev >/dev/null 2>&1
                        sleep 0.1
                        now_playing
                        LAST_TRACK=$(mpc current)
                        ;;
                    '+')
                        mpc volume +5 >/dev/null 2>&1
                        ;;
                    '-')
                        mpc volume -5 >/dev/null 2>&1
                        ;;
                    'q')
                        cleanup
                        ;;
                esac
            fi
        else
            if [ "$SUPPRESS" -eq 1 ]; then
                SUPPRESS=0
                continue
            fi
            current=$(mpc current)
            if [ "$current" != "$LAST_TRACK" ]; then
                LAST_TRACK="$current"
                state=$(mpc status --format "%state%")
                if [ "$state" = "stop" ]; then
                    cleanup
                fi
                now_playing
            fi
        fi
    done
}

# --- main ---

if [ $# -lt 1 ]; then
    usage
fi

MINIMAL=0
ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--minimal" ] || [ "$arg" = "-m" ]; then
        MINIMAL=1
    else
        ARGS+=("$arg")
    fi
done
set -- "${ARGS[@]}"

MODE="$1"
shift
SEARCH_TERM="$*"

mpc volume 35 >/dev/null 2>&1

case "$MODE" in
    --artist|-a)
        if [ -z "$SEARCH_TERM" ]; then
            echo -e "${BEIGE}Error: --artist requiere un termino de busqueda${RESET}"
            usage
        fi

        mapfile -t MATCHES < <(mpc list artist | grep -i "$SEARCH_TERM")

        if [ ${#MATCHES[@]} -eq 0 ]; then
            echo -e "${BEIGE}No se encontro el artista: ${GREEN}$SEARCH_TERM${RESET}"
            exit 1
        fi

        ARTIST="${MATCHES[0]}"
        echo ""
        echo -e "Playing ${BEIGE}${ARTIST}${RESET} in shuffle"

        mpc clear >/dev/null 2>&1
        mpc search artist "$ARTIST" | mpc add >/dev/null 2>&1
        mpc shuffle >/dev/null 2>&1
        mpc play >/dev/null 2>&1
        ;;

    --album|-A)
        if [ -z "$SEARCH_TERM" ]; then
            echo -e "${BEIGE}Error: --album requiere un termino de busqueda${RESET}"
            usage
        fi

        mapfile -t MATCHES < <(mpc list album | grep -i "$SEARCH_TERM")

        if [ ${#MATCHES[@]} -eq 0 ]; then
            echo -e "${BEIGE}No se encontro el album: ${GREEN}$SEARCH_TERM${RESET}"
            exit 1
        fi

        ALBUM="${MATCHES[0]}"
        echo ""
        echo -e "Playing full album: ${BEIGE}${ALBUM}${RESET}"

        mpc clear >/dev/null 2>&1
        mpc search album "$ALBUM" | mpc add >/dev/null 2>&1
        mpc play >/dev/null 2>&1
        ;;

    --song|-s)
        if [ -z "$SEARCH_TERM" ]; then
            echo -e "${BEIGE}Error: --song requiere un termino de busqueda${RESET}"
            usage
        fi

        mapfile -t MATCHES < <(mpc search title "$SEARCH_TERM")

        if [ ${#MATCHES[@]} -eq 0 ]; then
            echo -e "${BEIGE}No se encontro la cancion: ${GREEN}$SEARCH_TERM${RESET}"
            exit 1
        fi

        echo ""
        echo -e "Playing..."

        mpc clear >/dev/null 2>&1
        mpc search title "$SEARCH_TERM" | head -1 | mpc add >/dev/null 2>&1
        mpc play >/dev/null 2>&1
        ;;

    --shuffle|-S)
        echo ""
        echo -e "Playing ${BEIGE}full library${RESET} in shuffle..."

        mpc clear >/dev/null 2>&1
        mpc listall | mpc add >/dev/null 2>&1
        mpc shuffle >/dev/null 2>&1
        mpc repeat on >/dev/null 2>&1
        mpc play >/dev/null 2>&1
        ;;

    --genre|-g)
        if [ -z "$SEARCH_TERM" ]; then
            echo -e "${BEIGE}Error: --genre requiere un termino de busqueda${RESET}"
            usage
        fi

        mapfile -t MATCHES < <(mpc list genre | grep -i "$SEARCH_TERM")

        if [ ${#MATCHES[@]} -eq 0 ]; then
            echo -e "${BEIGE}No se encontro el genero: ${GREEN}$SEARCH_TERM${RESET}"
            exit 1
        fi

        GENRE="${MATCHES[0]}"
        echo ""
        echo -e "Playing a random ${BEIGE}${GENRE}${RESET} selection"

        mpc clear >/dev/null 2>&1
        mpc search genre "$GENRE" | mpc add >/dev/null 2>&1
        mpc shuffle >/dev/null 2>&1
        mpc play >/dev/null 2>&1
        ;;

    *)
        usage
        ;;
esac

interactive_loop
