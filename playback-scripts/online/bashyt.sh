#!/usr/bin/env bash

# colors
BEIGE='\033[38;2;199;170;119m'
GREEN='\033[38;2;152;187;108m'
BROWN='\033[38;2;134;120;104m'
RESET='\033[0m'

# --- playlists ---
declare -A PLAYLISTS
PLAYLISTS["white groove aproach"]="https://www.youtube.com/playlist?list=PL5PzgayM_cglQoCFmpjINPR4j1m6RYx6I"
PLAYLISTS["post-bop de manu"]="https://youtube.com/playlist?list=PL5PzgayM_cgn5GTxFf7S7jkV6SsCmPqqD&si=LTP6Li_i3uljlHan"
PLAYLISTS["19:19"]="https://youtube.com/playlist?list=PL5PzgayM_cgnB2VPjMtBxpXkMEb5d-qyB&si=v-wNA54dTZ1K4Mnb"
PLAYLISTS["hard-b0p enjoyer"]="https://youtube.com/playlist?list=PL5PzgayM_cglWTH_n505SZas7Q7C7rBKZ&si=y_gJcOPyvc-06Eiv"
PLAYLISTS["surfingDistortionWave"]="https://youtube.com/playlist?list=PL5PzgayM_cgkmL1TU-UgiIXHeYlVc0_Ls&si=vAwrJiD2rkGk2lWm"

# --- mpv options ---
MPV_OPTS=(
    --no-video
    --audio-display=no
    --term-osd-bar
    --volume=35
    --term-playing-msg=$'\033[97m♫\033[0m \033[38;2;199;170;119m${media-title}\033[0m'
    --msg-level=all=no,term-msg=info
)

usage() {
    echo ""
    echo -e "Keys: ${BROWN}space=pause | enter=next | 9/0=vol | q=quit${RESET}"
    echo ""
    echo -e "${BEIGE}Uso:${RESET}"
    echo -e "  $0 --playlist <alias>"
    echo -e "  $0 --url <youtube_url>"
    echo -e "  $0 --list"
    echo -e "  $0 --search <término>"
    echo ""
    echo -e "${BEIGE}Ejemplos:${RESET}"
    echo -e "  $0 --playlist \"white groove\""
    echo -e "  $0 --url \"https://youtube.com/watch?v=...\""
    echo -e "  $0 --url \"https://youtube.com/playlist?list=...\""
    echo ""
    echo -e "                            ${BROWN}script by monk999${RESET}"
    exit 1
}

list_playlists() {
    echo ""
    echo -e "${BEIGE}Playlists disponibles:${RESET}"
    for alias in "${!PLAYLISTS[@]}"; do
        echo -e "  ${GREEN}${alias}${RESET}"
    done
    echo ""
    exit 0
}

play() {
    local url="$1"
    local label="$2"
    echo ""
    echo -e "Playing ${BEIGE}${label}${RESET}"
    mpv "${MPV_OPTS[@]}" "$url"
}

if [ $# -lt 1 ]; then
    usage
fi

MODE="$1"
shift
ARG="$*"

case "$MODE" in
    --playlist|-p)
        if [ -z "$ARG" ]; then
            echo -e "${BEIGE}Error: --playlist requiere un alias${RESET}"
            usage
        fi

        # buscar alias (case insensitive)
        MATCH=""
        for alias in "${!PLAYLISTS[@]}"; do
            if [[ "${alias,,}" == *"${ARG,,}"* ]]; then
                MATCH="$alias"
                break
            fi
        done

        if [ -z "$MATCH" ]; then
            echo -e "${BEIGE}No se encontró la playlist: ${GREEN}${ARG}${RESET}"
            echo -e "Usá ${BROWN}$0 --list${RESET} para ver las disponibles"
            exit 1
        fi

        play "${PLAYLISTS[$MATCH]}" "$MATCH"
        ;;

    --url|-u)
        if [ -z "$ARG" ]; then
            echo -e "${BEIGE}Error: --url requiere una URL${RESET}"
            usage
        fi
        play "$ARG" "$ARG"
        ;;

    --list|-l)
        list_playlists
        ;;

    --search|-s)
        if [ -z "$ARG" ]; then
            echo -e "${BEIGE}Error: --search requiere un término de búsqueda${RESET}"
            usage
        fi
        echo ""
        echo -e "Searching ${BEIGE}${ARG}${RESET}..."
        URL=$(yt-dlp "ytsearch1:$ARG" --get-id 2>/dev/null | head -1)
        if [ -z "$URL" ]; then
            echo -e "${BEIGE}No se encontró: ${GREEN}${ARG}${RESET}"
            exit 1
        fi
        play "https://www.youtube.com/watch?v=$URL" "$ARG"
        ;;

    *)
        usage
        ;;
esac
