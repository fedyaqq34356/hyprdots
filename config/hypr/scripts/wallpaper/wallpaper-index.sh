#!/usr/bin/env bash
set -u

DIR="${1:-$HOME/Pictures/Wallpapers}"
THUMBS="$HOME/.cache/wallpaper-thumbs"
INDEX="$THUMBS/colors.tsv"

mkdir -p "$THUMBS"
touch "$INDEX"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

while IFS= read -r wp; do
    name=$(basename "$wp")

    if line=$(grep -m1 -F "$(printf '%s\t' "$name")" "$INDEX" 2>/dev/null); then
        printf '%s\n' "$line" >> "$tmp"
        continue
    fi

    src="$THUMBS/$name"
    [ -f "$src" ] || src="$wp"

    hex=$(nice -n 19 magick "$src" -resize 1x1\! -depth 8 -format '#%[hex:p{0,0}]' info: 2>/dev/null)
    [ -n "$hex" ] || continue

    printf '%s\t%s\n' "$name" "${hex:0:7}" >> "$tmp"
done < <(find "$DIR" -maxdepth 1 -type f \
             \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)

mv "$tmp" "$INDEX"
trap - EXIT
