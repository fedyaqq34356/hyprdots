#!/usr/bin/env bash
set -u

CACHE="$HOME/.cache/qs-print"
mkdir -p "$CACHE"

MAX_THUMBS=30
THUMB_WIDTH=420

SRC="${1:-}"

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/}"
    printf '%s' "$s"
}

fail() {
    printf '{"ok":false,"code":"%s","error":"%s"}\n' "$1" "$(json_escape "$2")"
    exit 0
}

[[ -n "$SRC" ]] || fail nofile "файл не выбран"
[[ -f "$SRC" ]] || fail nofile "файла нет: $SRC"
[[ -r "$SRC" ]] || fail noread "файл недоступен для чтения"

NAME=$(basename "$SRC")
EXT="${NAME##*.}"
EXT="${EXT,,}"
[[ "$EXT" == "$NAME" ]] && EXT=""

SIZE=$(stat -c %s "$SRC" 2>/dev/null || echo 0)
MTIME=$(stat -c %Y "$SRC" 2>/dev/null || echo 0)
KEY=$(printf '%s|%s|%s' "$SRC" "$MTIME" "$SIZE" | sha1sum | cut -d' ' -f1)
WORK="$CACHE/$KEY"
PDF="$WORK/doc.pdf"

kind_of() {
    case "$EXT" in
        pdf)                                  echo pdf ;;
        doc|docx|odt|rtf|fodt|dot|dotx|abw)   echo office ;;
        ppt|pptx|odp|fodp|pps|ppsx)           echo office ;;
        xls|xlsx|ods|fods|csv)                echo office ;;
        epub|xml)                             echo office ;;
        html|htm)                             echo web ;;
        jpg|jpeg|png|webp|gif|bmp|tif|tiff|avif|heic) echo image ;;
        txt|md|log|conf|ini)                  echo text ;;
        json|yaml|yml|sh|py|c|h|cpp|rs|js|ts|qml) echo code ;;
        ps|eps)                               echo ps ;;
        "")
            local mime
            mime=$(file -b --mime-type "$SRC" 2>/dev/null)
            case "$mime" in
                application/pdf) echo pdf ;;
                image/*)         echo image ;;
                text/*)          echo text ;;
                *)               echo unknown ;;
            esac
            ;;
        *)                                    echo unknown ;;
    esac
}

KIND=$(kind_of)
[[ "$KIND" == unknown ]] && fail unsupported "формат .$EXT не поддерживается"

mkdir -p "$WORK"

PAGE_W=4961    # 210 мм
PAGE_H=7016    # 297 мм
PRINT_W=4488   # 190 мм
PRINT_H=6543   # 277 мм

html_for_text() {
    local file="$1" mode="$2" out="$3"
    python3 - "$file" "$mode" "$out" <<'PY'
import html, sys

src, mode, out = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src, encoding="utf-8", errors="replace") as f:
    body = f.read()

if mode == "code":
    content = "<pre>%s</pre>" % html.escape(body)
    style = """
body { font-family: "JetBrainsMono Nerd Font", monospace; font-size: 8.5pt;
       line-height: 1.35; }
pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; }
"""
else:
    KEEP = ("-", "*", "•", "—", ">", "|", "#")

    def literal(block):
        for line in block:
            s = line.lstrip()
            if line[:1] in (" ", "\t"):
                return True
            if s[:1] in KEEP:
                return True
            if s[:2].rstrip(".").isdigit() and s[1:3] in (". ", ") "):
                return True
        return False

    parts = []
    first = True
    for raw in body.replace("\r\n", "\n").split("\n\n"):
        block = [l for l in raw.split("\n") if l.strip()]
        if not block:
            continue

        if first and len(block) == 1 and len(block[0].strip()) <= 60 \
                and not block[0].strip().endswith((".", "!", "?", ":", ",")):
            parts.append("<h1>%s</h1>" % html.escape(block[0].strip()))
            first = False
            continue
        first = False

        if literal(block):
            parts.append("<pre>%s</pre>" % html.escape("\n".join(block)))
        else:
            parts.append("<p>%s</p>" % html.escape(" ".join(l.strip() for l in block)))

    content = "\n".join(parts)
    style = """
body { font-family: "DejaVu Serif", serif; font-size: 11pt; line-height: 1.5; }
h1 { font-size: 13pt; font-weight: 600; letter-spacing: 0.04em;
     margin: 0 0 1.4em 0; }
p { margin: 0 0 0.62em 0; text-align: justify;
    hyphens: auto; -webkit-hyphens: auto; }
pre { margin: 0 0 0.62em 0; white-space: pre-wrap; word-wrap: break-word;
      font-family: inherit; font-size: inherit; line-height: inherit; }
"""

page = """<!doctype html><html lang="ru"><meta charset="utf-8"><style>
@page { size: A4; margin: 18mm 20mm; }
html { -webkit-print-color-adjust: exact; }
body { margin: 0; color: #000; orphans: 2; widows: 2; }
%s</style>
%s</html>""" % (style, content)

with open(out, "w", encoding="utf-8") as f:
    f.write(page)
PY
}

render_html() {
    local url="$1" out="$2"
    timeout 90 /usr/bin/chromium \
        --headless --disable-gpu --no-sandbox --no-pdf-header-footer \
        --user-data-dir="$CACHE/.chrome-profile" \
        --print-to-pdf="$out" "$url" >/dev/null 2>&1
    [[ -s "$out" ]]
}

build_pdf() {
    case "$KIND" in
    pdf)
        ln -sf "$SRC" "$PDF"
        ;;
    ps)
        ps2pdf "$SRC" "$PDF" >/dev/null 2>&1 || return 1
        ;;
    image)
        magick "$SRC" -auto-orient \
            -colorspace Gray -depth 8 \
            -resize "${PRINT_W}x${PRINT_H}>" \
            -unsharp 0x0.7+0.7+0.01 \
            -density 600 -units PixelsPerInch \
            -gravity center -background white -extent "${PAGE_W}x${PAGE_H}" \
            -compress Zip "$PDF" >/dev/null 2>&1 || return 1
        ;;
    text|code)
        local page="$WORK/page.html"
        html_for_text "$SRC" "$KIND" "$page" || return 1
        render_html "file://$page" "$PDF" || return 1
        ;;
    web)
        render_html "file://$SRC" "$PDF" || return 1
        ;;
    office)
        local profile="$CACHE/.soffice-profile"
        local filter='pdf:writer_pdf_Export:{"UseLosslessCompression":{"type":"boolean","value":"true"},"ReduceImageResolution":{"type":"boolean","value":"false"},"MaxImageResolution":{"type":"long","value":"600"},"EmbedStandardFonts":{"type":"boolean","value":"true"}}'

        soffice --headless --norestore \
            -env:UserInstallation="file://$profile" \
            --convert-to "$filter" --outdir "$WORK" "$SRC" >/dev/null 2>&1

        local out
        out=$(find "$WORK" -maxdepth 1 -name '*.pdf' ! -name 'doc.pdf' -print -quit)

        if [[ -z "$out" ]]; then
            soffice --headless --norestore \
                -env:UserInstallation="file://$profile" \
                --convert-to pdf --outdir "$WORK" "$SRC" >/dev/null 2>&1 || return 1
            out=$(find "$WORK" -maxdepth 1 -name '*.pdf' ! -name 'doc.pdf' -print -quit)
        fi

        [[ -n "$out" ]] || return 1
        mv -f "$out" "$PDF"
        ;;
    esac
    [[ -s "$PDF" || -L "$PDF" ]]
}

if [[ ! -e "$PDF" ]]; then
    build_pdf || fail convert "не удалось преобразовать в PDF"
fi

PAGES=$(pdfinfo "$PDF" 2>/dev/null | awk '/^Pages:/ { print $2; exit }')
[[ "$PAGES" =~ ^[0-9]+$ ]] || PAGES=1

PAPER=$(pdfinfo "$PDF" 2>/dev/null | awk -F': *' '/^Page size:/ { print $2; exit }')

GEOM=$(pdfinfo "$PDF" 2>/dev/null | awk '/^Page size:/ { print $3, $5; exit }')
WPT=${GEOM%% *}
HPT=${GEOM##* }
[[ "$WPT" =~ ^[0-9.]+$ ]] || WPT=0
[[ "$HPT" =~ ^[0-9.]+$ ]] || HPT=0

THUMB_DIR="$WORK/thumbs"
if [[ ! -d "$THUMB_DIR" ]]; then
    mkdir -p "$THUMB_DIR"
    pdftoppm -png -r 0 -scale-to-x "$THUMB_WIDTH" -scale-to-y -1 \
        -f 1 -l "$(( PAGES < MAX_THUMBS ? PAGES : MAX_THUMBS ))" \
        "$PDF" "$THUMB_DIR/p" >/dev/null 2>&1
fi

printf '{"ok":true,"name":"%s","src":"%s","pdf":"%s","kind":"%s","pages":%s,"paper":"%s","wpt":%s,"hpt":%s,"thumbs":[' \
    "$(json_escape "$NAME")" \
    "$(json_escape "$SRC")" \
    "$(json_escape "$PDF")" \
    "$KIND" \
    "$PAGES" \
    "$(json_escape "${PAPER:-}")" \
    "$WPT" "$HPT"

first=1
while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    (( first )) || printf ','
    first=0
    printf '"%s"' "$(json_escape "$t")"
done < <(find "$THUMB_DIR" -maxdepth 1 -name 'p*.png' 2>/dev/null | sort -V)

printf ']}\n'
