#!/usr/bin/env bash

BEIGE='\033[38;2;199;170;119m'
GREEN='\033[38;2;152;187;108m'
BROWN='\033[38;2;134;120;104m'
WHITE='\033[97m'
RESET='\033[0m'

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BEIGE}               📊 Stats                 ${RESET}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Totales básicos
echo -e "${WHITE}Totales:${RESET}"
TOTAL_TRACKS=$(beet ls | wc -l)
TOTAL_ALBUMS=$(beet ls -a | wc -l)
TOTAL_ARTISTS=$(beet ls -f '$albumartist' | sort -u | wc -l)

echo -e "  ${GREEN}Canciones:${RESET} $TOTAL_TRACKS"
echo -e "  ${GREEN}Álbumes:${RESET}   $TOTAL_ALBUMS"
echo -e "  ${GREEN}Artistas:${RESET}  $TOTAL_ARTISTS"

# Duration total
echo ""
echo -e "${WHITE}Duración total:${RESET}"
DURATION=$(beet stats | grep -i "total" | grep -i "time" | awk '{print $3, $4}')
echo -e "  ${BEIGE}$DURATION${RESET}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Top 10 Artistas
echo ""
echo -e "${WHITE}Top 10 Artistas (por álbumes):${RESET}"
beet ls -a -f '$albumartist' | sort | uniq -c | sort -rn | head -10 | while read count artist; do
    # Crear barra visual proporcional
    bar_length=$((count / 2))  # Dividir por 2 para que no sea muy largo
    bar=$(printf "%${bar_length}s" | tr ' ' '#')
    printf "  ${GREEN}%-30s${RESET} ${BROWN}%s${RESET} ${BEIGE}%2d${RESET}\n" "$artist" "$bar" "$count"
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Top 10 Géneros
echo ""
echo -e "${WHITE}Top 10 Géneros:${RESET}"
beet ls -f '$genre' | grep -v '^$' | sort | uniq -c | sort -rn | head -10 | while read count genre; do
    bar_length=$((count / 10))  # Ajustar según tu cantidad de canciones
    bar=$(printf "%${bar_length}s" | tr ' ' '#')
    printf "  ${GREEN}%-30s${RESET} ${BROWN}%s${RESET} ${BEIGE}%3d${RESET}\n" "$genre" "$bar" "$count"
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Álbumes por década
echo ""
echo -e "${WHITE}Álbumes por década:${RESET}"
beet ls -a -f '$year' | grep -E '^[0-9]{4}$' | sed 's/\(..\).$/\10s/' | sort | uniq -c | sort -k2 | while read count decade; do
    # Calcular barra proporcional
    bar_length=$((count / 5))  # Ajustar según tu colección
    [ $bar_length -lt 1 ] && bar_length=1
    bar=$(printf "%${bar_length}s" | tr ' ' '=')
    printf "  ${BEIGE}%s${RESET}  ${GREEN}%s${RESET} ${BROWN}(%d álbumes)${RESET}\n" "$decade" "$bar" "$count"
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
