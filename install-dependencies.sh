#!/usr/bin/env bash

# install.sh — Leaving Spotify
# Instala dependencias del proyecto según la selección del usuario

# colores
BEIGE='\033[38;2;199;170;119m'
GREEN='\033[38;2;152;187;108m'
BROWN='\033[38;2;134;120;104m'
GRAY='\033[38;2;140;140;140m'
RESET='\033[0m'

# --- dependencias agrupadas por módulo ---
# formato: "nombre_display|paquete_pacman|paquete_apt|descripción"
DEPS=(
    "mpd|mpd|mpd|Music Player Daemon — backend de reproducción local"
    "mpc|mpc|mpc|Cliente CLI para MPD"
    "mpv|mpv|mpv|Reproductor multimedia — usado para YouTube"
    "ffmpeg|ffmpeg|ffmpeg|Extracción de portadas y análisis de audio"
    "chafa|chafa|chafa|Renderizado de imágenes en terminal"
    "yt-dlp|yt-dlp|yt-dlp|Descarga y streaming desde YouTube"
    "python|python|python3|Intérprete Python"
    "pip|python-pip|python3-pip|Gestor de paquetes Python"
    "beets|beets|beets|Organización y metadata de la biblioteca"
    "requests|_pip_requests|_pip_requests|HTTP para scripts Python"
    "python-dotenv|_pip_python-dotenv|_pip_python-dotenv|Manejo de variables de entorno (.env)"
    "google-api-python-client|_pip_google-api-python-client|_pip_google-api-python-client|API de Google (spotify_to_youtube.py)"
    "google-auth-oauthlib|_pip_google-auth-oauthlib|_pip_google-auth-oauthlib|OAuth2 para Google (spotify_to_youtube.py)"
)

PM=""

header() {
    clear
    echo ""
    echo -e "${BEIGE}./install-dependencies.sh${RESET}"
    echo ""
}

detect_or_ask_pm() {
    if command -v pacman &>/dev/null; then
        PM="pacman"
        echo -e "${GRAY}Package manager detectado: ${GREEN}pacman${RESET} ${GRAY}(Arch/CachyOS)${RESET}"
        return
    fi
    if command -v apt &>/dev/null; then
        PM="apt"
        echo -e "${GRAY}Package manager detectado: ${GREEN}apt${RESET} ${GRAY}(Debian/Ubuntu)${RESET}"
        return
    fi

    echo -e "${BEIGE}No se detectó un package manager compatible.${RESET}"
    echo ""
    echo -e "  ${GREEN}1${RESET}) pacman ${GRAY}(Arch, CachyOS, Manjaro)${RESET}"
    echo -e "  ${GREEN}2${RESET}) apt    ${GRAY}(Debian, Ubuntu, Mint)${RESET}"
    echo ""
    read -r -p "$(echo -e "${BEIGE}Opción [1/2]: ${RESET}")" pm_choice
    case "$pm_choice" in
        1) PM="pacman" ;;
        2) PM="apt"    ;;
        *)
            echo -e "${BEIGE}Opción inválida. Saliendo.${RESET}"
            exit 1
            ;;
    esac
}

is_installed() {
    local name="$1"
    local pkg_pacman="$2"

    if [[ "$pkg_pacman" == _pip_* ]]; then
        local pip_name="${pkg_pacman#_pip_}"
        pip show "$pip_name" &>/dev/null 2>&1 && return 0
        return 1
    fi

    command -v "$name" &>/dev/null && return 0

    if [ "$PM" = "pacman" ]; then
        pacman -Qi "$pkg_pacman" &>/dev/null 2>&1 && return 0
    elif [ "$PM" = "apt" ]; then
        dpkg -l "$3" 2>/dev/null | grep -q "^ii" && return 0
    fi

    return 1
}

show_dep_list() {
    echo ""
    echo -e "${BROWN}Dependencias disponibles:${RESET}"
    echo ""
    local i=1
    for dep in "${DEPS[@]}"; do
        IFS='|' read -r name pkg_pacman pkg_apt desc <<< "$dep"

        if [[ "$pkg_pacman" == _pip_* ]]; then
            tag="${GRAY}[pip]  ${RESET}"
        else
            tag="${GRAY}[pkg]  ${RESET}"
        fi

        if is_installed "$name" "$pkg_pacman" "$pkg_apt"; then
            status="${GREEN}✓${RESET}"
        else
            status="${GRAY}·${RESET}"
        fi

        printf "  %s ${GREEN}%2d${RESET})  ${BEIGE}%-30s${RESET} %s${GRAY}%s${RESET}\n" \
            "$(echo -e "$status")" "$i" "$name" "$(echo -e "$tag")" "$desc"
        ((i++))
    done
    echo ""
}

