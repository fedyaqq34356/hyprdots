#!/bin/sh
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/pc-eco"
ECO_MAX_KHZ=2000000
GPU=/sys/class/drm/card1/device

root_apply() {
    if [ -t 0 ] && [ -z "$SUDO_ASKPASS" ]; then
        sudo_cmd="sudo"
    else
        export SUDO_ASKPASS="${SUDO_ASKPASS:-$(command -v ksshaskpass || command -v ssh-askpass || echo /usr/lib/ssh/ssh-askpass)}"
        sudo_cmd="sudo -A"
    fi
    $sudo_cmd sh -c '
        mode=$1 khz=$2 gpu=$3
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
            if [ "$mode" = on ]; then
                echo "$khz" > "$p/scaling_max_freq"
                echo power > "$p/energy_performance_preference"
            else
                cat "$p/cpuinfo_max_freq" > "$p/scaling_max_freq"
                echo balance_performance > "$p/energy_performance_preference"
            fi
        done
        if [ "$mode" = on ]; then
            echo 0 > /sys/devices/system/cpu/cpufreq/boost
            echo low > "$gpu/power_dpm_force_performance_level"
        else
            echo 1 > /sys/devices/system/cpu/cpufreq/boost
            echo auto > "$gpu/power_dpm_force_performance_level"
        fi
    ' sh "$1" "$ECO_MAX_KHZ" "$GPU"
}

on() {
    root_apply on || exit 1
    monitor-eco on
    mkdir -p "${STATE%/*}" && touch "$STATE"
}

off() {
    root_apply off || exit 1
    monitor-eco off
    rm -f "$STATE"
}

status() {
    p=/sys/devices/system/cpu/cpufreq/policy0
    [ "$(cat /sys/devices/system/cpu/cpufreq/boost)" = 0 ] || rm -f "$STATE"
    [ -e "$STATE" ] && echo on || echo off
    echo "cpu max $(($(cat $p/scaling_max_freq) / 1000)) MHz, boost $(cat /sys/devices/system/cpu/cpufreq/boost), epp $(cat $p/energy_performance_preference)"
    echo "gpu $(cat $GPU/power_dpm_force_performance_level), monitor $(monitor-eco status)"
}

case "$1" in
    on) on ;;
    off) off ;;
    toggle) if [ -e "$STATE" ]; then off; else on; fi ;;
    status) status ;;
    *) echo "usage: $0 on|off|toggle|status" >&2; exit 1 ;;
esac
