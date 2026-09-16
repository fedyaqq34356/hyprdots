#!/usr/bin/env bash
set -u

PDF="${1:-}"
PRINTER="${2:-}"
COPIES="${3:-1}"
RANGE="${4:-}"
TITLE="${5:-document}"
shift 5 2>/dev/null || true

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/ }"
    printf '%s' "$s"
}

fail() {
    printf '{"ok":false,"code":"%s","error":"%s"}\n' "$1" "$(json_escape "$2")"
    exit 0
}

[[ -n "$PDF" && -e "$PDF" ]] || fail nodoc "нечего печатать"
[[ -n "$PRINTER" ]] || fail noprinter "принтер не выбран"

"$HOME/.config/hypr/scripts/print-doctor.sh" --quiet >/dev/null 2>&1 || true

args=(-d "$PRINTER" -t "$TITLE")

[[ "$COPIES" =~ ^[0-9]+$ ]] && (( COPIES > 1 )) && args+=(-n "$COPIES")
[[ -n "$RANGE" ]] && args+=(-P "$RANGE")

for pair in "$@"; do
    [[ "$pair" =~ ^[A-Za-z][A-Za-z0-9_-]*=[A-Za-z0-9._:,-]+$ ]] || continue
    args+=(-o "$pair")
done

out=$(lp "${args[@]}" -- "$PDF" 2>&1) || fail lp "$out"

id=$(printf '%s' "$out" | sed -n 's/.*request id is \([^ ]*\).*/\1/p')
printf '{"ok":true,"id":"%s"}\n' "$(json_escape "${id:-}")"
