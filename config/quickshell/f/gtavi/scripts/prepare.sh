#!/usr/bin/env bash
set -u

video="${1:-}"; seek="${2:-3}"; wall="${3:-}"; cache="${4:-$HOME/.cache/gtavi}"
mkdir -p "$cache"
exec 9>"$cache/.prepare.lock"
flock -n 9 || { echo "gtavi: prepare already running"; exit 0; }

seek=$(printf '%.3f' "$seek")
clip="$cache/intro-$seek.mkv"
status=0

if [[ -f "$video" ]]; then
    if [[ ! -s "$clip" || "$video" -nt "$clip" ]]; then
        tmp="$clip.part.mkv"
        if nice -n 19 ionice -c 3 ffmpeg -v error -nostdin -y \
                -ss "$seek" -i "$video" \
                -map 0:v:0 -map 0:a:0 \
                -vf "scale=1920:1080:force_original_aspect_ratio=increase:flags=lanczos,crop=1920:1080,format=yuv420p" \
                -c:v libx264 -preset slow -crf 16 -g 30 -keyint_min 30 -bf 0 -tune film \
                -c:a flac -compression_level 5 \
                -avoid_negative_ts make_zero "$tmp"; then
            mv -f "$tmp" "$clip"
            echo "gtavi: built $clip"
        else
            rm -f "$tmp"; echo "gtavi: intro clip build failed" >&2; status=1
        fi
    fi
else
    echo "gtavi: intro video missing: $video" >&2; status=1
fi

logo="$cache/logo.png"; meta="$cache/logo.txt"
if [[ -f "$wall" ]]; then
    if [[ ! -s "$logo" || ! -s "$meta" || "$wall" -nt "$logo" ]]; then
        size=$(magick identify -format '%w %h' "$wall[0]" 2>/dev/null)
        read -r W H <<< "$size"
        bg=$(magick "$wall[0]" -alpha off -depth 8 -crop 1x1+8+8 -format '%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]' info: 2>/dev/null)
        box=$(magick "$wall[0]" -alpha off -colorspace gray -threshold 22% -format '%@' info: 2>/dev/null)
        if [[ -n "${W:-}" && -n "$bg" && "$box" =~ ^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$ ]]; then
            bw=${BASH_REMATCH[1]}; bh=${BASH_REMATCH[2]}; bx=${BASH_REMATCH[3]}; by=${BASH_REMATCH[4]}
            m=$(( W / 96 ))
            x=$(( bx - m < 0 ? 0 : bx - m )); y=$(( by - m < 0 ? 0 : by - m ))
            w=$(( bw + 2*m )); h=$(( bh + 2*m ))
            (( x + w > W )) && w=$(( W - x )); (( y + h > H )) && h=$(( H - y ))
            if nice -n 19 magick "$wall[0]" -alpha off -depth 8 \
                    \( +clone -fill "srgb($bg)" -colorize 100 \) \
                    -compose difference -composite -colorspace gray -level 1%,7% \
                    "$cache/.mask.png" &&
               nice -n 19 magick "$wall[0]" -alpha off -depth 8 "$cache/.mask.png" \
                    -compose copy_opacity -composite \
                    -crop "${w}x${h}+${x}+${y}" +repage \
                    -resize '1600x1600>' "PNG32:$logo.part"; then
                mv -f "$logo.part" "$logo"
                awk -v x="$x" -v y="$y" -v w="$w" -v h="$h" -v W="$W" -v H="$H" -v bg="$bg" \
                    'BEGIN { printf "%.6f %.6f %.6f %.6f %d %d %s\n", x/W, y/H, w/W, h/H, W, H, bg }' \
                    > "$meta.part" && mv -f "$meta.part" "$meta"
                echo "gtavi: built $logo"
            else
                echo "gtavi: logo cut failed" >&2; status=1
            fi
            rm -f "$cache/.mask.png" "$logo.part"
        else
            echo "gtavi: could not analyse wallpaper" >&2; status=1
        fi
    fi
else
    echo "gtavi: wallpaper missing: $wall" >&2; status=1
fi

exit $status
