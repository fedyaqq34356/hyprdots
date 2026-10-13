#!/usr/bin/env bash
set -u

PRINTER="${1:-}"

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

if [[ -z "$PRINTER" ]]; then
    printf '{"ok":false,"options":{}}\n'
    exit 0
fi

printf '{"ok":true,"printer":"%s","options":{' "$(json_escape "$PRINTER")"

first=1
while IFS= read -r line; do
    [[ "$line" == *:* ]] || continue

    head="${line%%:*}"
    rest="${line#*:}"
    key="${head%%/*}"
    [[ -n "$key" ]] || continue

    current=""
    values=""
    for v in $rest; do
        if [[ "$v" == \** ]]; then
            v="${v#\*}"
            current="$v"
        fi
        [[ -n "$values" ]] && values+=","
        values+="\"$(json_escape "$v")\""
    done
    [[ -n "$values" ]] || continue

    (( first )) || printf ','
    first=0
    printf '"%s":{"current":"%s","values":[%s]}' \
        "$(json_escape "$key")" "$(json_escape "$current")" "$values"
done < <(lpoptions -d "$PRINTER" -l 2>/dev/null)

printf '}}\n'
