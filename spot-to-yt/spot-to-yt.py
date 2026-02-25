#!/usr/bin/env python3

"""
spotify_to_youtube.py
Crea una playlist de YouTube a partir de un CSV exportado de Spotify.

Dependencias:
    pip install google-api-python-client google-auth-oauthlib yt-dlp

Uso:
    python spot_to_yt.py --csv playlist.csv --name "Nombre de la playlist"

Setup:
    1. Ir a https://console.cloud.google.com
    2. Crear proyecto → habilitar "YouTube Data API v3"
    3. Credenciales → OAuth 2.0 → Aplicación de escritorio → descargar client_secret.json
    4. Poner client_secret.json en el mismo directorio que este script
"""

import argparse
import csv
import json
import os
import sys
import time

try:
    import yt_dlp
except ImportError:
    print("Falta yt-dlp: pip install yt-dlp")
    sys.exit(1)

try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    print(
        "Faltan dependencias de Google: pip install google-api-python-client google-auth-oauthlib"
    )
    sys.exit(1)

# --- config ---
SCOPES = ["https://www.googleapis.com/auth/youtube"]
CLIENT_SECRET_FILE = "client_secret.json"
TOKEN_FILE = "token.json"
NOT_FOUND_LOG = "not_found.txt"


def authenticate():
    """OAuth2 flow. Primera vez abre el browser, después usa el token guardado."""
    creds = None

    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(CLIENT_SECRET_FILE):
                print(f"Error: no se encontró {CLIENT_SECRET_FILE}")
                print(
                    "Descargalo desde Google Cloud Console → Credenciales → OAuth 2.0"
                )
                sys.exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRET_FILE, SCOPES)
            creds = flow.run_local_server(port=0)

        with open(TOKEN_FILE, "w") as f:
            f.write(creds.to_json())

    return build("youtube", "v3", credentials=creds)


def search_youtube(track_name, artist):
    """Busca la canción en YouTube y devuelve el video_id del primer resultado."""
    query = f"{artist} {track_name}"
    ydl_opts = {
        "quiet": True,
        "no_warnings": True,
        "extract_flat": True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            results = ydl.extract_info(f"ytsearch1:{query}", download=False)
            if results and results.get("entries"):
                entry = results["entries"][0]
                return entry.get("id"), entry.get("title")
        except Exception as e:
            print(f"  Error buscando '{query}': {e}")
    return None, None


def create_playlist(youtube, name, description=""):
    """Crea una playlist en YouTube y devuelve su ID."""
    response = (
        youtube.playlists()
        .insert(
            part="snippet,status",
            body={
                "snippet": {
                    "title": name,
                    "description": description,
                },
                "status": {"privacyStatus": "private"},
            },
        )
        .execute()
    )
    return response["id"]


def add_to_playlist(youtube, playlist_id, video_id):
    """Agrega un video a la playlist."""
    youtube.playlistItems().insert(
        part="snippet",
        body={
            "snippet": {
                "playlistId": playlist_id,
                "resourceId": {
                    "kind": "youtube#video",
                    "videoId": video_id,
                },
            }
        },
    ).execute()


def read_csv(filepath):
    """Lee el CSV de Spotify y devuelve lista de (track_name, artist)."""
    tracks = []
    with open(filepath, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            track = row.get("Track Name", "").strip()
            artist = row.get("Artist Name(s)", "").strip()
            # si hay múltiples artistas separados por coma, tomar solo el primero
            artist = artist.split(",")[0].strip()
            if track and artist:
                tracks.append((track, artist))
    return tracks


def main():
    parser = argparse.ArgumentParser(
        description="Crea playlist de YouTube desde CSV de Spotify"
    )
    parser.add_argument("--csv", required=True, help="Path al archivo CSV")
    parser.add_argument(
        "--name", required=True, help="Nombre de la playlist en YouTube"
    )
    parser.add_argument(
        "--description",
        default="Creada desde Spotify CSV",
        help="Descripción de la playlist",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Solo busca en YouTube, no crea nada"
    )
    args = parser.parse_args()

    # leer CSV
    print(f"Leyendo {args.csv}...")
    tracks = read_csv(args.csv)
    print(f"  {len(tracks)} canciones encontradas\n")

    # autenticar (salvo dry-run)
    youtube = None
    if not args.dry_run:
        print("Autenticando con YouTube...")
        youtube = authenticate()
        print("  OK\n")

        print(f"Creando playlist '{args.name}'...")
        playlist_id = create_playlist(youtube, args.name, args.description)
        print(f"  ID: {playlist_id}\n")

    # procesar canciones
    found = []
    not_found = []

    for i, (track, artist) in enumerate(tracks, 1):
        print(f"[{i}/{len(tracks)}] {artist} - {track}")
        video_id, video_title = search_youtube(track, artist)

        if video_id:
            print(f"  ✓ {video_title}")
            found.append((track, artist, video_id, video_title))

            if not args.dry_run:
                try:
                    add_to_playlist(youtube, playlist_id, video_id)
                    time.sleep(0.5)  # evitar rate limiting
                except HttpError as e:
                    print(f"  Error agregando a playlist: {e}")
        else:
            print(f"  ✗ No encontrado")
            not_found.append((track, artist))

        time.sleep(0.3)  # ser amable con yt-dlp

    # resumen
    print(f"\n{'=' * 50}")
    print(f"Encontradas: {len(found)}/{len(tracks)}")
    print(f"No encontradas: {len(not_found)}")

    if not_found:
        with open(NOT_FOUND_LOG, "w") as f:
            for track, artist in not_found:
                f.write(f"{artist} - {track}\n")
        print(f"No encontradas guardadas en {NOT_FOUND_LOG}")

    if not args.dry_run and youtube:
        print(f"\nPlaylist creada: https://www.youtube.com/playlist?list={playlist_id}")


if __name__ == "__main__":
    main()
