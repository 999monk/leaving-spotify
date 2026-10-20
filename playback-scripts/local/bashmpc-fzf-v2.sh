#!/usr/bin/env bash
# bashmpc-fzf: navegación interactiva de la biblioteca de MPD con fzf
#
# Uso:  bashmpc-fzf.sh [all|artist|album|title]
#
# Teclas:
#   Enter          reemplaza la cola y reproduce (selección o elemento actual)
#   Tab            agrega a la cola sin cerrar fzf y baja al siguiente
#   Shift-Tab      marca/desmarca (selección múltiple)
#   Ctrl-A/L/T/R   artistas / álbumes / títulos / todo
#   Ctrl-O         muestra/oculta la vista previa
#   Ctrl-Q, Esc    salir
#
# Variables de entorno:
#   NO_COLOR=1       desactiva los colores
#   BASHMPC_COLOR=0|1  fuerza colores apagados/encendidos
#
# Requiere: mpd, mpc, fzf >= 0.45 (transform-*), awk, sort, sed

set -euo pipefail

SEP=$'\x1f'
FMT="%albumartist%${SEP}%artist%${SEP}%album%${SEP}%title%${SEP}%file%"

# ──────────────────────
HEX_BG='#181616'          # background
HEX_FG='#c5c9c5'          # foreground
HEX_BG_PANEL='#1e1c1c'    # bg-panel
HEX_BG_MODULE='#2e2c2c'   # bg-module
HEX_BG_ALT='#3a3838'      # bg-alt
HEX_BORDER='#4a4847'      # border
HEX_DIM='#5c5a59'         # dim
HEX_MUTED='#716f6e'       # muted
HEX_SUBTLE='#888785'      # subtle
HEX_MID='#9e9d9a'         # mid
HEX_FG_SOFT='#b4b3af'     # fg-soft
HEX_FG_BRIGHT='#dcdedd'   # fg-bright
HEX_FG_CURSOR='#f0f2f0'   # fg-cursor

# Convierte '#rrggbb' en una secuencia ANSI truecolor
ansi() {
    printf '\033[38;2;%d;%d;%dm' \
        "$((16#${1:1:2}))" "$((16#${1:3:2}))" "$((16#${1:5:2}))"
}

# Solo el proceso principal decide; los que lanza fzf heredan la decisión
if [[ -z ${BASHMPC_COLOR+x} ]]; then
    if [[ -t 2 && -z ${NO_COLOR:-} ]]; then BASHMPC_COLOR=1; else BASHMPC_COLOR=0; fi
    export BASHMPC_COLOR
fi

if [[ $BASHMPC_COLOR == 1 ]]; then
    A_URGENT=$(ansi "$HEX_FG_CURSOR"); A_BRIGHT=$(ansi "$HEX_FG_BRIGHT")
    A_MID=$(ansi "$HEX_MID");          A_MUTED=$(ansi "$HEX_MUTED")
    RESET=$'\033[0m'
else
    A_URGENT=''; A_BRIGHT=''; A_MID=''; A_MUTED=''; RESET=''
fi

# ── Utilidades ───────────────────────────────────────────────────────
die() { printf '%s❌ %s%s\n' "$A_URGENT" "$*" "$RESET" >&2; exit 1; }

usage() {
    cat <<EOF
Uso: ${0##*/} [all|artist|album|title]

  Enter  reproducir (reemplaza la cola)    Tab        encolar
  Ctrl-A artistas    Ctrl-L álbumes        Shift-Tab  marcar
  Ctrl-T títulos     Ctrl-R todo           Ctrl-O     vista previa
  Ctrl-Q salir

NO_COLOR=1 desactiva los colores.
EOF
}

# ── Generación de listas ─────────────────────────────────────────────
list_artists() {
    mpc list artist \
        | awk -v sep="$SEP" -v c="$A_BRIGHT" -v r="$RESET" \
            'NF { print c "artist" r "  " $0 sep "artist" sep $0 }' \
        | sort -f
}

# Lee por stdin la salida de `mpc -f $FMT listall`. $1: album | title
songs_to() {
    awk -F "$SEP" -v kind="$1" -v sep="$SEP" \
        -v c_alb="$A_MID" -v c_tit="$A_MUTED" -v r="$RESET" '
        $5 == "" { next }
        kind == "album" && $3 != "" {
            # Sin albumartist se cae a artist, para no mezclar "Greatest Hits" de distintos autores
            tag = ($1 != "") ? "albumartist" : "artist"
            who = ($1 != "") ? $1 : $2
            key = tag sep who sep $3
            if (!(key in seen)) {
                seen[key] = 1
                label = (who != "") ? who " - " $3 : $3
                print c_alb "album " r "  " label sep "album" sep tag sep who sep $3
            }
        }
        kind == "title" {
            ttl = $4
            if (ttl == "") { n = split($5, p, "/"); ttl = p[n] }
            label = ($2 != "") ? $2 " - " ttl : ttl
            print c_tit "title " r "  " label sep "title" sep $5
        }'
}

# $1: all | artist | album | title
# Los artistas salen primero, así fzf se puede usar mientras se consulta el resto.
list() {
    local want=$1 raw=''
    if [[ $want == all || $want == artist ]]; then list_artists; fi
    if [[ $want != artist ]]; then
        raw=$(mpc -f "$FMT" listall)
        if [[ $want != title ]]; then printf '%s\n' "$raw" | songs_to album | sort -f; fi
        if [[ $want != album ]]; then printf '%s\n' "$raw" | songs_to title | sort -f; fi
    fi
}

# ── Acciones sobre una línea de la lista ─────────────────────────────
add_line() {
    local _ kind f1 f2 f3
    IFS=$SEP read -r _ kind f1 f2 f3 <<<"$1"
    case $kind in
        artist) mpc -q findadd artist "$f1" ;;
        album)  mpc -q findadd album "$f3" "$f1" "$f2" ;;
        title)  mpc -q add "$f1" ;;
        *)      return 1 ;;
    esac
}

