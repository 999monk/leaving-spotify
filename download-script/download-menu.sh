#!/usr/bin/env bash

# sldl-menu — Simple downloader interface for sldl
# Dependencies: sldl in PATH, ~/.config/sldl/sldl.conf

set -euo pipefail

DOWNLOAD_ROOT="$HOME/sldl-downloads"
CONFIG_FILE="$HOME/.config/sldl/sldl.conf"

BEIGE='\033[38;2;199;170;119m'
GREEN='\033[38;2;152;187;108m'
BROWN='\033[38;2;134;120;104m'
GRAY='\033[38;2;140;140;140m'
RESET='\033[0m'

# Check dependencies
check_sldl() {
    if ! command -v sldl &>/dev/null; then
        echo -e "${BROWN}Error: sldl not found in PATH${RESET}"
        echo -e "${GRAY}Install from: https://github.com/fiso64/sldl/releases${RESET}"
        exit 1
    fi

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${BROWN}Warning: $CONFIG_FILE not found${RESET}"
        echo -e "${GRAY}sldl will use default settings or command-line credentials${RESET}"
        sleep 1
    fi
}

show_header() {
    clear
    echo ""
    echo -e "${BEIGE}── sldl downloader ──────────────────────────────────${RESET}"
    echo ""
}

show_menu() {
    show_header
    echo -e "    ${BEIGE}[1]${RESET}  ${GRAY}album${RESET}"
    echo -e "    ${BEIGE}[2]${RESET}  ${GRAY}playlist${RESET}"
    echo -e "    ${BEIGE}[3]${RESET}  ${GRAY}discography${RESET}"
    echo ""
    echo -e "    ${BROWN}[q]${RESET}  ${GRAY}quit${RESET}"
    echo ""
    read -r -n1 -p "  > " opt
    echo ""
}

get_input() {
    local prompt="$1"
    local var_name="$2"
    echo -en "  ${BEIGE}${prompt}:${RESET} "
    read -r "$var_name"
}

download_album() {
    local artist_album
    get_input "artist - album" artist_album

    if [[ -z "$artist_album" ]]; then
        echo -e "  ${BROWN}Error: empty input${RESET}"
        sleep 1
        return
    fi

    local output_dir="$DOWNLOAD_ROOT/albums"
    mkdir -p "$output_dir"

    echo ""
    echo -e "  ${GRAY}downloading to:${RESET} ${GREEN}$output_dir${RESET}"
    echo ""

    sldl "$artist_album" -a -t -p "$output_dir"
}

download_playlist() {
    echo ""
    echo -e "  ${BEIGE}playlist source:${RESET}"
    echo -e "    ${BEIGE}[1]${RESET}  ${GRAY}spotify url${RESET}"
    echo -e "    ${BEIGE}[2]${RESET}  ${GRAY}csv file${RESET}"
    echo ""
    echo -en "  ${BEIGE}>${RESET} "
    read -r source_type

    local output_dir="$DOWNLOAD_ROOT/playlists"
    mkdir -p "$output_dir"

    case "$source_type" in
        1)
            local url
            get_input "spotify url" url

            if [[ -z "$url" ]]; then
                echo -e "  ${BROWN}Error: empty url${RESET}"
                sleep 1
                return
            fi

            echo ""
            echo -e "  ${GRAY}downloading to:${RESET} ${GREEN}$output_dir${RESET}"
            echo ""

            sldl "$url" -p "$output_dir"
            ;;
        2)
            local csv_path
            get_input "csv file path" csv_path

            # Expand tilde
            csv_path="${csv_path/#\~/$HOME}"

            if [[ ! -f "$csv_path" ]]; then
                echo -e "  ${BROWN}Error: file not found:${RESET} ${GRAY}$csv_path${RESET}"
                sleep 1
                return
            fi

            echo ""
            echo -e "  ${GRAY}downloading to:${RESET} ${GREEN}$output_dir${RESET}"
            echo ""

            sldl "$csv_path" --input-type csv -p "$output_dir"
            ;;
        *)
            echo -e "  ${BROWN}Invalid option${RESET}"
            sleep 1
            ;;
    esac
}

download_discography() {
    local artist
    get_input "artist name" artist

    if [[ -z "$artist" ]]; then
        echo -e "  ${BROWN}Error: empty input${RESET}"
        sleep 1
        return
    fi

    local output_dir="$DOWNLOAD_ROOT/discographies/$artist"
    mkdir -p "$output_dir"

    echo ""
    echo -e "  ${GRAY}downloading to:${RESET} ${GREEN}$output_dir${RESET}"
    echo -e "  ${GRAY}mode:${RESET} ${BEIGE}aggregate album (interactive)${RESET}"
    echo ""

    sldl "artist=$artist" -a -g -t -p "$output_dir"
}

# Main loop
main() {
    check_sldl

    while true; do
        show_menu
        case "$opt" in
            1)
                download_album
                echo ""
                echo -e "  ${GRAY}[Enter] to continue${RESET}"
                read -r
                ;;
            2)
                download_playlist
                echo ""
                echo -e "  ${GRAY}[Enter] to continue${RESET}"
                read -r
                ;;
            3)
                download_discography
                echo ""
                echo -e "  ${GRAY}[Enter] to continue${RESET}"
                read -r
                ;;
            q)
                echo ""
                exit 0
                ;;
            *)
                echo -e "  ${BROWN}Invalid option${RESET}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
