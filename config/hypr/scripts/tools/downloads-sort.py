#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

DOWNLOADS = Path.home() / "Downloads"
INTERVAL = 5

CATEGORIES = {
    "Images": {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".svg",
               ".avif", ".heic", ".ico", ".tiff"},
    "Video": {".mp4", ".mkv", ".webm", ".avi", ".mov", ".m4v", ".flv", ".wmv"},
    "Audio": {".mp3", ".flac", ".wav", ".ogg", ".opus", ".m4a", ".aac", ".wma"},
    "Documents": {".pdf", ".epub", ".djvu", ".doc", ".docx", ".odt", ".rtf",
                  ".txt", ".md", ".xls", ".xlsx", ".ods", ".csv", ".ppt",
                  ".pptx", ".odp"},
    "Archives": {".zip", ".tar", ".gz", ".xz", ".bz2", ".zst", ".7z", ".rar",
                 ".tgz", ".lz4"},
    "Packages": {".pkg", ".deb", ".rpm", ".appimage", ".apk", ".flatpakref",
                 ".exe", ".msi", ".dmg"},
    "Code": {".py", ".sh", ".js", ".ts", ".rs", ".go", ".c", ".h", ".cpp",
             ".java", ".rb", ".lua", ".json", ".toml", ".yaml", ".yml",
             ".patch", ".diff"},
    "Torrents": {".torrent"},
    "Disks": {".iso", ".img", ".qcow2", ".vdi"},
    "Fonts": {".ttf", ".otf", ".woff", ".woff2"},
}

EXT_MAP = {ext: folder for folder, exts in CATEGORIES.items() for ext in exts}

PARTIAL_SUFFIXES = (".part", ".crdownload", ".download", ".tmp", ".partial",
                    ".!qb", ".aria2")

OWNED = set(CATEGORIES) | {"Other"}

MIME_PREFIXES = {
    "image/": "Images",
    "video/": "Video",
    "audio/": "Audio",
    "text/": "Documents",
    "font/": "Fonts",
}

MIME_EXACT = {
    "application/pdf": "Documents",
    "application/epub+zip": "Documents",
    "application/zip": "Archives",
    "application/x-tar": "Archives",
    "application/gzip": "Archives",
    "application/x-xz": "Archives",
    "application/zstd": "Archives",
    "application/x-7z-compressed": "Archives",
    "application/x-rar": "Archives",
    "application/x-bittorrent": "Torrents",
    "application/vnd.debian.binary-package": "Packages",
    "application/x-rpm": "Packages",
    "application/x-alpine-package": "Packages",
    "application/x-executable": "Packages",
    "application/x-sharedlib": "Packages",
    "application/x-dosexec": "Packages",
    "application/x-iso9660-image": "Disks",
    "application/x-shellscript": "Code",
    "text/x-shellscript": "Code",
    "text/x-python": "Code",
    "text/x-script.python": "Code",
    "text/x-c": "Code",
    "text/x-c++": "Code",
    "text/x-java": "Code",
    "text/x-lua": "Code",
    "text/x-ruby": "Code",
    "text/x-perl": "Code",
    "text/x-php": "Code",
    "text/javascript": "Code",
    "text/css": "Code",
    "text/html": "Code",
    "text/xml": "Code",
    "text/csv": "Documents",
    "text/markdown": "Documents",
    "application/json": "Code",
    "application/xml": "Code",
    "application/x-sqlite3": "Documents",
}

def category_by_mime(path: Path) -> str | None:
    if not shutil.which("file"):
        return None
    try:
        result = subprocess.run(
            ["file", "--brief", "--mime-type", "--", str(path)],
            capture_output=True, text=True, timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None

    mime = result.stdout.strip().lower()
    if mime in MIME_EXACT:
        return MIME_EXACT[mime]
    for prefix, folder in MIME_PREFIXES.items():
        if mime.startswith(prefix):
            return folder
    return None

def category_for(path: Path) -> str:
    if path.name.lower().endswith((".tar.gz", ".tar.xz", ".tar.bz2",
                                   ".tar.zst")):
        return "Archives"

    known = EXT_MAP.get(path.suffix.lower())
    if known:
        return known

    return category_by_mime(path) or "Other"

def unique_target(target: Path) -> Path:
    if not target.exists():
        return target
    stem, suffix = target.stem, target.suffix
    n = 2
    while True:
        candidate = target.with_name(f"{stem} ({n}){suffix}")
        if not candidate.exists():
            return candidate
        n += 1

def candidates() -> list[Path]:
    out = []
    for entry in DOWNLOADS.iterdir():
        if entry.is_dir():
            continue
        if entry.name.startswith("."):
            continue
        if entry.name.lower().endswith(PARTIAL_SUFFIXES):
            continue
        out.append(entry)
    return out

def notify(count: int) -> None:
    if not shutil.which("notify-send"):
        return
    word = "file" if count == 1 else "files"
    os.system(f'notify-send -a downloads-sort -i folder-download '
              f'"Downloads sorted" "{count} {word} filed away"')

SCRUB_SUFFIXES = {
    ".jpg", ".jpeg", ".png", ".webp", ".tif", ".tiff", ".heic", ".avif",
    ".mp4", ".mkv", ".mov", ".webm", ".m4v", ".mp3", ".flac", ".m4a",
    ".opus", ".ogg", ".wav", ".pdf",
}

SCRUB = Path.home() / ".local/bin/scrub-meta"

def scrub(path: Path) -> None:
    """Strips metadata, GPS included, from files landing in Downloads."""
    if path.suffix.lower() not in SCRUB_SUFFIXES or not SCRUB.is_file():
        return
    try:
        subprocess.run([str(SCRUB), str(path)], check=False,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=120)
    except (OSError, subprocess.SubprocessError):
        pass

def main() -> int:
    if not DOWNLOADS.is_dir():
        print(f"{DOWNLOADS} does not exist", file=sys.stderr)
        return 1

    last_size: dict[Path, int] = {}

    while True:
        moved = 0
        seen: dict[Path, int] = {}

        for path in candidates():
            try:
                size = path.stat().st_size
            except OSError:
                continue
            seen[path] = size

            if last_size.get(path) != size:
                continue

            folder = DOWNLOADS / category_for(path)
            folder.mkdir(exist_ok=True)
            target = unique_target(folder / path.name)
            try:
                shutil.move(str(path), str(target))
                scrub(target)
                moved += 1
            except OSError as exc:
                print(f"skip {path.name}: {exc}", file=sys.stderr)

        last_size = seen
        if moved:
            notify(moved)
        time.sleep(INTERVAL)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
