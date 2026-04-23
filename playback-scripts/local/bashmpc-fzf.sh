#!/usr/bin/env bash
# navegación interactiva con fzf

set -euo pipefail

BEIGE=''
GREEN=''
BROWN=''
GRAY=''
RESET=''

MUSIC_DIR=""

if ! mpc status >/dev/null 2>&1; then
    echo -e "${BROWN}❌ MPD no responde${RESET}" >&2
    exit 1
fi

# GENERAR LISTA
list_data=$({
    mpc list artist 2>/dev/null | sed 's/^/artist | /'
    mpc list album 2>/dev/null | sed 's/^/album  | /'
    mpc list title 2>/dev/null | sed 's/^/title  | /'
} | sort)

[[ -z "$list_data" ]] && { echo -e "${BROWN}❌ Biblioteca vacía${RESET}" >&2; exit 1; }

# FZF
# Exportar colores para fzf
export FZF_DEFAULT_OPTS="
    --color=fg:#8c8c8c,bg:#181616,hl:#c7aa77
    --color=fg+:#e6c384,bg+:#282727,hl+:#c7aa77
    --color=info:#98bb6c,prompt:#c7aa77,pointer:#98bb6c
    --color=marker:#98bb6c,spinner:#98bb6c,header:#867864
    --height=100%
    --layout=reverse
    --border
    --prompt='♫ '
    --pointer='▶'
    --marker='✓'
"

result=$(echo "$list_data" | fzf \
    --bind="ctrl-a:change-prompt(♫ artist> )+reload(mpc list artist 2>/dev/null | sed 's/^/artist | /')" \
    --bind="ctrl-l:change-prompt(♫ album> )+reload(mpc list album 2>/dev/null | sed 's/^/album  | /')" \
    --bind="ctrl-t:change-prompt(♫ title> )+reload(mpc list title 2>/dev/null | sed 's/^/title  | /')" \
    --bind="ctrl-r:change-prompt(♫ all> )+reload({ mpc list artist 2>/dev/null | sed 's/^/artist | /'; mpc list album 2>/dev/null | sed 's/^/album  | /'; mpc list title 2>/dev/null | sed 's/^/title  | /'; } | sort)" \
    --bind="ctrl-q:abort" \
    --header="Enter:Play | Tab:Queue | Ctrl-A:Artists | Ctrl-L:Albums | Ctrl-T:Titles | Ctrl-R:All | Ctrl-Q:Quit" \
    --expect="enter,tab"
)

# PROCESAR RESULTADO
key=$(head -1 <<< "$result")
selection=$(tail -n +2 <<< "$result")

[[ "$key" == "ctrl-q" ]] || [[ -z "$selection" ]] && exit 0

# Parsear
type=$(echo "$selection" | cut -d'|' -f1 | tr -d ' ')
value=$(echo "$selection" | cut -d'|' -f2- | sed 's/^ *//')

# Obtener archivos
files=""
case "$type" in
    artist) files=$(mpc find artist "$value" 2>/dev/null) ;;
    album)  files=$(mpc find album "$value" 2>/dev/null) ;;
    title)  files=$(mpc search title "$value" 2>/dev/null | head -1) ;;
esac

[[ -z "$files" ]] && { echo -e "${BROWN}❌ No se encontraron archivos${RESET}" >&2; exit 1; }

# Ejecutar
case "$key" in
    enter)
        mpc clear >/dev/null 2>&1
        echo "$files" | mpc add
        mpc play >/dev/null
        echo -e "${GREEN}▶${RESET} ${BEIGE}$(mpc current -f '%artist% - %title%')${RESET}"
        ;;
    tab)
        echo "$files" | mpc add
        echo -e "${BEIGE}➕ Agregado a la cola:${RESET} ${GRAY}$value${RESET}"
        ;;
esac
