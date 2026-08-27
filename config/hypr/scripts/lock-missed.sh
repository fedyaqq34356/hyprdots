#!/usr/bin/env bash
RUN="${XDG_RUNTIME_DIR:-/tmp}"
n=$(cat "$RUN/missed-notifications" 2>/dev/null)
[[ "$n" =~ ^[0-9]+$ ]] || n=0
((n == 0)) && exit 0

case $((n % 10)) in
    1) word="уведомление" ;;
    2|3|4) word="уведомления" ;;
    *) word="уведомлений" ;;
esac
case $n in
    11|12|13|14) word="уведомлений" ;;
esac

printf '󰂚  %d %s\n' "$n" "$word"
