#!/usr/bin/env bash
# Печатает установленные исходящие соединения текущего пользователя
# в виде «процесс<TAB>адрес<TAB>порт». Локальные адреса пропускаются,
# а процессы из outbound-ignore.list не показываются вовсе: браузер
# и мессенджеры держат сеть постоянно и забивают собой весь список.
set -u

IGNORE="$HOME/.config/hypr/outbound-ignore.list"
[[ -r "$IGNORE" ]] || IGNORE=/dev/null

ss -tunp state established 2>/dev/null | awk -v ignorefile="$IGNORE" '
    BEGIN {
        while ((getline line < ignorefile) > 0) {
            sub(/#.*/, "", line)
            gsub(/^[ \t]+|[ \t]+$/, "", line)
            if (line != "") skip[line] = 1
        }
    }
    NR == 1 { next }
    {
        proc = "?"
        if (match($0, /users:\(\("[^"]+"/)) {
            proc = substr($0, RSTART + 9, RLENGTH - 10)
        }
        if (proc == "?" || proc in skip) next

        peer = ""
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^users:/) { peer = $(i-1); break }
        }
        if (peer == "") next

        n = split(peer, a, ":")
        port = a[n]
        host = substr(peer, 1, length(peer) - length(port) - 1)
        gsub(/^\[|\]$/, "", host)

        if (host ~ /^127\./ || host == "::1" || host == "") next
        if (host ~ /^192\.168\./ || host ~ /^10\./) next
        if (host ~ /^172\.(1[6-9]|2[0-9]|3[01])\./) next

        print proc "\t" host "\t" port
    }
' | sort -u
