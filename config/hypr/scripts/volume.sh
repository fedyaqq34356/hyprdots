#!/bin/bash

case "$1" in
  up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute) wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle ;;
esac

MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED)
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2 * 100}')

if [ "$MUTED" -eq 1 ]; then
    ICON="audio-volume-muted"
    MSG="Muted"
else
    if   [ "$VOL" -eq 0 ];   then ICON="audio-volume-muted"
    elif [ "$VOL" -le 33 ];  then ICON="audio-volume-low"
    elif [ "$VOL" -le 66 ];  then ICON="audio-volume-medium"
    else                          ICON="audio-volume-high"
    fi
    MSG="Громкость: ${VOL}%"
fi

dunstify -a "volume" -u low -r 9991 -h int:value:"$VOL" -i "$ICON" "$MSG"
