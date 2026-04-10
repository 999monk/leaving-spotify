
Un ecosistema personal y minimalista construido sobre herramientas P2P y open source. Sin suscripciones, sin algoritmos, sin telemetría. Un intento por construir una biblioteca personal, organizada a gusto y extensible con scripts propios. Cada pieza del stack es reemplazable, auditable y opcional.

---

## Stack

```
Descarga      →  torrents / sldl, soulseek (nicotine+)
Organización  →  beets
Reproducción  →  mpd + mpc (local) / mpv + yt-dlp (online)
Playlists     →  exportify + script python → YouTube
Recomendación →  script python
Visualización →  ffmpeg + chafa (portadas en terminal)
```

---

## Módulos

### 1. Descargar música

Fuentes p2p: torrents, [sldl](https://github.com/fiso64/sldl) o [Soulseek vía Nicotine+](https://nicotine-plus.org/).

`download-menu.sh` cli de bash sobre sldl para simplificar y organizar la descarga de albums, playlists o discografías. Requiere sldl en el PATH y su respectiva configuración en `~/.config/sldl/sldl.conf`.

### 2. Organizar la biblioteca

[**beets**](https://github.com/beetbox/beets) es impresionante, se encarga de todo lo relacionado a metadata y estructura:

- Renombrado automático con formato homogéneo: `Artista/Album/track.ext`
- Etiquetado automático via MusicBrainz y Discogs
- Base de datos local con stats, búsquedas, plugins

Plugins recomendados: `fetchart`, `embedart`, `musicbrainz`, `scrub`, `discogs` 

### 3. Reproducción local — `bashmpc.sh`, `bashmpc-fzf.sh`

[**MPD**](https://github.com/MusicPlayerDaemon/MPD) (Music Player Daemon) como backend: un daemon que indexa la biblioteca, mantiene estado y expone un socket. Cualquier cliente puede controlarlo.

**mpc** como cliente CLI: un comando por operación, perfecto para scripting.

`bashmpc.sh` es un cli de bash sobre mpc con flags:

```bash
play --artist "steely dan"
play --album "the royal scam"
play --song "deacon blues"
play --genre "jazz rock"
play --shuffle
```

Con `--minimal` se muestra línea `♫ Artista - Título [Album]` en consola.

`view-cover.sh` muestra portada del álbum (extraída con ffmpeg, renderizada con chafa) y metadata completa. 

`bashmpc-fzf.sh` versión alternativa para navegación visual e interactiva con fzf.

### 3.1 Controles y visualización desde polybar

En `~/.config/polybar/config.ini`:
```
[module/mpd]
type = custom/script
exec = ~/.config/polybar/scripts/mpd-status.sh
tail = true
click-left = mpc toggle
click-right = mpc next
scroll-up = mpc volume +5
scroll-down = mpc volume -5
label-maxlen = 60
```

### 4. Reproducción online — `bashyt.sh`

[mpv](https://github.com/mpv-player/mpv) + [yt-dlp](https://github.com/yt-dlp/yt-dlp) para reproducir desde YouTube directamente en la terminal, sin browser, sin interfaz gráfica.

```bash
yt --playlist "white groove"
yt --url "https://youtube.com/watch?v=..."
yt --search "jaco pastorius portrait of tracy"
```

### 5. Playlists — `spot-to-yt.py`

[Exportify](https://exportify.net/) para extraer las playlists de Spotify en formato `.csv`. Luego un script de Python que toma ese csv, busca cada canción en YouTube via yt-dlp y crea la playlist automáticamente en tu cuenta usando la YouTube Data API v3 con autenticación OAuth2.

```bash
python spotify_to_youtube.py --csv mi_playlist.csv --name "Mi Playlist"
```

### 6. Recomendación — `get-reco.py`

`get-reco.py`: recomendaciones musicales via Last.fm filtradas contra la biblioteca de beets.

Uso:
```bash
    python get-reco.py --genre "jazz fusion"
    python get-reco.py --genre "funk" --year 1970
    python get-reco.py --similar "steely dan"
    python get-reco.py --from-library
    python get-reco.py --from-library --genre "soul"
    python get-reco.py --genre "jazz fusion" --rare
    python get-reco.py --similar "steely dan" --rare --rare-threshold 20000
```

---

## Dependencias

`install-dependecies.sh`: Instala dependencias del proyecto según la selección del usuario.

- Detecta automáticamente pacman/apt; si no funciona, selecciona manualmente.
- Muestra todas las dependencias del proyecto agrupadas por tipo (pkg/pip).
- Muestra el estado de instalación de cada dependencia.
- Permite la instalación selectiva por número, todas las dependencias o solo las del sistema.
- Compatible con Arch/CachyOS y Debian/Ubuntu (por ahora).

```
mpd mpc
mpv
fzf
ffmpeg ffprobe
chafa
yt-dlp
python + google-api-python-client google-auth-oauthlib
beets
sldl
```
