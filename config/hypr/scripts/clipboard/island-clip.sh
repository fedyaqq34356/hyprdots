#!/bin/sh
types=$(wl-paste --list-types 2>/dev/null)
[ -n "$types" ] || exit 0

if printf '%s\n' "$types" | grep -qi 'x-kde-passwordManagerHint'; then
    printf 'secret\tpm\n'
    exit 0
fi

dir="${XDG_RUNTIME_DIR:-/tmp}/qs-clip"
mkdir -p "$dir" && chmod 700 "$dir"

img=$(printf '%s\n' "$types" | grep -m1 '^image/')
if [ -n "$img" ]; then
    ext=${img#image/}
    tmp="$dir/.incoming"
    wl-paste --type "$img" > "$tmp" 2>/dev/null
    [ -s "$tmp" ] || exit 0
    sig=$(sha1sum < "$tmp" | cut -c1-12)
    out="$dir/$sig.$ext"
    if [ ! -e "$out" ]; then
        find "$dir" -maxdepth 1 -type f ! -name .incoming -delete
        mv "$tmp" "$out"
    else
        rm -f "$tmp"
    fi
    printf 'img\t%s\t%s\n' "$sig" "$out"
    exit 0
fi

if printf '%s\n' "$types" | grep -q '^text/uri-list'; then
    list=$(wl-paste --type text/uri-list 2>/dev/null | tr -d '\r' | grep -v '^#')
    n=$(printf '%s\n' "$list" | grep -c .)
    first=$(printf '%s\n' "$list" | head -n1)
    first=$(basename "$(printf '%s' "$first" | sed 's|^file://||')")
    sig=$(printf '%s' "$list" | sha1sum | cut -c1-12)
    printf 'files\t%s\t%s\t%s\n' "$sig" "$n" "$first"
    exit 0
fi

data=$(wl-paste --no-newline --type text 2>/dev/null | head -c 8000)
[ -n "$data" ] || exit 0
sig=$(printf '%s' "$data" | sha1sum | cut -c1-12)

if printf '%s' "$data" | grep -qiE \
    'sk-ant-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{30,}|github_pat_|xox[baprs]-|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|[0-9]{8,10}:AA[A-Za-z0-9_-]{33}'; then
    printf 'secret\t%s\n' "$sig"
    exit 0
fi

printf 'txt\t%s\t%s\n' "$sig" "$(printf '%s' "$data" | head -c 600 | tr '\n\t\r' '   ' | tr -s ' ')"
