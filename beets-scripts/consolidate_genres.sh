#!/usr/bin/env bash

# Consolidar y normalizar géneros en beets.

GREEN='\033[38;2;152;187;108m'
BEIGE='\033[38;2;199;170;119m'
RESET='\033[0m'

echo -e "${GREEN}Consolidando géneros...${RESET}"
echo ""

# Hip-Hop variations
echo -e "${BEIGE}→ Consolidando Hip-Hop...${RESET}"
beet modify -y genre:"Hip Hop" genre="Hip-Hop"
beet modify -y genre:"Rap/Hip Hop" genre="Hip-Hop"
beet modify -y genre:"Hip-Hop/Rap" genre="Hip-Hop"
beet modify -y genre:"Rap" genre="Hip-Hop"
beet modify -y genre:"Hip-Hop/Beat Tape" genre="Hip-Hop"
beet modify -y genre:"Abstract Hip Hop" genre="Hip-Hop"

# Jazz variations
echo -e "${BEIGE}→ Consolidando Jazz...${RESET}"
beet modify -y genre:"Jazz/Fusion" genre="Jazz Fusion"
beet modify -y genre:"Jazz-Fusion" genre="Jazz Fusion"
beet modify -y genre:"Jazz/Bebop" genre="Jazz"
beet modify -y genre:"Contemporary Jazz / Post-Bop / Fusion" genre="Jazz Fusion"
beet modify -y genre:"Contemporary Jazz" genre="Jazz"
beet modify -y genre:"Jazz, Hard Bop" genre="Jazz"
beet modify -y genre:"Jazz, Free Jazz" genre="Jazz"
beet modify -y genre:"Jazz, Avant-Garde Jazz" genre="Jazz"
beet modify -y genre:"Avant-Garde Jazz" genre="Jazz"
beet modify -y genre:"Brazilian Jazz" genre="Jazz"

# Jazz Funk variations
echo -e "${BEIGE}→ Consolidando Jazz Funk...${RESET}"
beet modify -y genre:"Jazz funk" genre="Jazz Funk"
beet modify -y genre:"Jazz-Funk" genre="Jazz Funk"
beet modify -y genre:"Jazz+Funk" genre="Jazz Funk"
beet modify -y genre:"Jazz-Funk;Latin Jazz;Smooth Jazz;Soul Jazz" genre="Jazz Funk"

# Jazz Rock variations
echo -e "${BEIGE}→ Consolidando Jazz Rock...${RESET}"
beet modify -y genre:"jazz, rock" genre="Jazz Rock"
beet modify -y genre:"Jazz-Rock" genre="Jazz Rock"

# Rock variations
echo -e "${BEIGE}→ Consolidando Rock...${RESET}"
beet modify -y genre:"Rock; Psychedelic Rock" genre="Rock"
beet modify -y genre:"Rock Progresivo" genre="Progressive Rock"
beet modify -y genre:"Symphonic Prog" genre="Progressive Rock"

# Stoner Rock/Metal
echo -e "${BEIGE}→ Consolidando Stoner Rock...${RESET}"
beet modify -y genre:"StonerRock" genre="Stoner Rock"

# Indie variations
echo -e "${BEIGE}→ Consolidando Indie...${RESET}"
beet modify -y genre:"Indie Rock / Brit Pop" genre="Indie Rock"
beet modify -y genre:"Indie Pop/Rock" genre="Indie Rock"
beet modify -y genre:"Post-Punk/ Indie / Alternative" genre="Indie Rock"

# R&B variations
echo -e "${BEIGE}→ Consolidando R&B...${RESET}"
beet modify -y genre:"R&B/Soul" genre="R&B"

# Pop variations
echo -e "${BEIGE}→ Consolidando Pop...${RESET}"
beet modify -y genre:"Progressive Pop" genre="Pop"
beet modify -y genre:"Pop-Jazz" genre="Jazz Pop"
beet modify -y genre:"Jazz Pop" genre="Jazz Pop"
beet modify -y genre:"80S Soul Pop" genre="Pop"
beet modify -y genre:"80S Pop Ballad" genre="Pop"

# Limpiar géneros múltiples complejos con muchos separadores
echo -e "${BEIGE}→ Simplificando géneros múltiples...${RESET}"
beet modify -y genre:"Synthpop;Neo-Psychedelia;Psychedelic Pop;Hypnagogic Pop;New Wave" genre="Synthpop"
beet modify -y genre:"Indietronica;Indie Pop;Synthpop;Psychedelic Pop;Electropop;Psychedelic Pop;Neo-Psychedelia" genre="Indietronica"
beet modify -y genre:"Contemporary R&B;Dance-Pop;Disco;Funk;Pop;Pop Rock;Pop Soul;Rock;Soul" genre="R&B"
beet modify -y genre:"Jazz;Latin;Mpb;Rock;Samba" genre="Latin Jazz"
beet modify -y genre:"Drum And Bass/Electronic/Experimental/Idm/Jungle" genre="Electronic"
beet modify -y genre:"Hip Hop/Jazz/Latin/Latin Jazz" genre="Jazz"
beet modify -y genre:"Jazz/Latin/Latin Jazz" genre="Latin Jazz"
beet modify -y genre:"Jazz/Latin Jazz" genre="Latin Jazz"

# New Wave variations
beet modify -y genre:"Reggae Fusion, Post-Punk, Pop Rock" genre="New Wave"
beet modify -y genre:"Pop Rock, New Wave, Rock" genre="New Wave"
beet modify -y genre:"New Wave, Rock, Reggae" genre="New Wave"
beet modify -y genre:"Ska, Pop Rock, New Wave" genre="New Wave"
beet modify -y genre:"Ska, New Wave, Rock" genre="New Wave"
beet modify -y genre:"Progressive Rock, New Wave, Alternative Rock" genre="New Wave"
beet modify -y genre:"New Wave, Rock, Pop" genre="New Wave"
beet modify -y genre:"New Wave, Alternative Rock, Rock" genre="New Wave"

# Limpiar géneros vacíos o basura
echo -e "${BEIGE}→ Limpiando géneros inválidos...${RESET}"
beet modify -y genre:"Other" genre=""
beet modify -y genre:"City pop(Album)/" genre="Pop"
beet modify -y genre:"Indie / Soul" genre="Indie"

echo ""
echo -e "${GREEN}✓ Consolidación completada${RESET}"
echo ""
echo -e "${BEIGE}Verificando resultado...${RESET}"
beet ls -f '$genre' | grep -v '^$' | sort | uniq -c | sort -rn | head -20