# Lo usa fzf con Tab. La salida se muestra como etiqueta del borde.
do_add() {
    local line
    for line in "$@"; do add_line "$line" || true; done
    printf ' ➕ cola: %d ' "$(( $(mpc playlist | wc -l) ))"
}

preview() {
    [[ -n ${1:-} ]] || return 0
    local _ kind f1 f2 f3
    IFS=$SEP read -r _ kind f1 f2 f3 <<<"$1"
    case $kind in
        artist) mpc -f '%album%' find artist "$f1" | sort -u | sed '/^$/d' ;;
        album)  mpc -f '[%track%. ]%title%' find album "$f3" "$f1" "$f2" ;;
        title)  mpc -f $'Título:  %title%\nArtista: %artist%\nÁlbum:   %album%\nArchivo: %file%' \
                    find file "$f1" ;;
    esac
}

# ── Modos internos (los invoca fzf a través de --bind/--preview) ─────
case "${1:-}" in
    --list)    list "${2:-all}"; exit 0 ;;
    --add)     shift; do_add "$@"; exit 0 ;;
    --preview) preview "${2:-}"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
esac

# ── Programa principal ───────────────────────────────────────────────
mode=${1:-all}
case $mode in
    all|artist|album|title) ;;
    *) usage >&2; die "Modo desconocido: $mode" ;;
esac

for cmd in mpc fzf; do
    command -v "$cmd" >/dev/null 2>&1 || die "Falta '$cmd' en el PATH"
done

mpc status >/dev/null 2>&1 || die "MPD no responde"

songs=$(mpc stats 2>/dev/null | awk '/^Songs:/ { print $2 }')
[[ $songs == 0 ]] && die "Biblioteca vacía"

# Ruta absoluta de este script, para que fzf pueda volver a llamarlo
SELF="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
printf -v SELF_Q '%q' "$SELF"

# fzf ejecuta los binds con $SHELL; forzamos bash por si el usuario usa fish/zsh
export SHELL="$BASH"

if [[ $BASHMPC_COLOR == 1 ]]; then
    fzf_theme="--color=fg:$HEX_FG,bg:$HEX_BG,hl:$HEX_FG_CURSOR:underline"
    fzf_theme+=" --color=fg+:$HEX_FG_BRIGHT,bg+:$HEX_BG_MODULE,hl+:$HEX_FG_CURSOR:underline"
    fzf_theme+=" --color=info:$HEX_MUTED,prompt:$HEX_FG_BRIGHT,pointer:$HEX_FG_CURSOR"
    fzf_theme+=" --color=marker:$HEX_FG_CURSOR,spinner:$HEX_DIM,header:$HEX_MUTED"
    fzf_theme+=" --color=border:$HEX_BORDER,label:$HEX_SUBTLE,gutter:$HEX_BG"
    fzf_theme+=" --color=preview-bg:$HEX_BG_PANEL,preview-fg:$HEX_FG"
else
    fzf_theme='--no-color'
fi
export FZF_DEFAULT_OPTS="$fzf_theme ${FZF_DEFAULT_OPTS:-}"

# change-prompt + reload para cada filtro
mode_bind() {
    printf '%s:change-prompt(♫ %s> )+reload(%s --list %s)' "$1" "$2" "$SELF_Q" "$2"
}

rc=0
selection=$(fzf \
    --ansi --multi \
    --delimiter="$SEP" --with-nth=1 \
    --height=100% --layout=reverse --border \
    --prompt="♫ $mode> " --pointer='▶' --marker='✓' \
    --preview="$SELF_Q --preview {}" \
    --preview-window='right,45%,wrap,<90(hidden)' \
    --header="Enter:Play | Tab:Queue | S-Tab:Mark | ^A:Artists ^L:Albums ^T:Titles ^R:All | ^O:Preview | ^Q:Quit" \
    --bind="$(mode_bind ctrl-a artist)" \
    --bind="$(mode_bind ctrl-l album)" \
    --bind="$(mode_bind ctrl-t title)" \
    --bind="$(mode_bind ctrl-r all)" \
    --bind="tab:transform-border-label($SELF_Q --add {+})+clear-selection+down" \
    --bind="ctrl-o:toggle-preview" \
    --bind="ctrl-q:abort" \
    < <(list "$mode")
) || rc=$?

# 1 = sin coincidencias, 130 = Esc/Ctrl-Q; cualquier otro código es un error de fzf
(( rc == 0 || rc == 1 || rc == 130 )) || exit "$rc"
[[ $rc -eq 0 && -n $selection ]] || exit 0

# Enter: reemplazar la cola y reproducir
mpc -q clear
while IFS= read -r line; do
    [[ -n $line ]] || continue
    add_line "$line" || true
done <<<"$selection"

queued=$(( $(mpc playlist | wc -l) ))
(( queued > 0 )) || die "No se encontraron archivos"

mpc -q play
printf '%s▶%s %s%s%s' "$A_URGENT" "$RESET" "$A_BRIGHT" \
    "$(mpc current -f '[%artist% - ]%title%|%file%')" "$RESET"
if (( queued > 1 )); then
    printf ' %s(+%d en la cola)%s' "$A_MUTED" "$((queued - 1))" "$RESET"
fi
printf '\n'
