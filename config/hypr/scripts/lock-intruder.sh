#!/bin/sh
# Grab a single frame from the webcam after a failed unlock attempt.
#
# Written to ~/.local/share/lock-attempts/ with a timestamp. Silent by design:
# whoever is at the keyboard should not be told a photo was taken, and the
# lock screen itself already shows the attempt counter to the owner.

DIR="$HOME/.local/share/lock-attempts"
DEV=/dev/video0

[ -e "$DEV" ] || exit 0
command -v ffmpeg >/dev/null 2>&1 || exit 0

mkdir -p "$DIR"
chmod 700 "$DIR"

STAMP=$(date +%Y-%m-%d_%H-%M-%S)

# -y overwrite, one frame, short timeout so a busy camera cannot hang the lock.
timeout 6 ffmpeg -y -hide_banner -loglevel quiet \
    -f v4l2 -input_format mjpeg -video_size 1280x720 \
    -i "$DEV" -frames:v 1 "$DIR/$STAMP.jpg" 2>/dev/null \
  || timeout 6 ffmpeg -y -hide_banner -loglevel quiet \
    -f v4l2 -i "$DEV" -frames:v 1 "$DIR/$STAMP.jpg" 2>/dev/null

chmod 600 "$DIR/$STAMP.jpg" 2>/dev/null

# Keep the last 50; this should not quietly fill the disk.
ls -1t "$DIR"/*.jpg 2>/dev/null | tail -n +51 | while read -r old; do
    rm -f "$old"
done
