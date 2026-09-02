#!/bin/sh

case "${1:-normal}" in
    critical)
        notify-send -u critical -a "test" \
            "Critical" "A static frame, stays until clicked"
        ;;
    burst)
        notify-send -a "test" "First" "Stack check"
        sleep 0.6
        notify-send -a "test" "Second" "The others follow"
        sleep 0.6
        notify-send -a "test" "Third" "Sound is rate limited"
        sleep 0.6
        notify-send -u critical -a "test" "Fourth" "And one critical"
        ;;
    *)
        notify-send -a "test" \
            "Test notification" "The outline counts down; hover to pause it"
        ;;
esac
