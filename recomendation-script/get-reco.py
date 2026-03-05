#!/usr/bin/env python3

"""
get-reco: recomendaciones musicales via Last.fm filtradas contra tu biblioteca beets

Dependencias:
    pip install requests python-dotenv

API key en .env (mismo directorio):
    LASTFM_API_KEY=tu_api_key

Uso:
    python get-reco.py --genre "jazz fusion"
    python get-reco.py --genre "funk" --year 1970
    python get-reco.py --similar "steely dan"
    python get-reco.py --from-library
    python get-reco.py --from-library --genre "soul"
    python get-reco.py --genre "jazz fusion" --rare
    python get-reco.py --similar "steely dan" --rare --rare-threshold 20000
"""

import argparse
import os
import subprocess
import sys

import requests
from dotenv import load_dotenv

# colores
BEIGE = "\033[38;2;199;170;119m"
GREEN = "\033[38;2;152;187;108m"
BROWN = "\033[38;2;134;120;104m"
GRAY = "\033[38;2;140;140;140m"
RESET = "\033[0m"

load_dotenv()
API_KEY = os.getenv("LASTFM_API_KEY")
BASE_URL = "https://ws.audioscrobbler.com/2.0/"

if not API_KEY:
    print(f"{BEIGE}Error: LASTFM_API_KEY no encontrada en .env{RESET}")
    sys.exit(1)

# cache
_listeners_cache = {}


def lastfm(method, params):
    params.update(
        {
            "method": method,
            "api_key": API_KEY,
            "format": "json",
            "limit": 50,
        }
    )
    try:
        r = requests.get(BASE_URL, params=params, timeout=10)
        r.raise_for_status()
        return r.json()
    except requests.RequestException as e:
        print(f"{BEIGE}Error de red: {e}{RESET}")
        return {}


def get_listeners(artist):
    key = artist.lower()
    if key in _listeners_cache:
        return _listeners_cache[key]
    data = lastfm("artist.getInfo", {"artist": artist})
    try:
        listeners = int(data.get("artist", {}).get("stats", {}).get("listeners", 0))
    except (ValueError, TypeError):
        listeners = 0
    _listeners_cache[key] = listeners
    return listeners


def is_rare(artist, threshold):
    return get_listeners(artist) < threshold


def get_library_artists():
    try:
        result = subprocess.run(
            ["beet", "list", "-a", "-f", "$albumartist"], capture_output=True, text=True
        )
        artists = set(
            line.strip().lower() for line in result.stdout.splitlines() if line.strip()
        )
        return artists
    except FileNotFoundError:
        print(f"{BEIGE}Error: beets no encontrado{RESET}")
        return set()


def get_library_albums():
    try:
        result = subprocess.run(
            ["beet", "list", "-a", "-f", "$albumartist - $album"],
            capture_output=True,
            text=True,
        )
        albums = set(
            line.strip().lower() for line in result.stdout.splitlines() if line.strip()
        )
        return albums
    except FileNotFoundError:
        return set()


def already_have(artist, album, library_albums):
    key = f"{artist.lower()} - {album.lower()}"
    return key in library_albums


def print_reco(artist, album, listeners=None, index=None, rare=False):
    prefix = f"{GRAY}{index:>2}.{RESET} " if index else "    "
    rare_str = f"  {BROWN}◈ rare{RESET}" if rare else ""
    if listeners is not None:
        try:
            listeners_str = f"  {GRAY}{int(listeners):,} listeners{RESET}"
        except (ValueError, TypeError):
            listeners_str = ""
    else:
        listeners_str = ""
    print(
        f"{prefix}{GREEN}{artist}{RESET} — {BEIGE}{album}{RESET}{listeners_str}{rare_str}"
    )


def reco_by_genre(
    tag,
    year_filter=None,
    library_albums=None,
    limit=15,
    rare=False,
    rare_threshold=50000,
):
    """Recomendar álbumes por género/tag."""
    rare_str = f" {BROWN}(rare < {rare_threshold:,}){RESET}" if rare else ""
    print(f"\n{BROWN}Buscando álbumes de '{tag}'{rare_str}...{RESET}\n")

    data = lastfm("tag.getTopAlbums", {"tag": tag})
    albums = data.get("albums", {}).get("album", [])

    if not albums:
        print(f"{BEIGE}No se encontraron álbumes para el tag '{tag}'{RESET}")
        return

    shown = 0
    for item in albums:
        if shown >= limit:
            break
        artist = item.get("artist", {}).get("name", "")
        album = item.get("name", "")

        if not artist or not album:
            continue
        if already_have(artist, album, library_albums):
            continue

        listeners = get_listeners(artist)
        if rare and listeners >= rare_threshold:
            continue

        print_reco(
            artist,
            album,
            listeners=listeners if rare else None,
            index=shown + 1,
            rare=rare,
        )
        shown += 1

    if shown == 0:
        print(
            f"{GRAY}Todo lo encontrado ya está en tu biblioteca o no cumple el filtro.{RESET}"
        )


