#!/usr/bin/env bash
set -u

CACHE="$HOME/.cache/rofi-thumbs"
mkdir -p "$CACHE"

DIR="${1:-$HOME/Pictures}"
[[ -d "$DIR" ]] || DIR="$HOME/Pictures"

MAX_NEW_THUMBS=60
made=0

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

thumb_for() {
    local f="$1"
    case "${f,,}" in
        *.jpg|*.jpeg|*.png|*.webp|*.gif|*.bmp|*.avif)
            printf '%s' "$f"
            return 0
            ;;
        *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v|*.wmv|*.flv)
            local key out
            key=$(printf '%s' "$f" | sha1sum | cut -d' ' -f1)
            out="$CACHE/$key.png"
            if [[ -f "$out" && "$out" -nt "$f" ]]; then
                printf '%s' "$out"
                return 0
            fi
            (( made >= MAX_NEW_THUMBS )) && return 1
            if ffmpegthumbnailer -i "$f" -o "$out" -s 480 -q 8 >/dev/null 2>&1; then
                made=$((made + 1))
                printf '%s' "$out"
                return 0
            fi
            return 1
            ;;
    esac
    return 1
}

printf '{"dir":"%s","parent":"%s","entries":[' \
    "$(json_escape "$DIR")" "$(json_escape "$(dirname "$DIR")")"

first=1
emit() {
    (( first )) || printf ','
    first=0
    printf '%s' "$1"
}

while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    emit "$(printf '{"name":"%s","path":"%s","type":"dir"}' \
        "$(json_escape "$(basename "$d")")" "$(json_escape "$d")")"
done < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sort)

while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    t=$(thumb_for "$f") || continue
    emit "$(printf '{"name":"%s","path":"%s","type":"file","thumb":"%s"}' \
        "$(json_escape "$(basename "$f")")" \
        "$(json_escape "$f")" \
        "$(json_escape "$t")")"
done < <(find "$DIR" -mindepth 1 -maxdepth 1 -type f ! -name '.*' 2>/dev/null | sort)

printf ']}\n'