ask_selection() {
    echo -e "${BROWN}Opciones:${RESET}"
    echo -e "  ${GREEN}a${RESET})  Instalar todas"
    echo -e "  ${GREEN}n${RESET})  Solo paquetes del sistema ${GRAY}(sin pip)${RESET}"
    echo -e "  ${GREEN}1,3,5${RESET})  Números separados por coma"
    echo -e "  ${GREEN}q${RESET})  Salir"
    echo ""
    read -r -p "$(echo -e "${BEIGE}Selección: ${RESET}")" selection
    echo "$selection"
}

parse_selection() {
    local sel="$1"
    local total="${#DEPS[@]}"
    SELECTED=()

    case "$sel" in
        a|A)
            for ((i=1; i<=total; i++)); do SELECTED+=("$i"); done
            ;;
        n|N)
            local i=1
            for dep in "${DEPS[@]}"; do
                IFS='|' read -r name pkg_pacman _ _ <<< "$dep"
                if [[ "$pkg_pacman" != _pip_* ]]; then
                    SELECTED+=("$i")
                fi
                ((i++))
            done
            ;;
        q|Q)
            echo ""
            echo -e "${BROWN}Saliendo.${RESET}"
            echo ""
            exit 0
            ;;
        *)
            IFS=',' read -ra nums <<< "$sel"
            for n in "${nums[@]}"; do
                n=$(echo "$n" | tr -d ' ')
                if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "$total" ]; then
                    SELECTED+=("$n")
                else
                    echo -e "${BEIGE}Número inválido ignorado: $n${RESET}"
                fi
            done
            ;;
    esac
}

install_dep() {
    local name="$1"
    local pkg_pacman="$2"
    local pkg_apt="$3"

    if is_installed "$name" "$pkg_pacman" "$pkg_apt"; then
        echo -e "  ${GREEN}✓${RESET} ${name} ya instalado"
        return 0
    fi

    if [[ "$pkg_pacman" == _pip_* ]]; then
        local pip_name="${pkg_pacman#_pip_}"
        echo -e "  ${BEIGE}→${RESET} Instalando ${name} via pip..."
        pip install "$pip_name" --break-system-packages --quiet 2>&1 && \
            echo -e "  ${GREEN}✓${RESET} ${name} instalado" || \
            echo -e "  ${BEIGE}✗${RESET} Error instalando ${name}"
        return
    fi

    echo -e "  ${BEIGE}→${RESET} Instalando ${name}..."
    if [ "$PM" = "pacman" ]; then
        sudo pacman -S --noconfirm "$pkg_pacman" && \
            echo -e "  ${GREEN}✓${RESET} ${name} instalado" || \
            echo -e "  ${BEIGE}✗${RESET} Error instalando ${name}"
    elif [ "$PM" = "apt" ]; then
        sudo apt-get install -y "$pkg_apt" && \
            echo -e "  ${GREEN}✓${RESET} ${name} instalado" || \
            echo -e "  ${BEIGE}✗${RESET} Error instalando ${name}"
    fi
}

run_install() {
    if [ ${#SELECTED[@]} -eq 0 ]; then
        echo -e "${BEIGE}Nada seleccionado.${RESET}"
        return
    fi

    echo ""
    echo -e "${BROWN}Instalando...${RESET}"
    echo ""

    if [ "$PM" = "apt" ]; then
        echo -e "  ${GRAY}→ apt update...${RESET}"
        sudo apt-get update -qq
        echo ""
    fi

    for num in "${SELECTED[@]}"; do
        dep="${DEPS[$((num-1))]}"
        IFS='|' read -r name pkg_pacman pkg_apt desc <<< "$dep"
        install_dep "$name" "$pkg_pacman" "$pkg_apt"
    done

    echo ""
    echo -e "${GREEN}Listo.${RESET} ${GRAY}Revisá los ✗ si hubo errores.${RESET}"
    echo ""
}

# --- main ---

header
detect_or_ask_pm
show_dep_list
selection=$(ask_selection)
parse_selection "$selection"
run_install
