#!/usr/bin/env python3
import configparser
import shutil
import sys
from pathlib import Path

SOURCE = Path.home() / ".config/matugen/out/librewolf-userchrome.css"

HOME = Path.home()

SEARCH_ROOTS = [
    HOME / ".config/librewolf",
    HOME / ".librewolf",
    HOME / ".config/mozilla",
    HOME / ".mozilla",
    HOME / ".config/zen",
    HOME / ".zen",
    HOME / ".config/waterfox",
    HOME / ".waterfox",
    HOME / ".var/app",
]

PREF_LINE = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

PALETTE_FILE = "matugen-colors.css"
IMPORT_LINE = f'@import url("{PALETTE_FILE}");'
IMPORT_BLOCK = f"/* matugen palette - regenerated on wallpaper change */\n{IMPORT_LINE}\n"

THEME_DIR = HOME / ".config/librewolf-theme"
THEME_FILES = ("userChrome.css", "userContent.css")

def profile_inis() -> list[Path]:
    found: list[Path] = []
    for root in SEARCH_ROOTS:
        if not root.is_dir():
            continue
        for pattern in ("profiles.ini", "*/profiles.ini", "*/*/profiles.ini",
                        "*/*/*/profiles.ini"):
            found.extend(root.glob(pattern))
    return sorted(set(found))

def profiles_from(ini_path: Path) -> list[Path]:
    parser = configparser.ConfigParser()
    try:
        parser.read(ini_path)
    except configparser.Error as exc:
        print(f"skip {ini_path}: {exc}", file=sys.stderr)
        return []

    base = ini_path.parent
    out: list[Path] = []
    for section in parser.sections():
        if not section.lower().startswith("profile"):
            continue
        path = parser[section].get("Path")
        if not path:
            continue
        relative = parser[section].get("IsRelative", "1") == "1"
        target = (base / path) if relative else Path(path)
        if target.is_dir():
            out.append(target)
    return out

def seed_theme(chrome: Path) -> list[str]:
    """Кладёт оформление в профиль, если его там ещё нет.

    Существующие файлы не трогаем: у профиля может быть своя тема, и
    затирать её на каждой смене обоев — худшее, что может сделать хук."""
    seeded: list[str] = []
    for name in THEME_FILES:
        source = THEME_DIR / name
        target = chrome / name
        if source.is_file() and not target.exists():
            shutil.copyfile(source, target)
            seeded.append(name)
    return seeded

def ensure_import(chrome: Path) -> str:
    states: list[str] = []

    for name in THEME_FILES:
        sheet = chrome / name
        if not sheet.exists():
            if name == "userChrome.css":
                sheet.write_text(IMPORT_BLOCK)
                states.append("userChrome created")
            continue

        text = sheet.read_text()
        if PALETTE_FILE in text:
            continue

        sheet.write_text(IMPORT_BLOCK + text)
        states.append(f"{name} linked")

    return ", ".join(states) if states else "already linked"

def ensure_pref(profile: Path) -> None:
    user_js = profile / "user.js"
    existing = user_js.read_text() if user_js.exists() else ""
    if "legacyUserProfileCustomizations.stylesheets" in existing:
        return
    prefix = "" if not existing or existing.endswith("\n") else "\n"
    with user_js.open("a") as f:
        f.write(f"{prefix}// Required for the matugen userChrome.css\n{PREF_LINE}\n")

def main() -> int:
    if not SOURCE.is_file():
        print(f"{SOURCE} missing - run matugen first", file=sys.stderr)
        return 1

    targets: list[Path] = []
    for ini in profile_inis():
        targets.extend(profiles_from(ini))

    if not targets:
        print("no browser profiles found - nothing to do")
        return 0

    for profile in targets:
        chrome = profile / "chrome"
        chrome.mkdir(exist_ok=True)
        shutil.copyfile(SOURCE, chrome / PALETTE_FILE)
        seeded = seed_theme(chrome)
        state = ensure_import(chrome)
        if seeded:
            state = f"seeded {' + '.join(seeded)}"
        ensure_pref(profile)
        print(f"themed: {profile.parent.name}/{profile.name} ({state})")

    print("restart the browser to see it")
    return 0

if __name__ == "__main__":
    sys.exit(main())