def reco_similar(
    artist_query, library_albums=None, limit=15, rare=False, rare_threshold=50000
):
    rare_str = f" {BROWN}(rare < {rare_threshold:,}){RESET}" if rare else ""
    print(
        f"\n{BROWN}Buscando artistas similares a '{artist_query}'{rare_str}...{RESET}\n"
    )

    data = lastfm("artist.getSimilar", {"artist": artist_query, "limit": 30})
    similar = data.get("similarartists", {}).get("artist", [])

    if not similar:
        print(f"{BEIGE}No se encontraron artistas similares a '{artist_query}'{RESET}")
        return

    shown = 0
    for artist_data in similar:
        if shown >= limit:
            break
        artist = artist_data.get("name", "")
        if not artist:
            continue

        listeners = get_listeners(artist)
        if rare and listeners >= rare_threshold:
            continue

        top = lastfm("artist.getTopAlbums", {"artist": artist, "limit": 3})
        top_albums = top.get("topalbums", {}).get("album", [])

        for alb in top_albums:
            if shown >= limit:
                break
            album = alb.get("name", "")
            if not album:
                continue
            if already_have(artist, album, library_albums):
                continue

            print_reco(
                artist,
                album,
                listeners=listeners if rare else None,
                index=shown + 1,
                rare=rare,
            )
            shown += 1
            break

    if shown == 0:
        print(
            f"{GRAY}Todo lo encontrado ya está en tu biblioteca o no cumple el filtro.{RESET}"
        )


def reco_from_library(
    library_artists,
    library_albums,
    genre_filter=None,
    limit=15,
    rare=False,
    rare_threshold=50000,
):
    """Tomar artistas random de tu biblioteca y buscar similares que no tengas."""
    import random

    if not library_artists:
        print(f"{BEIGE}No se encontraron artistas en la biblioteca{RESET}")
        return

    sample = random.sample(list(library_artists), min(5, len(library_artists)))
    genre_str = f" filtrando por '{genre_filter}'" if genre_filter else ""
    rare_str = f" {BROWN}(rare < {rare_threshold:,}){RESET}" if rare else ""
    print(
        f"\n{BROWN}Recomendaciones basadas en tu biblioteca{genre_str}{rare_str}...{RESET}"
    )
    print(f"{GRAY}Semilla: {', '.join(sample)}{RESET}\n")

    shown = 0
    seen_artists = set()

    for seed_artist in sample:
        if shown >= limit:
            break

        data = lastfm("artist.getSimilar", {"artist": seed_artist, "limit": 15})
        similar = data.get("similarartists", {}).get("artist", [])

        for artist_data in similar:
            if shown >= limit:
                break
            artist = artist_data.get("name", "")
            if (
                not artist
                or artist.lower() in library_artists
                or artist.lower() in seen_artists
            ):
                continue

            listeners = get_listeners(artist)
            if rare and listeners >= rare_threshold:
                continue

            if genre_filter:
                tags_data = lastfm("artist.getTopTags", {"artist": artist})
                tags = [
                    t.get("name", "").lower()
                    for t in tags_data.get("toptags", {}).get("tag", [])
                ]
                if not any(genre_filter.lower() in t for t in tags):
                    continue

            top = lastfm("artist.getTopAlbums", {"artist": artist, "limit": 1})
            top_albums = top.get("topalbums", {}).get("album", [])

            for alb in top_albums:
                album = alb.get("name", "")
                if not album or already_have(artist, album, library_albums):
                    continue
                print_reco(
                    artist,
                    album,
                    listeners=listeners if rare else None,
                    index=shown + 1,
                    rare=rare,
                )
                seen_artists.add(artist.lower())
                shown += 1
                break

    if shown == 0:
        print(f"{GRAY}No se encontraron recomendaciones nuevas.{RESET}")


def main():
    parser = argparse.ArgumentParser(
        description="Recomendaciones musicales via Last.fm filtradas contra tu biblioteca"
    )
    parser.add_argument("--genre", type=str, help="Recomendar por género/tag")
    parser.add_argument("--year", type=int, help="Filtrar por año (con --genre)")
    parser.add_argument(
        "--similar", type=str, help="Artistas y álbumes similares a uno dado"
    )
    parser.add_argument(
        "--from-library", action="store_true", help="Basado en tu biblioteca"
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=15,
        help="Cantidad de recomendaciones (default: 15)",
    )
    parser.add_argument(
        "--rare", action="store_true", help="Solo artistas con pocos listeners"
    )
    parser.add_argument(
        "--rare-threshold",
        type=int,
        default=50000,
        help="Threshold de listeners para --rare (default: 50000)",
    )
    args = parser.parse_args()

    if not any([args.genre, args.similar, args.from_library]):
        parser.print_help()
        sys.exit(1)

    print(f"{GRAY}Cargando biblioteca...{RESET}", end="", flush=True)
    library_artists = get_library_artists()
    library_albums = get_library_albums()
    print(f" {len(library_albums)} álbumes, {len(library_artists)} artistas{RESET}")

    if args.rare:
        print(f"{GRAY}Modo rare: < {args.rare_threshold:,} listeners{RESET}")

    if args.genre and not args.from_library:
        reco_by_genre(
            args.genre,
            year_filter=args.year,
            library_albums=library_albums,
            limit=args.limit,
            rare=args.rare,
            rare_threshold=args.rare_threshold,
        )
    elif args.similar:
        reco_similar(
            args.similar,
            library_albums=library_albums,
            limit=args.limit,
            rare=args.rare,
            rare_threshold=args.rare_threshold,
        )
    elif args.from_library:
        reco_from_library(
            library_artists,
            library_albums,
            genre_filter=args.genre,
            limit=args.limit,
            rare=args.rare,
            rare_threshold=args.rare_threshold,
        )

    print()


if __name__ == "__main__":
    main()
