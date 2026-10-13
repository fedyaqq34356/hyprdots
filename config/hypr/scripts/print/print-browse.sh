#!/usr/bin/env bash
set -u

DIR="${1:-$HOME}"
[[ -d "$DIR" ]] || DIR="$HOME"

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

kind_of() {
    case "${1,,}" in
        *.pdf)                                   echo pdf ;;
        *.doc|*.docx|*.odt|*.rtf|*.fodt|*.abw|*.dot|*.dotx) echo word ;;
        *.ppt|*.pptx|*.odp|*.pps|*.ppsx|*.fodp)  echo slides ;;
        *.xls|*.xlsx|*.ods|*.csv|*.fods)         echo sheet ;;
        *.jpg|*.jpeg|*.png|*.webp|*.gif|*.bmp|*.tif|*.tiff|*.avif|*.heic) echo image ;;
        *.txt|*.md|*.log|*.conf|*.ini|*.json|*.yaml|*.yml) echo text ;;
        *.sh|*.py|*.c|*.h|*.cpp|*.rs|*.js|*.ts|*.qml)      echo code ;;
        *.html|*.htm|*.xml|*.epub)               echo web ;;
        *.ps|*.eps)                              echo ps ;;
        *)                                       return 1 ;;
    esac
}

human() {
    local b="$1" unit div
    if   (( b >= 1073741824 )); then unit=G; div=1073741824
    elif (( b >= 1048576 ));    then unit=M; div=1048576
    elif (( b >= 1024 ));       then printf '%dK' "$(( b / 1024 ))"; return
    else printf '%dB' "$b"; return
    fi
    printf '%d.%d%s' "$(( b / div ))" "$(( b * 10 / div % 10 ))" "$unit"
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
    emit "$(printf '{"name":"%s","path":"%s","type":"dir","kind":"dir","size":""}' \
        "$(json_escape "$(basename "$d")")" "$(json_escape "$d")")"
done < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | sort)

while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    k=$(kind_of "$f") || continue
    sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
    emit "$(printf '{"name":"%s","path":"%s","type":"file","kind":"%s","size":"%s"}' \
        "$(json_escape "$(basename "$f")")" \
        "$(json_escape "$f")" "$k" "$(human "$sz")")"
done < <(find "$DIR" -mindepth 1 -maxdepth 1 -type f ! -name '.*' -printf '%T@\t%p\n' 2>/dev/null \
         | sort -rn | cut -f2-)

printf ']}\n'
