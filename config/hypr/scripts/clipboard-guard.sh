#!/usr/bin/env bash
set -u

LOG="$HOME/.local/state/clipboard-guard.log"
mkdir -p "$(dirname "$LOG")"
touch "$LOG"; chmod 600 "$LOG"

SECRET_TTL="${CLIPBOARD_SECRET_TTL:-45}"

looks_secret() {
    printf '%s' "$1" | grep -qiE \
        'sk-ant-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{30,}|github_pat_|xox[baprs]-|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|[0-9]{8,10}:AA[A-Za-z0-9_-]{33}'
}

owner() {
    hyprctl -j activewindow 2>/dev/null \
        | jq -r 'if .class then "\(.class)  ·  \(.title // "" | .[0:60])" else "?" end' 2>/dev/null \
        || printf '?'
}

log() { printf '%s\t%s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }

if [[ "${1:-}" == "--entry" ]]; then
    types="${2:-}"
    data=$(wl-paste --no-newline 2>/dev/null)
    len=${#data}

    mark="$HOME/.local/state/clipboard-guard.last"
    sig=$(printf '%s' "$data" | sha1sum | cut -d" " -f1)
    now=$(date +%s)
    if [[ -f "$mark" ]]; then
        read -r prev_sig prev_ts < "$mark" 2>/dev/null || true
        if [[ "$sig" == "${prev_sig:-}" ]] && (( now - ${prev_ts:-0} < 5 )); then
            exit 0
        fi
    fi
    printf '%s %s\n' "$sig" "$now" > "$mark"
    chmod 600 "$mark" 2>/dev/null

    who=$(owner)

    if looks_secret "$data"; then
        log "SECRET  length=$len  types=$types  from: $who"
        notify-send -a clipboard -u critical "Clipboard" \
            "Looks like a secret — clearing in ${SECRET_TTL}s" 2>/dev/null
        (
            sleep "$SECRET_TTL"
            current=$(wl-paste --no-newline 2>/dev/null)
            if [[ "$current" == "$data" ]]; then
                wl-copy --clear
                log "cleared on a timer"
                notify-send -a clipboard "Clipboard" "Secret cleared" 2>/dev/null
            fi
        ) &
    else
        log "entry   length=$len  types=$types  from: $who"
    fi
    exit 0
fi

wl-paste --watch sh -c '
    types=$(wl-paste --list-types 2>/dev/null | tr "\n" "," | sed "s/,$//")
    exec "$0" --entry "$types"
' "$0"
