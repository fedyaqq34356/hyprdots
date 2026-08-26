#!/usr/bin/env python3
"""Count this user's commits per day across every git repository under $HOME.

Writes a JSON map of "YYYY-MM-DD" -> commit count to
~/.cache/git-activity.json, which the Quickshell calendar reads to shade its
day cells. Run it from a scheduler; it is cheap but not instant, and the
calendar never blocks on it.

    git-activity.py            refresh the cache
    git-activity.py --days 400 look further back than the default year
"""

import argparse
import json
import os
import subprocess
import sys
from collections import Counter
from pathlib import Path

HOME = Path.home()
CACHE = HOME / ".cache/git-activity.json"

# Directories that never contain repositories worth counting, and that are
# expensive to walk.
SKIP_DIRS = {
    ".cache", ".cargo", ".rustup", ".npm", ".local/share/Steam", ".steam",
    "node_modules", ".venv", "venv", "__pycache__", ".mozilla", ".config",
    "go/pkg", ".gradle", ".m2", "Games", ".wine", ".var",
}

MAX_DEPTH = 5


def find_repos(root: Path) -> list[Path]:
    """Directories containing a .git entry, without descending into them."""
    found: list[Path] = []
    root_depth = len(root.parts)

    for dirpath, dirnames, _ in os.walk(root, topdown=True, followlinks=False):
        current = Path(dirpath)

        if len(current.parts) - root_depth >= MAX_DEPTH:
            dirnames.clear()
            continue

        # Prune before descending; walking a Steam library to find no repos is
        # the single slowest thing this script could do.
        dirnames[:] = [
            d for d in dirnames
            if d not in SKIP_DIRS
            and not (d.startswith(".") and d != ".git")
        ]

        if ".git" in dirnames or (current / ".git").exists():
            found.append(current)
            dirnames.clear()

    return found


def identities() -> list[str]:
    """Every email that counts as "me": git config plus the login name."""
    emails = set()
    try:
        result = subprocess.run(["git", "config", "--global", "user.email"],
                                capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and result.stdout.strip():
            emails.add(result.stdout.strip())
    except (OSError, subprocess.SubprocessError):
        pass
    return sorted(emails)


def commits_in(repo: Path, since: str, authors: list[str]) -> Counter:
    """Commit dates in one repository, counted per day."""
    cmd = ["git", "-C", str(repo), "log", "--all", "--no-merges",
           f"--since={since}", "--date=short", "--pretty=%ad"]
    for email in authors:
        cmd.append(f"--author={email}")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=25)
    except (OSError, subprocess.SubprocessError):
        return Counter()
    if result.returncode != 0:
        return Counter()

    return Counter(line.strip() for line in result.stdout.splitlines()
                   if line.strip())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=400,
                    help="how far back to look (default: 400)")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    authors = identities()
    if not authors:
        print("git user.email is not set; counting every author",
              file=sys.stderr)

    since = f"{args.days} days ago"
    total = Counter()
    repos = find_repos(HOME)

    for repo in repos:
        total.update(commits_in(repo, since, authors))

    CACHE.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "generated": subprocess.run(["date", "-Is"], capture_output=True,
                                    text=True).stdout.strip(),
        "repos": len(repos),
        "days": dict(sorted(total.items())),
    }
    CACHE.write_text(json.dumps(payload))

    if not args.quiet:
        print(f"{len(repos)} repos, {sum(total.values())} commits "
              f"over {len(total)} days -> {CACHE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
