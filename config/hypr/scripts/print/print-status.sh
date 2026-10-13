#!/usr/bin/env bash
set -u

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/ }"
    s="${s//$'\r'/}"
    printf '%s' "$s"
}

if ! lpstat -r >/dev/null 2>&1; then
    printf '{"cups":false,"capt":{"needed":false},"printers":[],"jobs":[]}\n'
    exit 0
fi

DEFAULT=$(lpstat -d 2>/dev/null | sed -n 's/.*: *//p')

declare -A URI
while IFS= read -r line; do
    [[ "$line" =~ ^device\ for\ ([^:]+):\ (.*)$ ]] || continue
    URI["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
done < <(lpstat -v 2>/dev/null)

CAPT_NEEDED=0
printers=""
while IFS= read -r line; do
    [[ "$line" =~ ^printer\ ([^ ]+)\ (is\ [^.]*|now\ [^.]*)\. ]] || continue
    name="${BASH_REMATCH[1]}"
    state="${BASH_REMATCH[2]}"

    case "$state" in
        *idle*)     st="idle" ;;
        *printing*) st="printing" ;;
        *disabled*) st="stopped" ;;
        *)          st="unknown" ;;
    esac

    reason=$(printf '%s' "$line" | sed -n 's/.*- *//p')
    uri="${URI[$name]:-}"
    capt=false
    [[ "$uri" == ccp://* ]] && { capt=true; CAPT_NEEDED=1; }

    accepting=false
    lpstat -a "$name" 2>/dev/null | grep -q 'accepting requests' && accepting=true

    [[ -n "$printers" ]] && printers+=","
    printers+=$(printf '{"name":"%s","state":"%s","reason":"%s","uri":"%s","capt":%s,"accepting":%s,"default":%s}' \
        "$(json_escape "$name")" "$st" "$(json_escape "$reason")" \
        "$(json_escape "$uri")" "$capt" "$accepting" \
        "$([[ "$name" == "$DEFAULT" ]] && echo true || echo false)")
done < <(lpstat -p 2>/dev/null)

jobs=""
while IFS= read -r line; do
    read -r id user size rest <<<"$line"
    [[ -n "$id" ]] || continue
    [[ -n "$jobs" ]] && jobs+=","
    jobs+=$(printf '{"id":"%s","user":"%s","size":%s,"when":"%s"}' \
        "$(json_escape "$id")" "$(json_escape "$user")" \
        "$([[ "$size" =~ ^[0-9]+$ ]] && echo "$size" || echo 0)" \
        "$(json_escape "$rest")")
done < <(lpstat -o 2>/dev/null)

DEV=""
for d in /dev/usb/lp*; do
    [[ -e "$d" ]] && { DEV="$d"; break; }
done

CCPD_PID=$(pidof ccpd 2>/dev/null | awk '{print $1}')
STALE=false
if [[ -n "$DEV" && -n "$CCPD_PID" ]]; then
    dev_age=$(stat -c %Z "$DEV" 2>/dev/null || echo 0)
    pid_age=$(stat -c %Z "/proc/$CCPD_PID" 2>/dev/null || echo 0)
    (( pid_age < dev_age )) && STALE=true
fi

printf '{"cups":true,"default":"%s","capt":{"needed":%s,"device":"%s","daemon":%s,"stale":%s},"printers":[%s],"jobs":[%s]}\n' \
    "$(json_escape "${DEFAULT:-}")" \
    "$([[ $CAPT_NEEDED == 1 ]] && echo true || echo false)" \
    "$(json_escape "$DEV")" \
    "$([[ -n "$CCPD_PID" ]] && echo true || echo false)" \
    "$STALE" \
    "$printers" "$jobs"
