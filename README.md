
Un ecosistema personal y minimalista para abandonar Spotify, construido sobre herramientas P2P y open source. Sin suscripciones, sin algoritmos, sin datos enviados a ningún lado. Un intento por construir una biblioteca personal, organizada a gusto y extensible con scripts propios. Cada pieza del stack es reemplazable, auditaable y opcional.

---

## Stack

```
Descarga      →  torrents / soulseek (nicotine+)
Organización  →  beets
Reproducción  →  mpd + mpc (local) / mpv + yt-dlp (online)
Playlists     →  exportify + script python → YouTube
Visualización →  ffmpeg + chafa (portadas en terminal)
```

---

## Módulos

### 1. Descargar música

Fuentes p2p: torrents y Soulseek vía Nicotine+.

---

### 2. Organizar la biblioteca

[**beets**](https://github.com/beetbox/beets) es impresionante, se encarga de todo lo relacionado a metadata y estructura:

- Renombrado automático con formato homogéneo: `Artista/Album/track.ext`
- Etiquetado automático via MusicBrainz
- Base de datos local con stats, búsquedas, plugins

Plugins recomendados: `fetchart`, `embedart`, `musicbrainz`

---

### 3. Reproducción local — `bashmpc.sh`

[**MPD**](https://github.com/MusicPlayerDaemon/MPD) (Music Player Daemon) como backend: un daemon que indexa la biblioteca, mantiene estado y expone un socket. Cualquier cliente puede controlarlo.

**mpc** como cliente CLI: un comando por operación, perfecto para scripting.

`bashmpc.sh` es un wrapper de bash sobre mpc con controles interactivos:

```bash
play --artist "steely dan"
play --album "royal scam"
play --song "deacon blues"
play --genre "jazz rock"
play --shuffle
```

Por default muestra portada del álbum (extraída con ffmpeg, renderizada con chafa) y metadata completa. Con `--minimal` muestra solo la línea `♫ Artista - Título [Album]`.

---

### 4. Reproducción online — `bashyt.sh`

[mpv](https://github.com/mpv-player/mpv) + [yt-dlp](https://github.com/yt-dlp/yt-dlp) para reproducir desde YouTube directamente en la terminal, sin browser, sin interfaz gráfica.

```bash
yt --playlist "white groove"
yt --url "https://youtube.com/watch?v=..."
yt --search "jaco pastorius portrait of tracy"
```

---

### 5. Playlists — `spot-to-yt.py`

[Exportify](https://exportify.net/) para extraer las playlists de Spotify en formato `.csv`. Luego un script de Python que toma ese csv, busca cada canción en YouTube via yt-dlp y crea la playlist automáticamente en tu cuenta usando la YouTube Data API v3 con autenticación OAuth2.

```bash
python spotify_to_youtube.py --csv mi_playlist.csv --name "Mi Playlist"
```

---

## Dependencias

```
mpd mpc
ffmpeg ffprobe
chafa
yt-dlp
python + google-api-python-client google-auth-oauthlib
beets
```
